import 'package:latlong2/latlong.dart';

/// Lieu prédéfini de Port-au-Prince proposé dans la recherche.
class PlaceLocation {
  final String id;
  final String name;
  final String zone; // Quartier / commune parent
  final LatLng coordinates;
  final List<String> keywords; // mots-clés alternatifs pour la recherche

  const PlaceLocation({
    required this.id,
    required this.name,
    required this.zone,
    required this.coordinates,
    this.keywords = const [],
  });

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if (zone.toLowerCase().contains(q)) return true;
    return keywords.any((k) => k.toLowerCase().contains(q));
  }
}

// ─── 40 lieux prédéfinis de Port-au-Prince ────────────────────────────────────

const kPortAuPrincePlaces = <PlaceLocation>[
  // ── Centre-Ville ────────────────────────────────────────────────────────────
  PlaceLocation(
    id: 'champ_de_mars',
    name: 'Champ de Mars',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5425, -72.3386),
    keywords: ['champs', 'center', 'palais national'],
  ),
  PlaceLocation(
    id: 'marche_hyppolite',
    name: 'Marché Hyppolite (Fer)',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5460, -72.3440),
    keywords: ['marche', 'fer', 'hyppolite'],
  ),
  PlaceLocation(
    id: 'port_pap',
    name: 'Port de Port-au-Prince',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5490, -72.3550),
    keywords: ['port', 'wharf', 'dock'],
  ),
  PlaceLocation(
    id: 'bicentenaire',
    name: 'Bicentenaire',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5500, -72.3490),
    keywords: ['bord de mer', 'exposition'],
  ),

  // ── Pétion-Ville ────────────────────────────────────────────────────────────
  PlaceLocation(
    id: 'petionville_centre',
    name: 'Centre Pétion-Ville',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.5131, -72.2863),
    keywords: ['petion ville', 'pv', 'marché pétion'],
  ),
  PlaceLocation(
    id: 'place_st_pierre',
    name: 'Place Saint-Pierre',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.5120, -72.2870),
    keywords: ['saint pierre', 'place pv'],
  ),
  PlaceLocation(
    id: 'jalousie',
    name: 'Jalousie',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.5055, -72.2940),
    keywords: ['village soleil'],
  ),
  PlaceLocation(
    id: 'pelerin',
    name: 'Pèlerin',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.5020, -72.2820),
    keywords: ['pelerin 5', 'pelerin 4'],
  ),
  PlaceLocation(
    id: 'kenscoff',
    name: 'Kenscoff',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.4630, -72.2860),
    keywords: ['montagne', 'legumes'],
  ),

  // ── Delmas ──────────────────────────────────────────────────────────────────
  PlaceLocation(
    id: 'delmas_32',
    name: 'Delmas 32',
    zone: 'Delmas',
    coordinates: LatLng(18.5474, -72.3121),
    keywords: ['d32', 'carrefour delmas'],
  ),
  PlaceLocation(
    id: 'delmas_33',
    name: 'Delmas 33',
    zone: 'Delmas',
    coordinates: LatLng(18.5490, -72.3095),
    keywords: ['d33'],
  ),
  PlaceLocation(
    id: 'delmas_75',
    name: 'Delmas 75',
    zone: 'Delmas',
    coordinates: LatLng(18.5612, -72.3050),
    keywords: ['d75', 'haut delmas'],
  ),
  PlaceLocation(
    id: 'delmas_95',
    name: 'Delmas 95',
    zone: 'Delmas',
    coordinates: LatLng(18.5750, -72.2840),
    keywords: ['d95'],
  ),
  PlaceLocation(
    id: 'nazon',
    name: 'Nazon',
    zone: 'Delmas',
    coordinates: LatLng(18.5570, -72.3200),
    keywords: ['carrefour nazon'],
  ),
  PlaceLocation(
    id: 'delmas_19',
    name: 'Delmas 19',
    zone: 'Delmas',
    coordinates: LatLng(18.5380, -72.3170),
    keywords: ['d19', 'bas delmas'],
  ),

  // ── Tabarre ─────────────────────────────────────────────────────────────────
  PlaceLocation(
    id: 'tabarre',
    name: 'Tabarre',
    zone: 'Tabarre',
    coordinates: LatLng(18.5799, -72.2991),
    keywords: ['zone industrielle', 'tabarre 41'],
  ),
  PlaceLocation(
    id: 'aeroport',
    name: 'Aéroport Toussaint Louverture',
    zone: 'Tabarre',
    coordinates: LatLng(18.5790, -72.3090),
    keywords: ['airport', 'aeroport', 'toussaint'],
  ),
  PlaceLocation(
    id: 'croix_bouquets',
    name: 'Croix-des-Bouquets',
    zone: 'Croix-des-Bouquets',
    coordinates: LatLng(18.5780, -72.2290),
    keywords: ['croix bouquets', 'cb'],
  ),
  PlaceLocation(
    id: 'la_plaine',
    name: 'La Plaine',
    zone: 'Croix-des-Bouquets',
    coordinates: LatLng(18.5560, -72.2500),
    keywords: ['plaine'],
  ),

  // ── Nord PAP ────────────────────────────────────────────────────────────────
  PlaceLocation(
    id: 'cite_soleil',
    name: 'Cité Soleil',
    zone: 'Cité Soleil',
    coordinates: LatLng(18.5740, -72.3600),
    keywords: ['cite soleil', 'cs'],
  ),
  PlaceLocation(
    id: 'drouillard',
    name: 'Drouillard',
    zone: 'Cité Soleil',
    coordinates: LatLng(18.5810, -72.3450),
    keywords: ['nord'],
  ),
  PlaceLocation(
    id: 'mais_gate',
    name: 'Mais Gâté',
    zone: 'Delmas',
    coordinates: LatLng(18.5650, -72.3380),
    keywords: ['mais gate'],
  ),
  PlaceLocation(
    id: 'bel_air',
    name: 'Bel Air',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5480, -72.3410),
    keywords: ['belair'],
  ),
  PlaceLocation(
    id: 'turgeau',
    name: 'Turgeau',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5430, -72.3300),
    keywords: ['ambassades'],
  ),
  PlaceLocation(
    id: 'bourdon',
    name: 'Bourdon',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5380, -72.3280),
    keywords: ['avenue bourdon'],
  ),
  PlaceLocation(
    id: 'canape_vert',
    name: 'Canapé-Vert',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5340, -72.3220),
    keywords: ['canape vert', 'hopital'],
  ),

  // ── Sud PAP ─────────────────────────────────────────────────────────────────
  PlaceLocation(
    id: 'martissant',
    name: 'Martissant',
    zone: 'Sud',
    coordinates: LatLng(18.5190, -72.3560),
    keywords: ['route nationale 2', 'rn2'],
  ),
  PlaceLocation(
    id: 'carrefour',
    name: 'Carrefour',
    zone: 'Carrefour',
    coordinates: LatLng(18.5348, -72.3875),
    keywords: ['carrefour', 'rn2'],
  ),
  PlaceLocation(
    id: 'leogane',
    name: 'Léogâne',
    zone: 'Léogâne',
    coordinates: LatLng(18.5101, -72.6300),
    keywords: ['leogane', 'grand goave'],
  ),
  PlaceLocation(
    id: 'gressier',
    name: 'Gressier',
    zone: 'Gressier',
    coordinates: LatLng(18.5430, -72.5090),
    keywords: ['plages', 'kaliko'],
  ),

  // ── Hôpitaux & institutions ──────────────────────────────────────────────────
  PlaceLocation(
    id: 'hopital_etat',
    name: 'Hôpital Général de l\'État',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5396, -72.3382),
    keywords: ['hopital general', 'hge', 'medecin'],
  ),
  PlaceLocation(
    id: 'canape_vert_hop',
    name: 'Hôpital Canapé-Vert',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.5321, -72.3189),
    keywords: ['hopital canape', 'clinique'],
  ),
  PlaceLocation(
    id: 'university_etat',
    name: 'Université d\'État d\'Haïti',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5430, -72.3370),
    keywords: ['ueh', 'universite', 'faculte'],
  ),
  PlaceLocation(
    id: 'marche_salomon',
    name: 'Marché Salomon',
    zone: 'Centre-Ville',
    coordinates: LatLng(18.5420, -72.3320),
    keywords: ['salomon', 'marche'],
  ),
  PlaceLocation(
    id: 'plaza_caribe',
    name: 'Plaza Caribe',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.5140, -72.2910),
    keywords: ['plaza', 'shopping'],
  ),
  PlaceLocation(
    id: 'karibe_hotel',
    name: 'Karibe / Juvenat',
    zone: 'Pétion-Ville',
    coordinates: LatLng(18.5000, -72.2980),
    keywords: ['karibe', 'juvenat', 'hotel'],
  ),
];
