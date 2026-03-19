/// Service HTTP centralisé pour l'API KOTE MAP (FastAPI backend).
///
/// Architecture :
///   - Toutes les requêtes passent par [ApiService]
///   - L'URL de base est définie dans [ApiConstants] (changer pour Render.com en prod)
///   - Chaque méthode gère ses erreurs et retourne null / liste vide en cas d'échec
///   - Timeout global : 15 secondes
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ─── URL de base ──────────────────────────────────────────────────────────────
//
// En développement local :   http://localhost:8000
// En production (Render) :   https://kotemap-api.onrender.com
//
// TODO : remplacer par ton URL Render.com une fois déployé

class ApiConstants {
  ApiConstants._();

  // Changer cette URL après déploiement sur Render.com
  static const String baseUrl = kDebugMode
      ? 'http://localhost:8000'
      : 'https://kotemap-api.onrender.com';

  static const Duration timeout = Duration(seconds: 15);
}

// ─── Modèles de réponse API ───────────────────────────────────────────────────

/// Station reçue de l'API (avant mapping vers le modèle domaine Flutter)
class ApiStation {
  final int id;
  final String name;
  final String transportType; // "taptap" | "bus"
  final double latitude;
  final double longitude;
  final String? description;
  final String? routesJson;
  final bool isVerified;
  final double? distanceMeters;

  const ApiStation({
    required this.id,
    required this.name,
    required this.transportType,
    required this.latitude,
    required this.longitude,
    this.description,
    this.routesJson,
    required this.isVerified,
    this.distanceMeters,
  });

  factory ApiStation.fromJson(Map<String, dynamic> json) => ApiStation(
        id: json['id'] as int,
        name: json['name'] as String,
        transportType: json['transport_type'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        description: json['description'] as String?,
        routesJson: json['routes_json'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        distanceMeters: json['distance_meters'] != null
            ? (json['distance_meters'] as num).toDouble()
            : null,
      );
}

/// Incident de sécurité reçu de l'API
class ApiIncident {
  final int id;
  final String title;
  final String description;
  final String severity; // "high" | "medium" | "low"
  final double latitude;
  final double longitude;
  final String createdAt;
  final bool isActive;

  const ApiIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.isActive,
  });

  factory ApiIncident.fromJson(Map<String, dynamic> json) => ApiIncident(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        severity: json['severity'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        createdAt: json['created_at'] as String,
        isActive: json['is_active'] as bool? ?? true,
      );
}

/// Option d'itinéraire retournée par Claude AI
class ApiItineraryOption {
  final String type; // "rapide" | "economique" | "sur"
  final String label;
  final int durationMinutes;
  final int costHtg;
  final List<String> steps;
  final List<String> transportTypes;
  final String? safetyNote;
  final List<String> warnings;

  const ApiItineraryOption({
    required this.type,
    required this.label,
    required this.durationMinutes,
    required this.costHtg,
    required this.steps,
    required this.transportTypes,
    this.safetyNote,
    this.warnings = const [],
  });

  factory ApiItineraryOption.fromJson(Map<String, dynamic> json) =>
      ApiItineraryOption(
        type: json['type'] as String,
        label: json['label'] as String,
        durationMinutes: (json['duration_minutes'] as num).toInt(),
        costHtg: (json['cost_htg'] as num).toInt(),
        steps: List<String>.from(json['steps'] as List),
        transportTypes: List<String>.from(json['transport_types'] as List),
        safetyNote: json['safety_note'] as String?,
        warnings: json['warnings'] != null
            ? List<String>.from(json['warnings'] as List)
            : [],
      );
}

/// Réponse complète de l'endpoint /itineraries/
class ApiItineraryResponse {
  final List<ApiItineraryOption> options;
  final String source; // "claude_ai" | "fallback_local"
  final List<ApiIncident> nearbyIncidents;

  const ApiItineraryResponse({
    required this.options,
    required this.source,
    this.nearbyIncidents = const [],
  });

  factory ApiItineraryResponse.fromJson(Map<String, dynamic> json) =>
      ApiItineraryResponse(
        options: (json['options'] as List)
            .map((o) => ApiItineraryOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        source: json['source'] as String,
        nearbyIncidents: json['nearby_incidents'] != null
            ? (json['nearby_incidents'] as List)
                .map((i) =>
                    ApiIncident.fromJson(i as Map<String, dynamic>))
                .toList()
            : [],
      );
}

// ─── Service principal ────────────────────────────────────────────────────────

class ApiService {
  ApiService._();

