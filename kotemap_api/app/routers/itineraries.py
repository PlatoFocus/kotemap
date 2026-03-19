"""
Router : /itineraries
Calcul d'itinéraires intelligent via Claude AI avec fallback local.

Flow :
  1. Requête POST avec coordonnées origine/destination
  2. Requête DB : stations proches + incidents actifs dans la zone
  3. Appel Claude API (avec tout le contexte)
  4. Si Claude échoue → fallback local
  5. Retour de 3 options (rapide / économique / sûr)
"""

import logging
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas import IncidentResponse, ItineraryRequest, ItineraryResponse
from app.services.claude_service import get_itinerary_from_claude

logger = logging.getLogger(__name__)

router = APIRouter()

# Rayon de recherche des stations proches du point d'origine/destination (mètres)
NEARBY_STATIONS_RADIUS_M = 1500

# Rayon de recherche des incidents sur le trajet (mètres autour de chaque point)
INCIDENTS_RADIUS_M = 2000


@router.post("/", response_model=ItineraryResponse)
async def calculate_itinerary(
    request: ItineraryRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Calcule un itinéraire en transport en commun entre deux points GPS.

    Retourne 3 options (rapide, économique, sûr) générées par Claude AI
    ou par le fallback local si l'API est indisponible.
    """
    olng, olat = request.origin_lng, request.origin_lat
    dlng, dlat = request.destination_lng, request.destination_lat

    # -------------------------------------------------------------------------
    # Étape 1 : Stations proches de l'origine (SQL brut, évite les problèmes de cast ORM)
    # -------------------------------------------------------------------------
    try:
        rows = (await db.execute(text("""
            SELECT name, transport_type, latitude, longitude,
                   ST_Distance(location::geography, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) AS dist
            FROM stations
            WHERE status = 'active'
              AND ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radius)
            ORDER BY dist LIMIT 5
        """), {"lat": olat, "lng": olng, "radius": NEARBY_STATIONS_RADIUS_M})).mappings().all()

        nearby_stations = [
            {"name": r["name"], "transport_type": r["transport_type"],
             "latitude": r["latitude"], "longitude": r["longitude"],
             "distance_meters": r["dist"]}
            for r in rows
        ]
    except Exception as e:
        logger.error(f"Erreur stations proches : {e}")
        nearby_stations = []

    # -------------------------------------------------------------------------
    # Étape 2 : Incidents actifs dans la zone du trajet
    # -------------------------------------------------------------------------
    try:
        inc_rows = (await db.execute(text("""
            SELECT id, title, description, severity, latitude, longitude,
                   is_active, expires_at, created_at
            FROM incidents
            WHERE is_active = true AND (expires_at IS NULL OR expires_at > NOW())
              AND (
                ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(:olng, :olat), 4326)::geography, :radius)
                OR ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(:dlng, :dlat), 4326)::geography, :radius)
              )
            LIMIT 10
        """), {"olat": olat, "olng": olng, "dlat": dlat, "dlng": dlng,
               "radius": INCIDENTS_RADIUS_M})).mappings().all()

        incidents: list[IncidentResponse] = [
            IncidentResponse(
                id=r["id"], title=r["title"], description=r["description"],
                severity=r["severity"], latitude=r["latitude"], longitude=r["longitude"],
                is_active=r["is_active"], expires_at=r["expires_at"], created_at=r["created_at"],
            )
            for r in inc_rows
        ]
    except Exception as e:
        logger.error(f"Erreur incidents : {e}")
        incidents = []

    # -------------------------------------------------------------------------
    # Étape 3 : Appel Claude AI (avec fallback automatique)
    # -------------------------------------------------------------------------
    try:
        itinerary = await get_itinerary_from_claude(
            origin_lat=request.origin_lat,
            origin_lng=request.origin_lng,
            destination_lat=request.destination_lat,
            destination_lng=request.destination_lng,
            origin_name=request.origin_name,
            destination_name=request.destination_name,
            nearby_stations=nearby_stations,
            incidents=incidents,
        )
    except Exception as e:
        logger.error(f"Erreur inattendue dans calculate_itinerary : {e}")
        raise HTTPException(
            status_code=500,
            detail="Erreur lors du calcul d'itinéraire",
        )

    return itinerary
