import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../domain/models/route_result.dart';

// ─── OSRM Routing Service ─────────────────────────────────────────────────────
// Uses the public OSRM demo server (OpenStreetMap road network, global coverage)

class RoutingService {
  static const _baseUrl = 'https://router.project-osrm.org';

  static Future<RouteResult?> fetchRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?geometries=geojson&steps=true&overview=full&annotations=false',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return _fallbackRoute(origin, destination);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        return _fallbackRoute(origin, destination);
      }

      final route = data['routes'][0] as Map<String, dynamic>;

      // Parse GeoJSON polyline coordinates
      final coords = (route['geometry']['coordinates'] as List)
          .map((c) => LatLng(
                (c[1] as num).toDouble(),
                (c[0] as num).toDouble(),
              ))
          .toList();

      // Parse turn-by-turn steps from all legs
      final steps = <RouteStep>[];
      for (final leg in route['legs'] as List) {
        for (final step in leg['steps'] as List) {
          final maneuver = step['maneuver'] as Map<String, dynamic>;
          final loc = maneuver['location'] as List;

          steps.add(RouteStep(
            instruction: _buildInstruction(step),
            distanceM: (step['distance'] as num).toDouble(),
            durationSec: (step['duration'] as num).toDouble(),
            maneuver: _parseManeuver(
              maneuver['type'] as String? ?? 'unknown',
              maneuver['modifier'] as String?,
            ),
            location: LatLng(
              (loc[1] as num).toDouble(),
              (loc[0] as num).toDouble(),
            ),
          ));
        }
      }

      return RouteResult(
        polyline: coords,
        steps: steps,
        distanceM: (route['distance'] as num).toDouble(),
        durationSec: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      // Network error or parsing error → use straight-line fallback
      return _fallbackRoute(origin, destination);
    }
  }

  // ─── French instruction from OSRM step fields ──────────────────────────────

  static String _buildInstruction(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map<String, dynamic>;
    final type = maneuver['type'] as String? ?? 'unknown';
    final modifier = maneuver['modifier'] as String?;
    final name = (step['name'] as String?)?.trim() ?? '';
    final namePart = name.isNotEmpty ? ' sur $name' : '';

    return switch (type) {
      'depart' => name.isNotEmpty ? 'Départ$namePart' : 'Départ',
      'arrive' => 'Vous êtes arrivé à destination',
      'turn' => switch (modifier) {
          'left' => 'Tournez à gauche$namePart',
          'right' => 'Tournez à droite$namePart',
          'sharp left' => 'Tournez fortement à gauche$namePart',
          'sharp right' => 'Tournez fortement à droite$namePart',
          'slight left' => 'Légèrement à gauche$namePart',
          'slight right' => 'Légèrement à droite$namePart',
          'uturn' => 'Faites demi-tour',
          _ => 'Continuez tout droit$namePart',
        },
      'merge' || 'new name' || 'continue' =>
        'Continuez tout droit$namePart',
      'fork' => switch (modifier) {
          'left' || 'slight left' => 'Bifurquez à gauche$namePart',
          'right' || 'slight right' => 'Bifurquez à droite$namePart',
          _ => 'Continuez$namePart',
        },
      'end of road' => switch (modifier) {
          'left' => 'Tournez à gauche$namePart',
          'right' => 'Tournez à droite$namePart',
          _ => 'Continuez$namePart',
        },
      'on ramp' => 'Prenez la bretelle$namePart',
      'off ramp' => 'Quittez la bretelle$namePart',
      'roundabout' || 'rotary' => 'Prenez le rond-point$namePart',
      _ => name.isNotEmpty ? 'Continuez$namePart' : 'Continuez tout droit',
    };
  }

  static ManeuverType _parseManeuver(String type, String? modifier) {
    if (type == 'depart') return ManeuverType.depart;
    if (type == 'arrive') return ManeuverType.arrive;
    if (modifier == 'uturn') return ManeuverType.uturn;
    if (modifier == 'straight') return ManeuverType.straight;
    if (type == 'roundabout' || type == 'rotary') {
      return ManeuverType.roundabout;
    }
    return switch (modifier) {
      'left' => ManeuverType.turnLeft,
      'right' => ManeuverType.turnRight,
      'sharp left' => ManeuverType.sharpLeft,
      'sharp right' => ManeuverType.sharpRight,
      'slight left' => ManeuverType.slightLeft,
      'slight right' => ManeuverType.slightRight,
      _ => ManeuverType.unknown,
    };
  }

  // ─── Straight-line fallback (e.g. network unavailable) ────────────────────

  static RouteResult _fallbackRoute(LatLng origin, LatLng destination) {
    final dist = const Distance().as(LengthUnit.Meter, origin, destination);

    return RouteResult(
      polyline: [origin, destination],
      steps: [
        RouteStep(
          instruction: 'Allez vers la destination',
          distanceM: dist,
          durationSec: dist / 5, // ~18 km/h average for Port-au-Prince traffic
          maneuver: ManeuverType.depart,
          location: origin,
        ),
        RouteStep(
          instruction: 'Vous êtes arrivé à destination',
          distanceM: 0,
          durationSec: 0,
          maneuver: ManeuverType.arrive,
          location: destination,
        ),
      ],
      distanceM: dist,
      durationSec: dist / 5,
    );
  }
}
