"""
Service d'itinéraire IA via Claude API (claude-sonnet-4-20250514).

Architecture :
  1. Tente d'appeler Claude avec un prompt structuré contenant le contexte géo.
  2. Si Claude est indisponible (clé manquante, timeout, erreur), active le fallback local.
  3. Le fallback génère des itinéraires plausibles à partir des stations proches en DB.

Claude reçoit :
  - Les coordonnées d'origine et de destination
  - Les 5 stations les plus proches de chaque point
  - Les incidents actifs dans un rayon de 2 km
  Il doit retourner du JSON structuré (3 options : rapide / economique / sur).
"""

import json
import logging
import math
from typing import Any, Optional

import anthropic

from app.config import settings
from app.schemas import IncidentResponse, ItineraryOption, ItineraryResponse

logger = logging.getLogger(__name__)

# Modèle Claude à utiliser (configurable via .env)
CLAUDE_MODEL = "claude-sonnet-4-20250514"

# Timeout en secondes pour l'appel API Claude
CLAUDE_TIMEOUT = 30

# ---------------------------------------------------------------------------
# Prompt système — donne à Claude le contexte métier de KOTE MAP
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """Tu es l'assistant de navigation de KOTE MAP, une application de transport en commun informel à Port-au-Prince, Haïti.

Le réseau de transport est composé de :
- Taptaps : petits pick-up/minibus colorés, trajet fixe, tarif ~10-25 gourdes
- Bus SOTRÁN : plus grands, plus lents mais moins chers, tarif ~10-15 gourdes

Contexte local important :
- Les rues de Port-au-Prince sont souvent sans nom officiel, on se repère par les carrefours
- La sécurité varie fortement selon les quartiers (Cité Soleil, Martissant = prudence)
- Les heures de pointe sont 6h-9h et 16h-19h (trafic très dense)
- Le coût s'exprime en Gourdes Haïtiennes (HTG), 1 USD ≈ 130 HTG (2024)

Tu dois retourner UNIQUEMENT du JSON valide (pas de markdown, pas d'explication), avec exactement ce format :
{
  "options": [
    {
      "type": "rapide",
      "label": "Itinéraire Rapide",
      "duration_minutes": 25,
      "cost_htg": 50,
      "steps": ["Prendre le taptap au Champ de Mars direction Pétion-Ville", "Descendre à Jalousie", "Marcher 5 min vers la destination"],
      "transport_types": ["taptap"],
      "safety_note": "Trajet sûr en journée",
      "warnings": []
    },
    {
      "type": "economique",
      "label": "Itinéraire Économique",
      "duration_minutes": 40,
      "cost_htg": 20,
      "steps": [...],
      "transport_types": ["bus"],
      "safety_note": null,
      "warnings": []
    },
    {
      "type": "sur",
      "label": "Itinéraire le Plus Sûr",
      "duration_minutes": 35,
      "cost_htg": 40,
      "steps": [...],
      "transport_types": ["taptap", "bus"],
      "safety_note": "Évite les zones à risque signalées",
      "warnings": ["Incident signalé à 500m : Blocage route"]
    }
  ]
}"""


# ---------------------------------------------------------------------------
# Calcul de distance haversine (sans dépendance externe)
# ---------------------------------------------------------------------------

def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Distance à vol d'oiseau entre deux points GPS en kilomètres."""
    R = 6371  # rayon de la Terre en km
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlng / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


# ---------------------------------------------------------------------------
# Fallback local — itinéraires générés sans Claude
# ---------------------------------------------------------------------------

def _generate_fallback_itinerary(
    origin_lat: float,
    origin_lng: float,
    destination_lat: float,
    destination_lng: float,
    origin_name: Optional[str],
    destination_name: Optional[str],
    nearby_stations: list[dict[str, Any]],
    incidents: list[IncidentResponse],
) -> ItineraryResponse:
    """
    Génère 3 options d'itinéraire sans IA, basées sur la distance géographique.
    Utilisé quand Claude API est indisponible.
    """
    distance_km = _haversine_km(origin_lat, origin_lng, destination_lat, destination_lng)

    # Estimation basique : 15 km/h vitesse moyenne taptap en ville
    base_duration = max(10, int(distance_km / 15 * 60))

    orig = origin_name or f"({origin_lat:.4f}, {origin_lng:.4f})"
    dest = destination_name or f"({destination_lat:.4f}, {destination_lng:.4f})"

    # Trouver les stations proches pour enrichir les instructions
    near_origin = nearby_stations[:2] if nearby_stations else []
    station_hint = (
        f"via la station {near_origin[0]['name']}" if near_origin else "en taptap direct"
    )

    warnings: list[str] = []
    for inc in incidents:
        if inc.severity in ("high", "medium"):
            warnings.append(f"Incident signalé : {inc.title}")

    options = [
        ItineraryOption(
            type="rapide",
            label="Itinéraire Rapide",
            duration_minutes=base_duration,
            cost_htg=int(distance_km * 5 + 25),  # tarif estimé par km
            steps=[
                f"Depuis {orig}, prendre un taptap {station_hint}",
                "Suivre la route principale vers votre destination",
                f"Descendre à proximité de {dest}",
                "Marcher jusqu'à la destination finale",
            ],
            transport_types=["taptap"],
            safety_note="Trajet standard, restez vigilant.",
            warnings=warnings,
        ),
        ItineraryOption(
            type="economique",
            label="Itinéraire Économique",
            duration_minutes=int(base_duration * 1.4),
            cost_htg=max(15, int(distance_km * 3)),
            steps=[
                f"Depuis {orig}, prendre le bus SOTRÁN direction Centre-Ville",
                "Correspondance au Champ de Mars si nécessaire",
                f"Continuer vers {dest} en bus ou taptap",
            ],
            transport_types=["bus"],
            safety_note="Option la moins chère, prévoir plus de temps.",
            warnings=[],
        ),
        ItineraryOption(
            type="sur",
            label="Itinéraire le Plus Sûr",
            duration_minutes=int(base_duration * 1.2),
            cost_htg=int(distance_km * 4 + 20),
            steps=[
                f"Depuis {orig}, prendre un taptap vers une zone sûre connue",
                "Rester sur les axes principaux (Route Nationale, Avenue Panaméricaine)",
                f"Rejoindre {dest} par des rues fréquentées",
                "Éviter les trajets nocturnes isolés",
            ],
            transport_types=["taptap"],
            safety_note="Itinéraire privilégiant les axes les plus fréquentés.",
            warnings=warnings,
        ),
    ]

    return ItineraryResponse(
        origin_name=origin_name,
        destination_name=destination_name,
        options=options,
        source="fallback_local",
        nearby_incidents=incidents,
    )


