"""
Connexion PostgreSQL/PostGIS et gestion du cycle de vie de la base de données.

Deux fonctions clés appelées au démarrage de l'API :
  - init_db()       : crée toutes les tables (CREATE TABLE IF NOT EXISTS)
  - seed_stations() : insère les 25 stations réelles de Port-au-Prince si la table est vide
"""

import json
import logging
from typing import AsyncGenerator

from geoalchemy2.elements import WKTElement
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker
from app.config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Moteur SQLAlchemy asynchrone (asyncpg driver)
#
# NullPool : chaque requête obtient une connexion fraîche depuis pgBouncer
# et la libère immédiatement après. Obligatoire avec Supabase Transaction
# Pooler (pgBouncer mode transaction) qui est incompatible avec les
# prepared statements nommés qu'asyncpg utilise par défaut.
# ---------------------------------------------------------------------------

engine = create_async_engine(
    settings.async_database_url,
    echo=False,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
)

AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Évite les lazy-load après commit en async
)


class Base(DeclarativeBase):
    pass


# ---------------------------------------------------------------------------
# Dependency injection FastAPI
# ---------------------------------------------------------------------------

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Fournit une session DB pour chaque requête HTTP, fermée automatiquement."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


# ---------------------------------------------------------------------------
# Initialisation de la base de données
# ---------------------------------------------------------------------------

async def init_db() -> None:
    """
    Crée l'extension PostGIS et toutes les tables SQLAlchemy.
    Appelé une seule fois au démarrage de l'application (lifespan FastAPI).
    """
    # Import des modèles ici pour éviter les imports circulaires
    from app.models import Station, User, Incident, Contribution  # noqa: F401

    async with engine.begin() as conn:
        # PostGIS doit être activé avant de créer les colonnes Geometry
        try:
            await conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))
            logger.info("Extension PostGIS activée.")
        except Exception as e:
            logger.warning(f"PostGIS déjà actif ou erreur ignorée : {e}")

        # Crée toutes les tables déclarées dans Base (IF NOT EXISTS implicite)
        await conn.run_sync(Base.metadata.create_all)
        logger.info("Tables créées ou déjà existantes.")


# ---------------------------------------------------------------------------
# Seed data — 25 stations réelles de Port-au-Prince
# ---------------------------------------------------------------------------

