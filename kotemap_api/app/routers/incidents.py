"""
Router : /incidents
Signalements de sécurité géolocalisés.

Endpoints :
  GET  /incidents/              → liste les incidents actifs
  GET  /incidents/nearby        → incidents dans un rayon (ST_DWithin)
  POST /incidents/              → signaler un incident
  PUT  /incidents/{id}/resolve  → marquer comme résolu (auteur ou admin)
  DELETE /incidents/{id}        → supprimer (admin uniquement)
"""

import logging
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from geoalchemy2.elements import WKTElement
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Incident, IncidentSeverity, User
from app.routers.auth import get_current_user, require_role
from app.schemas import IncidentCreate, IncidentListResponse, IncidentResponse

logger = logging.getLogger(__name__)

router = APIRouter()


# ---------------------------------------------------------------------------
# Helper : convertir un objet Incident ORM → IncidentResponse
# ---------------------------------------------------------------------------

def _incident_to_response(incident: Incident) -> IncidentResponse:
    """Mappe un objet SQLAlchemy Incident vers le schema de réponse."""
    return IncidentResponse(
        id=incident.id,
        title=incident.title,
        description=incident.description,
        severity=incident.severity,
        latitude=incident.latitude,
        longitude=incident.longitude,
        is_active=incident.is_active,
        expires_at=incident.expires_at,
        created_at=incident.created_at,
        username=incident.user.username if incident.user else None,
    )


# ---------------------------------------------------------------------------
# Requête de base : incidents actifs non expirés
# ---------------------------------------------------------------------------

def _active_incidents_query():
    """Retourne la requête de base filtrée sur les incidents actifs."""
    now = datetime.utcnow()
    return (
        select(Incident)
        .where(Incident.is_active == True)  # noqa: E712
        .where(
            (Incident.expires_at == None) | (Incident.expires_at > now)  # noqa: E711
        )
    )


# ---------------------------------------------------------------------------
# GET /incidents/nearby — doit être déclaré avant /{id}
# ---------------------------------------------------------------------------

@router.get("/nearby", response_model=IncidentListResponse)
async def incidents_nearby(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_m: float = Query(default=2000, ge=100, le=20000),
    limit: int = Query(default=20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """Retourne les incidents actifs dans un rayon autour d'un point GPS."""
    raw_sql = text("""
        SELECT id, title, description, severity, latitude, longitude,
               is_active, expires_at, created_at, user_id
        FROM incidents
        WHERE is_active = true
          AND (expires_at IS NULL OR expires_at > NOW())
          AND ST_DWithin(location::geography, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radius)
        ORDER BY created_at DESC
        LIMIT :limit
    """)

    try:
        result = await db.execute(raw_sql, {"lat": lat, "lng": lng, "radius": radius_m, "limit": limit})
        rows = result.mappings().all()
    except Exception as e:
        logger.error(f"Erreur incidents_nearby : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la recherche géospatiale")

    incidents = [
        IncidentResponse(
            id=r["id"], title=r["title"], description=r["description"],
            severity=r["severity"], latitude=r["latitude"], longitude=r["longitude"],
            is_active=r["is_active"], expires_at=r["expires_at"], created_at=r["created_at"],
        )
        for r in rows
    ]

    return IncidentListResponse(total=len(incidents), incidents=incidents)


# ---------------------------------------------------------------------------
# GET /incidents/ — liste paginée
# ---------------------------------------------------------------------------

@router.get("/", response_model=IncidentListResponse)
async def list_incidents(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=200),
    severity: Optional[IncidentSeverity] = Query(default=None),
    include_expired: bool = Query(default=False),
    db: AsyncSession = Depends(get_db),
):
    """Liste les incidents avec filtres optionnels."""
    if include_expired:
        query = select(Incident)
    else:
        query = _active_incidents_query()

    if severity:
        query = query.where(Incident.severity == severity)

    query = query.order_by(Incident.created_at.desc()).offset(skip).limit(limit)

    try:
        result = await db.execute(query)
        incidents = result.scalars().all()
    except Exception as e:
        logger.error(f"Erreur liste incidents : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    return IncidentListResponse(
        total=len(incidents),
        incidents=[_incident_to_response(inc) for inc in incidents],
    )


# ---------------------------------------------------------------------------
# POST /incidents/ — signaler un incident
# ---------------------------------------------------------------------------

@router.post("/", response_model=IncidentResponse, status_code=status.HTTP_201_CREATED)
async def create_incident(
    data: IncidentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: Optional[User] = Depends(get_current_user),
):
    """
    Signale un incident de sécurité géolocalisé.
    Les utilisateurs anonymes peuvent signaler (user_id = None).
    """
    # Calcul de la date d'expiration
    expires_at = None
    if data.expires_in_hours:
        expires_at = datetime.utcnow() + timedelta(hours=data.expires_in_hours)

    new_incident = Incident(
        title=data.title,
        description=data.description,
        severity=data.severity,
        latitude=data.latitude,
        longitude=data.longitude,
        location=WKTElement(f"POINT({data.longitude} {data.latitude})", srid=4326),
        is_active=True,
        expires_at=expires_at,
        user_id=current_user.id if current_user else None,
    )

    try:
        db.add(new_incident)
        await db.commit()
        await db.refresh(new_incident)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur création incident : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors du signalement")

    return _incident_to_response(new_incident)


# ---------------------------------------------------------------------------
# PUT /incidents/{id}/resolve — marquer comme résolu
# ---------------------------------------------------------------------------

@router.put("/{incident_id}/resolve", response_model=IncidentResponse)
async def resolve_incident(
    incident_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role(["admin", "contributor"])),
):
    """Marque un incident comme résolu (inactif). Admin ou contributeur requis."""
    try:
        result = await db.execute(select(Incident).where(Incident.id == incident_id))
        incident = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur get incident {incident_id} : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    if not incident:
        raise HTTPException(status_code=404, detail=f"Incident {incident_id} introuvable")

    incident.is_active = False

    try:
        await db.commit()
        await db.refresh(incident)
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur resolve incident : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la mise à jour")

    return _incident_to_response(incident)


# ---------------------------------------------------------------------------
# DELETE /incidents/{id} — suppression (admin uniquement)
# ---------------------------------------------------------------------------

@router.delete("/{incident_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_incident(
    incident_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_role(["admin"])),
):
    """Supprime définitivement un incident. Admin requis."""
    try:
        result = await db.execute(select(Incident).where(Incident.id == incident_id))
        incident = result.scalar_one_or_none()
    except Exception as e:
        logger.error(f"Erreur get incident pour delete : {e}")
        raise HTTPException(status_code=500, detail="Erreur serveur")

    if not incident:
        raise HTTPException(status_code=404, detail=f"Incident {incident_id} introuvable")

    try:
        await db.delete(incident)
        await db.commit()
    except Exception as e:
        await db.rollback()
        logger.error(f"Erreur delete incident : {e}")
        raise HTTPException(status_code=500, detail="Erreur lors de la suppression")
