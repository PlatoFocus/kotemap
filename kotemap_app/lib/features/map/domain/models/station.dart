import 'package:latlong2/latlong.dart';
import '../../../../core/services/api_service.dart';

enum StationType { bus, taptap, moto }

enum SecurityLevel { high, moderate, low }

class Station {
  final String id;
  final String name;
  final StationType type;
  final LatLng position;
  final SecurityLevel security;
  final int? fareMin;
  final int? fareMax;
  final double? rating;
  final bool isVerified;

  const Station({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.security = SecurityLevel.moderate,
    this.fareMin,
    this.fareMax,
    this.rating,
    this.isVerified = false,
  });

  /// Convertit une [ApiStation] reçue du backend en modèle domaine Flutter.
  factory Station.fromApi(ApiStation api) {
    final type = switch (api.transportType) {
      'bus' => StationType.bus,
      'taptap' => StationType.taptap,
      _ => StationType.taptap,
    };

    return Station(
      id: 'api_${api.id}',
      name: api.name,
      type: type,
      position: LatLng(api.latitude, api.longitude),
      isVerified: api.isVerified,
      // Les tarifs ne sont pas encore dans l'API — valeurs par défaut
      fareMin: type == StationType.bus ? 15 : 25,
      fareMax: type == StationType.bus ? 25 : 50,
    );
  }

  String get typeLabel {
    switch (type) {
      case StationType.bus:
        return 'Bus';
      case StationType.taptap:
        return 'Tap-tap';
      case StationType.moto:
        return 'Moto-taxi';
    }
  }

  String get typeInitial {
    switch (type) {
      case StationType.bus:
        return 'B';
      case StationType.taptap:
        return 'T';
      case StationType.moto:
        return 'M';
    }
  }
}
