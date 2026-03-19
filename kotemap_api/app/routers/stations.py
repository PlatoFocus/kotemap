"""
Router : /stations
CRUD complet + requêtes géospatiales (nearby, nearest).

Endpoints :
  GET  /stations/                   → liste toutes les stations actives
  GET  /stations/{id}               → détail d'une station
  GET  /stations/nearby             → stations dans un rayon donné (ST_DWithin)
  GET  /stations/nearest            → station la plus proche (ST_Distance ORDER BY)
  POST /stations/                   → crée une station (contributeur/admin requis)
  PUT  /stations/{id}/status        → change le statut (admin uniquement)
"""

import json
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from geoalchemy2.elements import WKTElement
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Station, StationStatus, TransportType
from app.routers.auth import get_current_user, require_role
from app.schemas import StationCreate, StationListResponse, StationResponse

logger = logging.getLogger(__name__)

router = APIRouter()


# ---------------------------------------------------------------------------
# Helper : convertir un objet Station ORM en StationResponse
# ---------------------------------------------------------------------------

def _station_to_response(station: Station, distance_m: Optional[float] = None) -> StationResponse:
    """Mappe un objet SQLAlchemy Station vers le schema de réponse."""
    return StationResponse(
        id=station.id,
        name=station.name,
        transport_type=station.transport_type,
        status=station.status,
        latitude=station.latitude,
        longitude=station.longitude,
        description=station.description,
        routes_json=station.routes_json,
        is_verified=station.is_verified,
        created_at=station.created_at,
        distance_meters=distance_m,
    )


# ---------------------------------------------------------------------------
# GET /stations/nearby — doit être déclaré AVANT /stations/{id}
# pour éviter que FastAPI interprète "nearby" comme un ID
# ---------------------------------------------------------------------------

