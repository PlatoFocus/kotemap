"""
Router : /auth
Authentification JWT minimale (register + login).

Sécurité :
  - Mots de passe hashés avec bcrypt (passlib)
  - JWT signé avec HS256 (python-jose)
  - Expiration configurable via settings
  - Fonction get_current_user() réutilisable comme dependency FastAPI
  - Fonction require_role() pour protéger des endpoints par rôle
"""

import logging
from datetime import datetime, timedelta
from functools import lru_cache
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import User, UserRole
from app.schemas import TokenResponse, UserRegister, UserResponse

logger = logging.getLogger(__name__)

router = APIRouter()

# ---------------------------------------------------------------------------
# Configuration sécurité
# ---------------------------------------------------------------------------

# bcrypt pour le hashing des mots de passe
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 : le token est attendu dans l'en-tête Authorization: Bearer <token>
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)


def _hash_password(password: str) -> str:
    return pwd_context.hash(password)


def _verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def _create_jwt(user_id: int, email: str, role: str) -> str:
    """Génère un token JWT signé avec expiration."""
    expire = datetime.utcnow() + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "exp": expire,
    }
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


# ---------------------------------------------------------------------------
# Dependency : récupère l'utilisateur depuis le JWT (si présent)
# ---------------------------------------------------------------------------

async def get_current_user(
    token: Optional[str] = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> Optional[User]:
    """
    Dependency optionnelle — retourne l'utilisateur connecté ou None.
    N'échoue pas si aucun token fourni (pour les endpoints publics).
    """
    if not token:
        return None

    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id = int(payload.get("sub", 0))
    except (JWTError, ValueError):
        return None

    try:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur récupération user depuis JWT : {e}")
        return None

    return user if (user and user.is_active) else None


async def get_current_user_required(
    token: Optional[str] = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Dependency obligatoire — lève 401 si non authentifié.
    Utiliser pour les endpoints qui nécessitent une connexion.
    """
    user = await get_current_user(token, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentification requise",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


def require_role(roles: list[str]):
    """
    Factory de dependency — vérifie que l'utilisateur a l'un des rôles requis.
    Usage : Depends(require_role(["admin", "contributor"]))
    """
    async def _check_role(
        current_user: User = Depends(get_current_user_required),
    ) -> User:
        if current_user.role.value not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Rôle requis : {', '.join(roles)}. Votre rôle : {current_user.role.value}",
            )
        return current_user

    return _check_role


# ---------------------------------------------------------------------------
# POST /auth/register
# ---------------------------------------------------------------------------

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    data: UserRegister,
    db: AsyncSession = Depends(get_db),
):
    """
    Crée un nouveau compte utilisateur.
    L'email et le username doivent être uniques.
    """
    # Vérification unicité email
    try:
        result = await db.execute(select(User).where(User.email == data.email))
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Un compte avec cet email existe déjà",
            )

        # Vérification unicité username
        result = await db.execute(select(User).where(User.username == data.username))
        if result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Ce nom d'utilisateur est déjà pris",
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur vérification unicité register : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    new_user = User(
        email=data.email,
        username=data.username,
        hashed_password=_hash_password(data.password),
        role=UserRole.user,
    )

    try:
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur création user : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la création du compte")

    return UserResponse.model_validate(new_user)


# ---------------------------------------------------------------------------
# POST /auth/login
# ---------------------------------------------------------------------------

@router.post("/login", response_model=TokenResponse)
async def login(
    data: dict,
    db: AsyncSession = Depends(get_db),
):
    """
    Connexion : retourne un token JWT si les credentials sont valides.
    Accepte {email, password} en JSON.
    """
    email = data.get("email", "")
    password = data.get("password", "")

    if not email or not password:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Email et mot de passe requis",
        )

    try:
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur DB login : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    # Message générique pour éviter l'énumération d'emails
    if not user or not _verify_password(password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Ce compte est désactivé",
        )

    token = _create_jwt(user.id, user.email, user.role.value)

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


# ---------------------------------------------------------------------------
# GET /auth/me
# ---------------------------------------------------------------------------

@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user_required),
):
    """Retourne le profil de l'utilisateur actuellement connecté."""
    return UserResponse.model_validate(current_user)
