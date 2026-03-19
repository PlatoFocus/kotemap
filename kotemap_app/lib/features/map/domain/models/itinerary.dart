import 'package:latlong2/latlong.dart';

enum ItineraryType { fastest, safest, cheapest }

class ItineraryStep {
  final String label;
  final ItineraryType transport;

  const ItineraryStep({required this.label, required this.transport});
}

class Itinerary {
  final String id;
  final ItineraryType type;
  final int priceFtg;
  final int durationMin;
  final List<ItineraryStep> steps;
  final List<LatLng> polyline;

  const Itinerary({
    required this.id,
    required this.type,
    required this.priceFtg,
    required this.durationMin,
    required this.steps,
    this.polyline = const [],
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
