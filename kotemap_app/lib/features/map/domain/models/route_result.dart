import 'package:latlong2/latlong.dart';

// ─── Maneuver types ───────────────────────────────────────────────────────────

enum ManeuverType {
  depart,
  arrive,
  turnLeft,
  turnRight,
  slightLeft,
  slightRight,
  sharpLeft,
  sharpRight,
  straight,
  uturn,
  roundabout,
  unknown,
}

// ─── A single turn-by-turn instruction ───────────────────────────────────────

class RouteStep {
  final String instruction;
  final double distanceM;
  final double durationSec;
  final ManeuverType maneuver;
  final LatLng location;

  const RouteStep({
    required this.instruction,
    required this.distanceM,
    required this.durationSec,
    required this.maneuver,
    required this.location,
  });
}

// ─── Full route result from OSRM ─────────────────────────────────────────────

class RouteResult {
  final List<LatLng> polyline;
  final List<RouteStep> steps;
  final double distanceM;
  final double durationSec;

  const RouteResult({
    required this.polyline,
    required this.steps,
    required this.distanceM,
    required this.durationSec,
  });

  int get durationMin => (durationSec / 60).round();
  double get distanceKm => distanceM / 1000;

  String get distanceLabel {
    if (distanceM >= 1000) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
    return '${distanceM.round()} m';
  }
}