@router.get("/nearby", response_model=StationListResponse)
async def stations_nearby(
    lat: float = Query(..., description="Latitude du point de référence", ge=-90, le=90),
    lng: float = Query(..., description="Longitude du point de référence", ge=-180, le=180),
    radius_m: float = Query(default=1000, description="Rayon de recherche en mètres", ge=50, le=50000),
    transport_type: Optional[TransportType] = Query(default=None, description="Filtrer par type (taptap/bus)"),
    limit: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """
    Retourne les stations dans un rayon donné autour d'un point GPS.
    Utilise ST_DWithin PostGIS pour la recherche géospatiale optimisée.
    """
    # SQL brut paramétré : évite les limitations de casting ORM avec GeoAlchemy2 + pgBouncer
    transport_filter = f"AND transport_type = :transport_type" if transport_type else ""

    raw_sql = text(f"""
        SELECT id, name, transport_type, status, latitude, longitude,
               description, routes_json, is_verified, created_at,
               ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) AS dist
        FROM stations
        WHERE status = 'active'
          {transport_filter}
          AND ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radius)
        ORDER BY dist
        LIMIT :limit
    """)

    params: dict = {"lat": lat, "lng": lng, "radius": radius_m, "limit": limit}
    if transport_type:
        params["transport_type"] = transport_type.value

    try:
        result = await db.execute(raw_sql, params)
        rows = result.mappings().all()
    except Exception as e:
        logger.error(f"Erreur requête nearby : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la recherche géospatiale")

    stations = [
        StationResponse(
            id=r["id"], name=r["name"], transport_type=r["transport_type"],
            status=r["status"], latitude=r["latitude"], longitude=r["longitude"],
            description=r["description"], routes_json=r["routes_json"],
            is_verified=r["is_verified"], created_at=r["created_at"],
            distance_meters=r["dist"],
        )
        for r in rows
    ]

    return StationListResponse(total=len(stations), stations=stations)


@router.get("/nearest", response_model=StationResponse)
async def station_nearest(
    lat: float = Query(..., description="Latitude du point de référence", ge=-90, le=90),
    lng: float = Query(..., description="Longitude du point de référence", ge=-180, le=180),
    transport_type: Optional[TransportType] = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    """Retourne la station active la plus proche du point GPS donné."""
    transport_filter = "AND transport_type = :transport_type" if transport_type else ""

    raw_sql = text(f"""
        SELECT id, name, transport_type, status, latitude, longitude,
               description, routes_json, is_verified, created_at,
               ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) AS dist
        FROM stations
        WHERE status = 'active'
          {transport_filter}
        ORDER BY location::geography <-> ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography
        LIMIT 1
    """)

    params: dict = {"lat": lat, "lng": lng}
    if transport_type:
        params["transport_type"] = transport_type.value

    try:
        result = await db.execute(raw_sql, params)
        row = result.mappings().first()
    except Exception as e:
        logger.error(f"Erreur requête nearest : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la recherche")

    if not row:
        raise HTTPException(status_code=404, detail="Aucune station trouvée")

    return StationResponse(
        id=row["id"], name=row["name"], transport_type=row["transport_type"],
        status=row["status"], latitude=row["latitude"], longitude=row["longitude"],
        description=row["description"], routes_json=row["routes_json"],
        is_verified=row["is_verified"], created_at=row["created_at"],
        distance_meters=row["dist"],
    )


# ---------------------------------------------------------------------------
# GET /stations/ — liste paginée
# ---------------------------------------------------------------------------

@router.get("/", response_model=StationListResponse)
async def list_stations(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    transport_type: Optional[TransportType] = Query(default=None),
    status_filter: Optional[StationStatus] = Query(default=StationStatus.active, alias="status"),
    db: AsyncSession = Depends(get_db),
):
    """Liste toutes les stations avec filtres optionnels."""
    query = select(Station).offset(skip).limit(limit).order_by(Station.name)

    if transport_type:
        query = query.where(Station.transport_type == transport_type)
    if status_filter:
        query = query.where(Station.status == status_filter)

    # Compte total pour la pagination
    count_query = select(func.count(Station.id))
    if transport_type:
        count_query = count_query.where(Station.transport_type == transport_type)
    if status_filter:
        count_query = count_query.where(Station.status == status_filter)

    try:
        result = await db.execute(query)
        count_result = await db.execute(count_query)
        stations = result.scalars().all()
        total = count_result.scalar()
    except Exception as e:
        logger.error(f"Erreur liste stations : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    return StationListResponse(
        total=total,
        stations=[_station_to_response(s) for s in stations],
    )


# ---------------------------------------------------------------------------
# GET /stations/{id} — détail
# ---------------------------------------------------------------------------

@router.get("/{station_id}", response_model=StationResponse)
async def get_station(
    station_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Retourne le détail d'une station par son ID."""
    try:
        result = await db.execute(select(Station).where(Station.id == station_id))
        station = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur get_station {station_id} : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    if not station:
        raise HTTPException(status_code=404, detail=f"Station {station_id} introuvable")

    return _station_to_response(station)


# ---------------------------------------------------------------------------
# POST /stations/ — création (contributeur ou admin)
# ---------------------------------------------------------------------------

@router.post("/", response_model=StationResponse, status_code=status.HTTP_201_CREATED)
async def create_station(
    data: StationCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_role(["contributor", "admin"])),
):
    """
    Crée une nouvelle station.
    Réservé aux contributeurs vérifiés et aux admins.
    """
    new_station = Station(
        name=data.name,
        transport_type=data.transport_type,
        latitude=data.latitude,
        longitude=data.longitude,
        location=WKTElement(f"POINT({data.longitude} {data.latitude})", srid=4326),
        description=data.description,
        routes_json=data.routes_json,
        status=StationStatus.active,
        is_verified=True,  # Créé directement par un contributeur vérifié
    )

    try:
        db.add(new_station)
        await db.commit()
        await db.refresh(new_station)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur création station : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la création de la station")

    return _station_to_response(new_station)


# ---------------------------------------------------------------------------
# PUT /stations/{id}/status — modifier le statut (admin uniquement)
# ---------------------------------------------------------------------------

@router.put("/{station_id}/status", response_model=StationResponse)
async def update_station_status(
    station_id: int,
    new_status: StationStatus,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_role(["admin"])),
):
    """Change le statut d'une station (active/inactive/pending). Admin requis."""
    try:
        result = await db.execute(select(Station).where(Station.id == station_id))
        station = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur get_station pour update : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    if not station:
        raise HTTPException(status_code=404, detail=f"Station {station_id} introuvable")

    station.status = new_status

    try:
        await db.commit()
        await db.refresh(station)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur update statut : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la mise à jour")

    return _station_to_response(station)
