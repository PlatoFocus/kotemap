"""
Schemas Pydantic pour KOTE MAP.
Convention : XxxCreate = données entrantes, XxxResponse = données sortantes.
On ne retourne jamais hashed_password dans les réponses.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.models import (
    ContributionStatus,
    IncidentSeverity,
    StationStatus,
    TransportType,
    UserRole,
)


# ---------------------------------------------------------------------------
# Schemas : Station
# ---------------------------------------------------------------------------

class StationCreate(BaseModel):
    """Données pour créer une station (contributeur/admin uniquement)."""
    name: str = Field(..., min_length=2, max_length=200)
    transport_type: TransportType
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    description: Optional[str] = None
    routes_json: Optional[str] = None  # ex: '["Route1","Route2"]'

    @field_validator("latitude")
    @classmethod
    def valider_latitude_haiti(cls, v: float) -> float:
        # Port-au-Prince est entre 18.4 et 18.7 de latitude
        if not (17.0 <= v <= 20.0):
            raise ValueError("Latitude hors des limites d'Haïti (17.0–20.0)")
        return v

    @field_validator("longitude")
    @classmethod
    def valider_longitude_haiti(cls, v: float) -> float:
        # Haïti est entre -74.5 et -71.6 de longitude
        if not (-75.0 <= v <= -71.0):
            raise ValueError("Longitude hors des limites d'Haïti (-75.0 à -71.0)")
        return v


class StationResponse(BaseModel):
    """Données retournées pour une station."""
    id: int
    name: str
    transport_type: TransportType
    status: StationStatus
    latitude: float
    longitude: float
    description: Optional[str]
    routes_json: Optional[str]
    is_verified: bool
    created_at: datetime

    # Distance en mètres si calculée via ST_Distance (champ optionnel)
    distance_meters: Optional[float] = None

    model_config = {"from_attributes": True}


class StationListResponse(BaseModel):
    """Liste de stations avec pagination."""
    total: int
    stations: List[StationResponse]


# ---------------------------------------------------------------------------
# Schemas : User / Auth
# ---------------------------------------------------------------------------

class UserRegister(BaseModel):
    """Données pour créer un compte."""
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=100)
    password: str = Field(..., min_length=8, max_length=100)


class UserLogin(BaseModel):
    """Données pour se connecter."""
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """Données publiques d'un utilisateur (sans mot de passe)."""
    id: int
    email: str
    username: str
    role: UserRole
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    """JWT retourné après connexion réussie."""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# ---------------------------------------------------------------------------
# Schemas : Incident (signalement de sécurité)
# ---------------------------------------------------------------------------

class IncidentCreate(BaseModel):
    """Données pour signaler un incident de sécurité."""
    title: str = Field(..., min_length=3, max_length=200)
    description: str = Field(..., min_length=10)
    severity: IncidentSeverity = IncidentSeverity.medium
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    # Durée de validité en heures (None = jusqu'à suppression manuelle)
    expires_in_hours: Optional[int] = Field(default=24, ge=1, le=168)


class IncidentResponse(BaseModel):
    """Données retournées pour un incident."""
    id: int
    title: str
    description: str
    severity: IncidentSeverity
    latitude: float
    longitude: float
    is_active: bool
    expires_at: Optional[datetime]
    created_at: datetime
    # Auteur (si non anonyme)
    username: Optional[str] = None

    model_config = {"from_attributes": True}


class IncidentListResponse(BaseModel):
    total: int
    incidents: List[IncidentResponse]


# ---------------------------------------------------------------------------
# Schemas : Contribution (proposition de station)
# ---------------------------------------------------------------------------

class ContributionCreate(BaseModel):
    """Données pour proposer une nouvelle station."""
    station_name: str = Field(..., min_length=2, max_length=200)
    transport_type: TransportType
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    description: Optional[str] = None
    routes_json: Optional[str] = None


class ContributionResponse(BaseModel):
    """Données retournées pour une contribution."""
    id: int
    station_name: str
    transport_type: TransportType
    latitude: float
    longitude: float
    description: Optional[str]
    routes_json: Optional[str]
    status: ContributionStatus
    created_at: datetime

    model_config = {"from_attributes": True}


class ContributionListResponse(BaseModel):
    total: int
    contributions: List[ContributionResponse]


# ---------------------------------------------------------------------------
# Schemas : Itinéraire (réponse Claude AI)
# ---------------------------------------------------------------------------

class ItineraryRequest(BaseModel):
    """Requête pour calculer un itinéraire entre deux points."""
    origin_lat: float = Field(..., ge=-90, le=90)
    origin_lng: float = Field(..., ge=-180, le=180)
    destination_lat: float = Field(..., ge=-90, le=90)
    destination_lng: float = Field(..., ge=-180, le=180)
    # Nom textuel optionnel pour améliorer la réponse IA
    origin_name: Optional[str] = None
    destination_name: Optional[str] = None


class ItineraryOption(BaseModel):
    """Une option d'itinéraire (rapide, économique, sûr)."""
    type: str  # "rapide" | "economique" | "sur"
    label: str  # Titre lisible ex: "Itinéraire Rapide"
    duration_minutes: int
    cost_htg: int  # Coût estimé en Gourdes Haïtiennes
    steps: List[str]  # Instructions étape par étape
    transport_types: List[str]  # ["taptap", "bus"]
    safety_note: Optional[str] = None
    warnings: List[str] = []


class ItineraryResponse(BaseModel):
    """Réponse complète avec 3 options d'itinéraire."""
    origin_name: Optional[str]
    destination_name: Optional[str]
    options: List[ItineraryOption]
    # Indique si la réponse vient de Claude ou du fallback local
    source: str  # "claude_ai" | "fallback_local"
    nearby_incidents: List[IncidentResponse] = []
