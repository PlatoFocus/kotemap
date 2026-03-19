import 'package:latlong2/latlong.dart';

enum ItineraryType { fastest, safest, cheapest }

enum StepTransport { walk, taptap, bus, moto }

class ItineraryStep {
  final String label;
  final ItineraryType transport;
  final StepTransport? mode; // transport mode détecté depuis le label

  const ItineraryStep({required this.label, required this.transport, this.mode});

  /// Détecte le mode de transport depuis le texte de l'étape
  static StepTransport detectMode(String label) {
    final l = label.toLowerCase();
    if (l.contains('bus')) return StepTransport.bus;
    if (l.contains('taptap') || l.contains('tap-tap') || l.contains('tap tap')) return StepTransport.taptap;
    if (l.contains('moto')) return StepTransport.moto;
    if (l.contains('march') || l.contains('pied') || l.contains('walk')) return StepTransport.walk;
    return StepTransport.taptap;
  }
}

class Itinerary {
  final String id;
  final ItineraryType type;
  final int priceFtg;
  final int durationMin;
  final List<ItineraryStep> steps;
  final List<LatLng> polyline;
  final String? safetyNote;
  final List<String> warnings;

  const Itinerary({
    required this.id,
    required this.type,
    required this.priceFtg,
    required this.durationMin,
    required this.steps,
    this.polyline = const [],
    this.safetyNote,
    this.warnings = const [],
  });

  String get typeLabel {
    switch (type) {
      case ItineraryType.fastest:
        return 'Le plus rapide';
      case ItineraryType.safest:
        return 'Le plus sûr';
      case ItineraryType.cheapest:
        return 'Le moins cher';
    }
  }
}