  static final _client = http.Client();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── Helper : GET avec gestion d'erreur ──────────────────────────────────────

  static Future<Map<String, dynamic>?> _get(String path,
      {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path')
          .replace(queryParameters: params);

      final response =
          await _client.get(uri, headers: _headers).timeout(ApiConstants.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      debugPrint('API GET $path → HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('API GET $path → erreur : $e');
      return null;
    }
  }

  // ── Helper : POST avec gestion d'erreur ─────────────────────────────────────

  static Future<Map<String, dynamic>?> _post(
      String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');

      final response = await _client
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(ApiConstants.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }

      debugPrint('API POST $path → HTTP ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('API POST $path → erreur : $e');
      return null;
    }
  }

  // ─── Stations ──────────────────────────────────────────────────────────────

  /// Charge toutes les stations actives.
  static Future<List<ApiStation>> getStations({int limit = 100}) async {
    final data = await _get('/stations/', params: {'limit': '$limit'});
    if (data == null) return [];

    try {
      final list = data['stations'] as List;
      return list
          .map((s) => ApiStation.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erreur parsing stations : $e');
      return [];
    }
  }

  /// Stations dans un rayon autour d'un point GPS (en mètres).
  static Future<List<ApiStation>> getNearbyStations({
    required double lat,
    required double lng,
    double radiusM = 1500,
    int limit = 10,
  }) async {
    final data = await _get('/stations/nearby', params: {
      'lat': '$lat',
      'lng': '$lng',
      'radius_m': '$radiusM',
      'limit': '$limit',
    });
    if (data == null) return [];

    try {
      final list = data['stations'] as List;
      return list
          .map((s) => ApiStation.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erreur parsing nearby stations : $e');
      return [];
    }
  }

  // ─── Itinéraires (Claude AI) ───────────────────────────────────────────────

  /// Calcule 3 options d'itinéraire via Claude AI.
  static Future<ApiItineraryResponse?> getItinerary({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String? originName,
    String? destinationName,
  }) async {
    final body = <String, dynamic>{
      'origin_lat': originLat,
      'origin_lng': originLng,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      if (originName != null) 'origin_name': originName,
      if (destinationName != null) 'destination_name': destinationName,
    };

    final data = await _post('/itineraries/', body);
    if (data == null) return null;

    try {
      return ApiItineraryResponse.fromJson(data);
    } catch (e) {
      debugPrint('Erreur parsing itinerary response : $e');
      return null;
    }
  }

  // ─── Incidents de sécurité ─────────────────────────────────────────────────

  /// Liste les incidents actifs dans un rayon autour d'un point.
  static Future<List<ApiIncident>> getNearbyIncidents({
    required double lat,
    required double lng,
    double radiusM = 2000,
  }) async {
    final data = await _get('/incidents/nearby', params: {
      'lat': '$lat',
      'lng': '$lng',
      'radius_m': '$radiusM',
    });
    if (data == null) return [];

    try {
      final list = data['incidents'] as List;
      return list
          .map((i) => ApiIncident.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Erreur parsing incidents : $e');
      return [];
    }
  }

  /// Signale un incident de sécurité.
  static Future<bool> createIncident({
    required String title,
    required String description,
    required String severity,
    required double lat,
    required double lng,
    int expiresInHours = 24,
  }) async {
    final data = await _post('/incidents/', {
      'title': title,
      'description': description,
      'severity': severity,
      'latitude': lat,
      'longitude': lng,
      'expires_in_hours': expiresInHours,
    });
    return data != null;
  }

  // ─── Contributions ─────────────────────────────────────────────────────────

  /// Soumet une proposition de nouvelle station.
  /// [token] : JWT optionnel si l'utilisateur est connecté.
  static Future<bool> createContribution({
    required String stationName,
    required String transportType,
    required double lat,
    required double lng,
    String? description,
    String? routesJson,
    String? token,
  }) async {
    final body = {
      'station_name': stationName,
      'transport_type': transportType,
      'latitude': lat,
      'longitude': lng,
      if (description != null) 'description': description,
      if (routesJson != null) 'routes_json': routesJson,
    };

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/contributions/');
      final headers = {
        ..._headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(ApiConstants.timeout);

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Erreur createContribution : $e');
      return false;
    }
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  /// Connexion — retourne le token JWT ou null en cas d'échec.
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return data?['access_token'] as String?;
  }

  /// Inscription — retourne true si le compte a été créé.
  static Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final data = await _post('/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    });
    return data != null;
  }
}
