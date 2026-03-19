"""
Router : /contributions
Formulaire de contribution de stations par la communauté.

Flow de modération :
  1. Un utilisateur soumet une contribution (statut: pending)
  2. Un admin/contributeur vérifié approuve ou rejette
  3. Si approuvé → la contribution est automatiquement convertie en Station

Endpoints :
  GET  /contributions/           → liste des contributions (admin/contributeur)
  GET  /contributions/{id}       → détail d'une contribution
  POST /contributions/           → soumettre une contribution (utilisateurs connectés)
  PUT  /contributions/{id}/approve → approuver et créer la station (admin)
  PUT  /contributions/{id}/reject  → rejeter (admin)
"""

import json
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status
from geoalchemy2.elements import WKTElement
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Contribution, ContributionStatus, Station, StationStatus, User
from app.routers.auth import get_current_user_required, require_role
from app.schemas import ContributionCreate, ContributionListResponse, ContributionResponse

logger = logging.getLogger(__name__)

router = APIRouter()


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

def _contribution_to_response(contrib: Contribution) -> ContributionResponse:
    return ContributionResponse(
        id=contrib.id,
        station_name=contrib.station_name,
        transport_type=contrib.transport_type,
        latitude=contrib.latitude,
        longitude=contrib.longitude,
        description=contrib.description,
        routes_json=contrib.routes_json,
        status=contrib.status,
        created_at=contrib.created_at,
    )


# ---------------------------------------------------------------------------
# GET /contributions/ — liste (admin/contributeur uniquement)
# ---------------------------------------------------------------------------

@router.get("/", response_model=ContributionListResponse)
async def list_contributions(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    status_filter: ContributionStatus = Query(default=ContributionStatus.pending, alias="status"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role(["admin", "contributor"])),
):
    """Liste les contributions filtrées par statut. Admin/contributeur requis."""
    query = (
        select(Contribution)
        .where(Contribution.status == status_filter)
        .order_by(Contribution.created_at.desc())
        .offset(skip)
        .limit(limit)
    )

    try:
        result = await db.execute(query)
        contributions = result.scalars().all()
    except Exception as e:
        logger.error(f"Erreur liste contributions : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    return ContributionListResponse(
        total=len(contributions),
        contributions=[_contribution_to_response(c) for c in contributions],
    )


# ---------------------------------------------------------------------------
# GET /contributions/{id} — détail
# ---------------------------------------------------------------------------

@router.get("/{contribution_id}", response_model=ContributionResponse)
async def get_contribution(
    contribution_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_required),
):
    """Retourne le détail d'une contribution. Authentification requise."""
    try:
        result = await db.execute(
            select(Contribution).where(Contribution.id == contribution_id)
        )
        contrib = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur get contribution {contribution_id} : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    if not contrib:
        raise HTTPException(status_code=404, detail=f"Contribution {contribution_id} introuvable")

    return _contribution_to_response(contrib)


# ---------------------------------------------------------------------------
# POST /contributions/ — soumettre une nouvelle contribution
# ---------------------------------------------------------------------------

@router.post("/", response_model=ContributionResponse, status_code=status.HTTP_201_CREATED)
async def create_contribution(
    data: ContributionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user_required),
):
    """
    Soumet une proposition de nouvelle station.
    L'authentification est requise pour tracer les contributions.
    La contribution est en statut 'pending' jusqu'à validation.
    """
    new_contrib = Contribution(
        station_name=data.station_name,
        transport_type=data.transport_type,
        latitude=data.latitude,
        longitude=data.longitude,
        description=data.description,
        routes_json=data.routes_json,
        status=ContributionStatus.pending,
        user_id=current_user.id,
    )

    try:
        db.add(new_contrib)
        await db.commit()
        await db.refresh(new_contrib)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur création contribution : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la soumission")

    return _contribution_to_response(new_contrib)


# ---------------------------------------------------------------------------
# PUT /contributions/{id}/approve — approuver et créer la station
# ---------------------------------------------------------------------------

@router.put("/{contribution_id}/approve", response_model=ContributionResponse)
async def approve_contribution(
    contribution_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role(["admin"])),
):
    """
    Approuve une contribution et crée automatiquement la station correspondante.
    Admin uniquement.
    """
    try:
        result = await db.execute(
            select(Contribution).where(Contribution.id == contribution_id)
        )
        contrib = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur get contribution {contribution_id} : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    if not contrib:
        raise HTTPException(status_code=404, detail=f"Contribution {contribution_id} introuvable")

    if contrib.status != ContributionStatus.pending:
        raise HTTPException(
            status_code=409,
            detail=f"Cette contribution est déjà en statut '{contrib.status.value}'",
        )

    # Création de la station depuis la contribution
    new_station = Station(
        name=contrib.station_name,
        transport_type=contrib.transport_type,
        latitude=contrib.latitude,
        longitude=contrib.longitude,
        location=WKTElement(f"POINT({contrib.longitude} {contrib.latitude})", srid=4326),
        description=contrib.description,
        routes_json=contrib.routes_json,
        status=StationStatus.active,
        is_verified=True,
    )

    from datetime import datetime

    contrib.status = ContributionStatus.approved
    contrib.reviewed_at = datetime.utcnow()

    try:
        db.add(new_station)
        await db.flush()  # Pour obtenir l'ID de la station avant commit
        contrib.station_id = new_station.id
        await db.commit()
        await db.refresh(contrib)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur approbation contribution : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de l'approbation")

    logger.info(f"Contribution {contribution_id} approuvée → Station {new_station.id} créée.")
    return _contribution_to_response(contrib)


# ---------------------------------------------------------------------------
# PUT /contributions/{id}/reject — rejeter
# ---------------------------------------------------------------------------

@router.put("/{contribution_id}/reject", response_model=ContributionResponse)
async def reject_contribution(
    contribution_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role(["admin"])),
):
    """Rejette une contribution. Admin uniquement."""
    from datetime import datetime

    try:
        result = await db.execute(
            select(Contribution).where(Contribution.id == contribution_id)
        )
        contrib = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur get contribution {contribution_id} pour reject : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    if not contrib:
        raise HTTPException(status_code=404, detail=f"Contribution {contribution_id} introuvable")

    if contrib.status != ContributionStatus.pending:
        raise HTTPException(
            status_code=409,
            detail=f"Cette contribution est déjà en statut '{contrib.status.value}'",
        )

    contrib.status = ContributionStatus.rejected
    contrib.reviewed_at = datetime.utcnow()

    try:
        await db.commit()
        await db.refresh(contrib)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur rejet contribution : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors du rejet")

    return _contribution_to_response(contrib)