# Format : (nom, transport_type, latitude, longitude, description, routes)
STATIONS_SEED = [
    (
        "Station Pétion-Ville (Marché)",
        "taptap",
        18.5131, -72.2863,
        "Terminus principal de Pétion-Ville, face au marché couvert.",
        ["Pétion-Ville", "Centre-Ville", "Jalousie"],
    ),
    (
        "Station Delmas 32",
        "bus",
        18.5474, -72.3121,
        "Carrefour Delmas 32, nœud de correspondance majeur.",
        ["Delmas", "Centre-Ville", "Aéroport"],
    ),
    (
        "Station Centre-Ville Champ de Mars",
        "taptap",
        18.5425, -72.3386,
        "Place emblématique du centre historique de Port-au-Prince.",
        ["Centre-Ville", "Bel-Air", "Pétion-Ville"],
    ),
    (
        "Station Carrefour Route Nationale 2",
        "bus",
        18.5348, -72.3875,
        "Entrée sud de Carrefour sur la RN2, départ pour Léogâne.",
        ["Carrefour", "Léogâne", "Gressier"],
    ),
    (
        "Station Tabarre",
        "taptap",
        18.5799, -72.2991,
        "Zone industrielle et résidentielle au nord-est.",
        ["Tabarre", "Delmas", "Centre-Ville"],
    ),
    (
        "Station Croix-des-Bouquets",
        "bus",
        18.5780, -72.2290,
        "Terminus de la ville satellite de Croix-des-Bouquets.",
        ["Croix-des-Bouquets", "Centre-Ville", "Tabarre"],
    ),
    (
        "Station Léogâne",
        "bus",
        18.5101, -72.6300,
        "Terminus de Léogâne, départ pour Gressier et Grand-Goâve.",
        ["Léogâne", "Carrefour", "Gressier"],
    ),
    (
        "Station Martissant",
        "taptap",
        18.5190, -72.3560,
        "Quartier populaire au sud-ouest, zone sensible.",
        ["Martissant", "Carrefour", "Centre-Ville"],
    ),
    (
        "Station Jalousie Pétion-Ville",
        "taptap",
        18.5055, -72.2940,
        "Départ pour le quartier de Jalousie sur les hauteurs.",
        ["Jalousie", "Pétion-Ville"],
    ),
    (
        "Station Delmas 75",
        "taptap",
        18.5612, -72.3050,
        "Nœud de correspondance haut de Delmas.",
        ["Delmas 75", "Delmas 32", "Tabarre"],
    ),
    (
        "Station Nazon",
        "taptap",
        18.5570, -72.3200,
        "Carrefour Nazon, connexion entre Delmas et Centre-Ville.",
        ["Nazon", "Delmas", "Centre-Ville"],
    ),
    (
        "Station Canapé-Vert",
        "taptap",
        18.5340, -72.3220,
        "Route de Canapé-Vert, accès aux hôpitaux de la zone.",
        ["Canapé-Vert", "Pétion-Ville", "Centre-Ville"],
    ),
    (
        "Station Bourdon",
        "bus",
        18.5380, -72.3280,
        "Avenue Bourdon, axe reliant Centre-Ville et Pétion-Ville.",
        ["Bourdon", "Centre-Ville", "Pétion-Ville"],
    ),
    (
        "Station Turgeau",
        "taptap",
        18.5430, -72.3300,
        "Quartier résidentiel Turgeau, proche des ambassades.",
        ["Turgeau", "Centre-Ville", "Pétion-Ville"],
    ),
    (
        "Station Bel-Air",
        "taptap",
        18.5480, -72.3410,
        "Quartier populaire Bel-Air au nord du Centre-Ville.",
        ["Bel-Air", "Centre-Ville", "Cité Soleil"],
    ),
    (
        "Station Cité Soleil",
        "bus",
        18.5740, -72.3600,
        "Grand terminus de Cité Soleil, zone densément peuplée.",
        ["Cité Soleil", "Centre-Ville", "Drouillard"],
    ),
    (
        "Station Drouillard",
        "bus",
        18.5810, -72.3450,
        "Entrée nord de Cité Soleil vers l'aéroport.",
        ["Drouillard", "Cité Soleil", "Aéroport"],
    ),
    (
        "Station Aéroport Toussaint Louverture",
        "bus",
        18.5790, -72.3090,
        "Terminal arrêt bus face à l'aéroport international.",
        ["Aéroport", "Centre-Ville", "Delmas"],
    ),
    (
        "Station Mais Gâté",
        "bus",
        18.5650, -72.3380,
        "Carrefour Mais Gâté, connexion Delmas / Cité Soleil.",
        ["Mais Gâté", "Delmas", "Cité Soleil"],
    ),
    (
        "Station Delmas 95",
        "taptap",
        18.5750, -72.2840,
        "Terminus haut de Delmas, proche de la frontière Tabarre.",
        ["Delmas 95", "Tabarre", "Pétion-Ville"],
    ),
    (
        "Station Kenscoff",
        "taptap",
        18.4630, -72.2860,
        "Terminus de Kenscoff en altitude, marchés de légumes frais.",
        ["Kenscoff", "Pétion-Ville"],
    ),
    (
        "Station Pèlerin 5",
        "taptap",
        18.5020, -72.2820,
        "Quartier Pèlerin sur les hauteurs de Pétion-Ville.",
        ["Pèlerin", "Pétion-Ville", "Kenscoff"],
    ),
    (
        "Station Gressier",
        "bus",
        18.5430, -72.5090,
        "Terminus de Gressier, accès aux plages à l'ouest.",
        ["Gressier", "Léogâne", "Carrefour"],
    ),
    (
        "Station La Plaine",
        "bus",
        18.5560, -72.2500,
        "Commune de La Plaine, axe vers Croix-des-Bouquets.",
        ["La Plaine", "Croix-des-Bouquets", "Tabarre"],
    ),
    (
        "Station Delmas 19",
        "taptap",
        18.5380, -72.3170,
        "Bas de Delmas, connexion rapide Centre-Ville — Delmas.",
        ["Delmas 19", "Centre-Ville", "Nazon"],
    ),
]


async def seed_stations() -> None:
    """
    Insère les 25 stations réelles si la table stations est vide.
    Idempotent : ne réinsère pas si des données existent déjà.
    """
    from app.models import Station, TransportType  # import local pour éviter circular

    async with AsyncSessionLocal() as session:
        # Vérification : des stations existent-elles déjà ?
        result = await session.execute(select(Station).limit(1))
        if result.scalars().first() is not None:
            logger.info("Seed ignoré : des stations existent déjà en base.")
            return

        logger.info(f"Insertion de {len(STATIONS_SEED)} stations seed...")

        for nom, transport, lat, lng, description, routes in STATIONS_SEED:
            station = Station(
                name=nom,
                transport_type=TransportType(transport),
                latitude=lat,
                longitude=lng,
                # WKTElement construit la géométrie PostGIS depuis WKT
                location=WKTElement(f"POINT({lng} {lat})", srid=4326),
                description=description,
                routes_json=json.dumps(routes, ensure_ascii=False),
                is_verified=True,  # Les stations seed sont considérées vérifiées
            )
            session.add(station)

        try:
            await session.commit()
            logger.info("Seed terminé avec succès.")
        except Exception as e:
            await session.rollback()
            logger.error(f"Erreur lors du seed : {e}")
            raise
