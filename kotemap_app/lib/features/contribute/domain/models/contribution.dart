import 'package:latlong2/latlong.dart';
import '../../../map/domain/models/station.dart';

enum ContributionType { newStation, fare, incident, correction }

enum ContributionStatus { pending, validated, toModerate }

class Contribution {
  final String id;
  final ContributionType type;
  final String stationName;
  final StationType vehicleType;
  final SecurityLevel securityLevel;
  final LatLng location;
  final int fareMin;
  final int fareMax;
  final ContributionStatus status;

  const Contribution({
    required this.id,
    required this.type,
    required this.stationName,
    required this.vehicleType,
    required this.securityLevel,
    required this.location,
    required this.fareMin,
    required this.fareMax,
    required this.status,
  });
}
