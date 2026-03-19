"""
Configuration centralisée via pydantic-settings.
Les valeurs sont lues depuis les variables d'environnement ou le fichier .env.

Note Supabase : utiliser le Connection Pooler (port 6543) pour IPv4.
Le préfixe postgresql:// est automatiquement converti en postgresql+asyncpg://.
"""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # -------------------------------------------------------------------------
    # Base de données PostgreSQL (Supabase)
    # Accepte les deux formats :
    #   - postgresql+asyncpg://...  (format SQLAlchemy asyncpg, recommandé)
    #   - postgresql://...          (converti automatiquement ci-dessous)
    # Pour Supabase tier gratuit : utiliser le pooler (port 6543)
    # -------------------------------------------------------------------------
    database_url: str = "postgresql+asyncpg://savilner@localhost:5432/kotemap"

    # Redis (optionnel pour le prototype)
    redis_url: str = ""

    # JWT
    secret_key: str = "change-me-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 jours

    # Anthropic / Claude API
    anthropic_api_key: str = ""

    # Firebase Admin SDK
    firebase_credentials_path: str = ""

    @property
    def async_database_url(self) -> str:
        """
        Retourne l'URL de connexion compatible asyncpg.
        Supabase fournit postgresql://, SQLAlchemy async a besoin de postgresql+asyncpg://.
        """
        url = self.database_url
        if url.startswith("postgresql://"):
            url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
        elif url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql+asyncpg://", 1)
        return url

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
