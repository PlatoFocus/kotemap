import 'package:latlong2/latlong.dart';

enum IncidentSeverity { high, medium, low, resolved }

class Incident {
  final String id;
  final String description;
  final IncidentSeverity severity;
  final LatLng position;
  final String timeAgo;
  final int confirmations;

  const Incident({
    required this.id,
    required this.description,
    required this.severity,
    required this.position,
    required this.timeAgo,
    this.confirmations = 0,
  });
}