# ---------------------------------------------------------------------------
# Appel Claude API principal
# ---------------------------------------------------------------------------

async def get_itinerary_from_claude(
    origin_lat: float,
    origin_lng: float,
    destination_lat: float,
    destination_lng: float,
    origin_name: Optional[str],
    destination_name: Optional[str],
    nearby_stations: list[dict[str, Any]],
    incidents: list[IncidentResponse],
) -> ItineraryResponse:
    """
    Appelle Claude API pour générer 3 options d'itinéraire.
    Retourne le fallback local en cas d'erreur.
    """
    # Vérification préalable : clé API configurée ?
    if not settings.anthropic_api_key:
        logger.warning("ANTHROPIC_API_KEY non configurée — utilisation du fallback.")
        return _generate_fallback_itinerary(
            origin_lat, origin_lng, destination_lat, destination_lng,
            origin_name, destination_name, nearby_stations, incidents,
        )

    # Construction du prompt utilisateur avec le contexte géographique
    orig_label = origin_name or f"coordonnées ({origin_lat:.4f}, {origin_lng:.4f})"
    dest_label = destination_name or f"coordonnées ({destination_lat:.4f}, {destination_lng:.4f})"

    stations_context = ""
    if nearby_stations:
        stations_list = "\n".join(
            f"  - {s['name']} ({s['transport_type']}) à {s.get('distance_meters', 0):.0f}m"
            for s in nearby_stations[:5]
        )
        stations_context = f"\nStations proches connues :\n{stations_list}"

    incidents_context = ""
    if incidents:
        inc_list = "\n".join(
            f"  - [{inc.severity.upper()}] {inc.title} ({inc.latitude:.4f}, {inc.longitude:.4f})"
            for inc in incidents
        )
        incidents_context = f"\nIncidents de sécurité actifs dans la zone :\n{inc_list}"

    user_prompt = f"""Calcule 3 itinéraires en transport en commun à Port-au-Prince, Haïti.

Départ : {orig_label} (lat: {origin_lat}, lng: {origin_lng})
Destination : {dest_label} (lat: {destination_lat}, lng: {destination_lng})
{stations_context}
{incidents_context}

Retourne uniquement le JSON structuré avec les 3 options (rapide, economique, sur)."""

    try:
        client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

        message = await client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=2048,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_prompt}],
            timeout=CLAUDE_TIMEOUT,
        )

        # Extraction du texte de la réponse
        raw_text = message.content[0].text.strip()

        # Nettoyage si Claude a enveloppé dans des backticks markdown
        if raw_text.startswith("```"):
            raw_text = raw_text.split("```")[1]
            if raw_text.startswith("json"):
                raw_text = raw_text[4:]

        data = json.loads(raw_text)

        # Validation et construction des options
        options = [
            ItineraryOption(
                type=opt["type"],
                label=opt["label"],
                duration_minutes=int(opt["duration_minutes"]),
                cost_htg=int(opt["cost_htg"]),
                steps=opt["steps"],
                transport_types=opt["transport_types"],
                safety_note=opt.get("safety_note"),
                warnings=opt.get("warnings", []),
            )
            for opt in data["options"]
        ]

        logger.info(f"Itinéraire Claude généré ({len(options)} options).")

        return ItineraryResponse(
            origin_name=origin_name,
            destination_name=destination_name,
            options=options,
            source="claude_ai",
            nearby_incidents=incidents,
        )

    except json.JSONDecodeError as e:
        logger.error(f"Claude a retourné du JSON invalide : {e}")
        return _generate_fallback_itinerary(
            origin_lat, origin_lng, destination_lat, destination_lng,
            origin_name, destination_name, nearby_stations, incidents,
        )
    except anthropic.APITimeoutError:
        logger.warning("Timeout Claude API — basculement sur le fallback.")
        return _generate_fallback_itinerary(
            origin_lat, origin_lng, destination_lat, destination_lng,
            origin_name, destination_name, nearby_stations, incidents,
        )
    except anthropic.APIError as e:
        logger.error(f"Erreur Claude API : {e}")
        return _generate_fallback_itinerary(
            origin_lat, origin_lng, destination_lat, destination_lng,
            origin_name, destination_name, nearby_stations, incidents,
        )
    except Exception as e:
        logger.error(f"Erreur inattendue dans le service Claude : {e}")
        return _generate_fallback_itinerary(
            origin_lat, origin_lng, destination_lat, destination_lng,
            origin_name, destination_name, nearby_stations, incidents,
        )
