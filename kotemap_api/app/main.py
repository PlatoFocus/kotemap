"""
Point d'entrée de l'API KOTE MAP.

Lifespan FastAPI :
  - Au démarrage : init_db() crée les tables, seed_stations() insère les 25 stations
  - À l'arrêt    : fermeture du pool de connexions

CORS : configuré pour accepter le frontend Flutter Web (Firebase Hosting + localhost dev)
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine, init_db, seed_stations
from app.routers import auth, contributions, incidents, stations
from app.routers import itineraries

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s — %(name)s — %(levelname)s — %(message)s",
)
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Lifespan : remplace les @app.on_event("startup"/"shutdown") (déprécié)
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Cycle de vie de l'application.
    Tout ce qui précède le `yield` s'exécute au démarrage.
    Tout ce qui suit le `yield` s'exécute à l'arrêt.
    """
    logger.info("=== KOTE MAP API — Démarrage ===")

    # 1. Créer les tables (IF NOT EXISTS — idempotent)
    try:
        await init_db()
        logger.info("Base de données initialisée.")
    except Exception as e:
        logger.error(f"Échec initialisation DB : {e}")
        raise

    # 2. Insérer les stations seed si la table est vide
    try:
        await seed_stations()
    except Exception as e:
        # Le seed n'est pas critique — on continue même en cas d'erreur
        logger.warning(f"Seed non complété (non bloquant) : {e}")

    logger.info("=== API prête à recevoir des requêtes ===")

    yield  # L'application tourne ici

    # Fermeture propre du pool de connexions
    logger.info("=== KOTE MAP API — Arrêt propre ===")
    await engine.dispose()


# ---------------------------------------------------------------------------
# Application FastAPI
# ---------------------------------------------------------------------------

app = FastAPI(
    title="KOTE MAP API",
    description=(
        "API REST pour la navigation de transport en commun informel (taptap/bus) "
        "à Port-au-Prince, Haïti. Propulsé par Claude AI."
    ),
    version="0.1.0",
    docs_url="/docs",       # Swagger UI
    redoc_url="/redoc",     # ReDoc
    lifespan=lifespan,
)


# ---------------------------------------------------------------------------
# CORS — accepte les requêtes Flutter Web (dev + production Firebase Hosting)
# ---------------------------------------------------------------------------

# En production, remplacer "*" par l'URL exacte du frontend Firebase
ALLOWED_ORIGINS = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:5000",
    "http://localhost:8080",
    # URL Firebase Hosting — à remplacer avec votre domaine réel
    "https://kotemap-app.web.app",
    "https://kotemap-app.firebaseapp.com",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Inclusion des routers
# ---------------------------------------------------------------------------

app.include_router(auth.router, prefix="/auth", tags=["Authentification"])
app.include_router(stations.router, prefix="/stations", tags=["Stations"])
app.include_router(itineraries.router, prefix="/itineraries", tags=["Itinéraires IA"])
app.include_router(incidents.router, prefix="/incidents", tags=["Incidents Sécurité"])
app.include_router(contributions.router, prefix="/contributions", tags=["Contributions"])


# ---------------------------------------------------------------------------
# Endpoints de base
# ---------------------------------------------------------------------------

@app.get("/", tags=["Santé"])
async def root():
    """Endpoint racine — vérification que l'API tourne."""
    return {
        "message": "KOTE MAP API v0.1.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health", tags=["Santé"])
async def health():
    """Health check pour Render.com (utilisé par le load balancer)."""
    return {"status": "ok"}
