"""
Modèles SQLAlchemy pour KOTE MAP.
Chaque table correspond à une entité métier principale.
PostGIS est utilisé pour les colonnes géospatiales (geometry POINT).
"""

import enum
from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import relationship

from app.database import Base


# ---------------------------------------------------------------------------
# Enums métier
# ---------------------------------------------------------------------------

class TransportType(str, enum.Enum):
    taptap = "taptap"
    bus = "bus"


class StationStatus(str, enum.Enum):
    active = "active"
    inactive = "inactive"
    pending = "pending"


class IncidentSeverity(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"


class UserRole(str, enum.Enum):
    user = "user"
    contributor = "contributor"
    admin = "admin"


class ContributionStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


# ---------------------------------------------------------------------------
# Table : stations
# Les arrêts/stations de taptap et bus dans Port-au-Prince.
# ---------------------------------------------------------------------------

class Station(Base):
    __tablename__ = "stations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, index=True)
    transport_type = Column(Enum(TransportType), nullable=False)
    status = Column(Enum(StationStatus), default=StationStatus.active, nullable=False)

    # Colonnes float pour accès direct sans désérialisation WKB
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)

    # Colonne géospatiale PostGIS — utilisée pour ST_DWithin, ST_Distance, etc.
    location = Column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=False,
    )

    description = Column(Text, nullable=True)
    # Liste des routes desservies, stockée en JSON string ex: '["Pétion-Ville","Centre-Ville"]'
    routes_json = Column(Text, nullable=True)

    # Indique si la station a été vérifiée par un contributeur approuvé
    is_verified = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )

    # Relations
    contributions = relationship("Contribution", back_populates="station")


# ---------------------------------------------------------------------------
# Table : users
# Gestion des comptes (utilisateurs anonymes, contributeurs, admins).
# ---------------------------------------------------------------------------

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.user, nullable=False)
    is_active = Column(Boolean, default=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relations
    incidents = relationship("Incident", back_populates="user")
    contributions = relationship("Contribution", back_populates="user")


# ---------------------------------------------------------------------------
# Table : incidents
# Signalements de sécurité géolocalisés (insécurité, blocage route, etc.).
# ---------------------------------------------------------------------------

class Incident(Base):
    __tablename__ = "incidents"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    severity = Column(Enum(IncidentSeverity), default=IncidentSeverity.medium, nullable=False)

    # Coordonnées float pour accès rapide
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)

    # Géométrie PostGIS pour les requêtes spatiales
    location = Column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=False,
    )

    # Un incident reste actif jusqu'à expires_at (ou indéfiniment si NULL)
    is_active = Column(Boolean, default=True)
    expires_at = Column(DateTime, nullable=True)

    # L'auteur du signalement (peut être anonyme → NULL)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relations
    user = relationship("User", back_populates="incidents")


# ---------------------------------------------------------------------------
# Table : contributions
# Propositions de nouvelles stations par la communauté.
# Un admin/contributeur vérifié doit approuver avant d'insérer en stations.
# ---------------------------------------------------------------------------

class Contribution(Base):
    __tablename__ = "contributions"

    id = Column(Integer, primary_key=True, index=True)
    station_name = Column(String(200), nullable=False)
    transport_type = Column(Enum(TransportType), nullable=False)

    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)

    description = Column(Text, nullable=True)
    routes_json = Column(Text, nullable=True)

    status = Column(Enum(ContributionStatus), default=ContributionStatus.pending, nullable=False)

    # Lien vers la station créée après approbation
    station_id = Column(Integer, ForeignKey("stations.id"), nullable=True)

    # L'auteur de la contribution
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    reviewed_at = Column(DateTime, nullable=True)

    # Relations
    user = relationship("User", back_populates="contributions")
    station = relationship("Station", back_populates="contributions")
