import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/station.dart';
import '../../domain/models/itinerary.dart';
import '../../domain/models/incident.dart';
import '../../domain/models/route_result.dart';
import '../../data/routing_service.dart';
import '../../../../core/services/api_service.dart';

// ─── Sentinel for nullable copyWith ──────────────────────────────────────────

class _Absent {
  const _Absent();
}

const _none = _Absent();

// ─── Filtre transport ─────────────────────────────────────────────────────────

enum TransportFilter { all, bus, taptap, moto }

// ─── State ────────────────────────────────────────────────────────────────────

class MapState {
  // Map / search
  final LatLng? userLocation;
  final LatLng? origin; // null = use GPS userLocation
  final LatLng? destination;
  final TransportFilter filter;
  final List<Station> stations;
  final List<Itinerary> itineraries;
  final List<Incident> activeIncidents;
  final Itinerary? selectedItinerary;
  final bool showAlert;
  final String? alertMessage;
  final String searchQuery;

  // Navigation
  final bool isNavigating;
  final bool isFetchingRoute;
  final List<LatLng> routePoints; // polyline from OSRM
  final List<RouteStep> routeSteps; // turn-by-turn steps
  final int currentStepIndex;
  final double? remainingDistanceKm;
  final int? remainingTimeMin;
  final String? routeError;
  final bool arrivedAtDestination;

  const MapState({
    this.userLocation,
    this.origin,
    this.destination,
    this.filter = TransportFilter.all,
    this.stations = const [],
    this.itineraries = const [],
    this.activeIncidents = const [],
    this.selectedItinerary,
    this.showAlert = true,
    this.alertMessage,
    this.searchQuery = '',
    this.isNavigating = false,
    this.isFetchingRoute = false,
    this.routePoints = const [],
    this.routeSteps = const [],
    this.currentStepIndex = 0,
    this.remainingDistanceKm,
    this.remainingTimeMin,
    this.routeError,
    this.arrivedAtDestination = false,
  });

  /// The effective starting point: explicit origin or current GPS location.
  LatLng? get effectiveOrigin => origin ?? userLocation;

  MapState copyWith({
    Object? userLocation = _none,
    Object? origin = _none,
    Object? destination = _none,
    TransportFilter? filter,
    List<Station>? stations,
    List<Itinerary>? itineraries,
    List<Incident>? activeIncidents,
    Object? selectedItinerary = _none,
    bool? showAlert,
    Object? alertMessage = _none,
    String? searchQuery,
    bool? isNavigating,
    bool? isFetchingRoute,
    List<LatLng>? routePoints,
    List<RouteStep>? routeSteps,
    int? currentStepIndex,
    Object? remainingDistanceKm = _none,
    Object? remainingTimeMin = _none,
    Object? routeError = _none,
    bool? arrivedAtDestination,
  }) {
    return MapState(
      userLocation: identical(userLocation, _none)
          ? this.userLocation
          : userLocation as LatLng?,
      origin: identical(origin, _none) ? this.origin : origin as LatLng?,
      destination: identical(destination, _none)
          ? this.destination
          : destination as LatLng?,
      filter: filter ?? this.filter,
      stations: stations ?? this.stations,
      itineraries: itineraries ?? this.itineraries,
      activeIncidents: activeIncidents ?? this.activeIncidents,
      selectedItinerary: identical(selectedItinerary, _none)
          ? this.selectedItinerary
          : selectedItinerary as Itinerary?,
      showAlert: showAlert ?? this.showAlert,
      alertMessage: identical(alertMessage, _none)
          ? this.alertMessage
          : alertMessage as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      isNavigating: isNavigating ?? this.isNavigating,
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
      routePoints: routePoints ?? this.routePoints,
      routeSteps: routeSteps ?? this.routeSteps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      remainingDistanceKm: identical(remainingDistanceKm, _none)
          ? this.remainingDistanceKm
          : remainingDistanceKm as double?,
      remainingTimeMin: identical(remainingTimeMin, _none)
          ? this.remainingTimeMin
          : remainingTimeMin as int?,
      routeError: identical(routeError, _none)
          ? this.routeError
          : routeError as String?,
      arrivedAtDestination:
          arrivedAtDestination ?? this.arrivedAtDestination,
    );
  }
}

// ─── Demo data (Port-au-Prince) ───────────────────────────────────────────────

final _demoStations = [
  Station(
    id: 's1',
    name: 'Station Delmas 33',
    type: StationType.bus,
    position: const LatLng(18.5490, -72.3095),
    security: SecurityLevel.moderate,
    fareMin: 35,
    fareMax: 50,
    isVerified: true,
  ),
  Station(
    id: 's2',
    name: 'Carrefour Taptap',
    type: StationType.taptap,
    position: const LatLng(18.5450, -72.3200),
    security: SecurityLevel.low,
    fareMin: 25,
    fareMax: 40,
    isVerified: true,
  ),
  Station(
    id: 's3',
    name: 'Station Pétion-Ville',
    type: StationType.bus,
    position: const LatLng(18.5150, -72.2850),
    security: SecurityLevel.high,
    fareMin: 50,
    fareMax: 75,
    isVerified: true,
  ),
  Station(
    id: 's4',
    name: 'Taptap Fort National',
    type: StationType.taptap,
    position: const LatLng(18.5520, -72.3380),
    security: SecurityLevel.low,
    fareMin: 20,
    fareMax: 35,
    isVerified: false,
  ),
  Station(
    id: 's5',
    name: 'Moto-taxi Delmas 65',
    type: StationType.moto,
    position: const LatLng(18.5330, -72.3050),
    security: SecurityLevel.moderate,
    fareMin: 50,
    fareMax: 100,
    isVerified: false,
  ),
];

final _demoItineraries = [
  Itinerary(
    id: 'i1',
    type: ItineraryType.fastest,
    priceFtg: 75,
    durationMin: 22,
    steps: [
      ItineraryStep(label: 'Taptap Delmas', transport: ItineraryType.fastest),
      ItineraryStep(label: 'Bus PV', transport: ItineraryType.safest),
    ],
    polyline: [
      const LatLng(18.5474, -72.3380),
      const LatLng(18.5490, -72.3095),
      const LatLng(18.5150, -72.2850),
    ],
  ),
  Itinerary(
    id: 'i2',
    type: ItineraryType.safest,
    priceFtg: 90,
    durationMin: 30,
    steps: [
      ItineraryStep(label: 'Bus direct', transport: ItineraryType.safest),
    ],
    polyline: [
      const LatLng(18.5474, -72.3380),
      const LatLng(18.5350, -72.3200),
      const LatLng(18.5150, -72.2850),
    ],
  ),
  Itinerary(
    id: 'i3',
    type: ItineraryType.cheapest,
    priceFtg: 50,
    durationMin: 40,
    steps: [
      ItineraryStep(
          label: 'Taptap Carrefour', transport: ItineraryType.fastest),
      ItineraryStep(label: 'Taptap Delmas', transport: ItineraryType.fastest),
      ItineraryStep(label: 'Bus PV', transport: ItineraryType.safest),
    ],
  ),
];

final _demoIncidents = [
  Incident(
    id: 'inc1',
    description: 'Bel Air — Blocus signalé',
    severity: IncidentSeverity.high,
    position: const LatLng(18.5520, -72.3380),
    timeAgo: 'Il y a 45 min',
    confirmations: 4,
  ),
];

// ─── Notifier ─────────────────────────────────────────────────────────────────

class MapNotifier extends Notifier<MapState> {
  @override
  MapState build() {
    // Charger les vraies stations en arrière-plan dès le démarrage
    Future.microtask(loadStations);
    return MapState(
      userLocation: const LatLng(18.5474, -72.3380),
      stations: _demoStations,   // Données demo immédiates — remplacées par l'API
      itineraries: _demoItineraries,
      activeIncidents: _demoIncidents,
      selectedItinerary: _demoItineraries.first,
      showAlert: true,
      alertMessage: 'Bel Air — incident signalé · route alternative disponible',
    );
  }

  // ─── Chargement des stations depuis l'API ────────────────────────────────

  Future<void> loadStations() async {
    try {
      final apiStations = await ApiService.getStations(limit: 100);
      if (apiStations.isEmpty) return; // Garder les données demo si API muette

      final stations = apiStations.map(Station.fromApi).toList();
      state = state.copyWith(stations: stations);
      debugPrint('✓ ${stations.length} stations chargées depuis l\'API');
    } catch (e) {
      debugPrint('Erreur chargement stations API : $e');
      // Silencieux — on garde les données demo
    }
  }

  // ─── Calcul d'itinéraire via Claude AI ──────────────────────────────────

  Future<void> loadItineraries({
    String? originName,
    String? destinationName,
  }) async {
    final origin = state.effectiveOrigin;
    final destination = state.destination;
    if (origin == null || destination == null) return;

    state = state.copyWith(
      itineraries: [],
      selectedItinerary: null,
    );

    try {
      final response = await ApiService.getItinerary(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destinationLat: destination.latitude,
        destinationLng: destination.longitude,
        originName: originName,
        destinationName: destinationName,
      );

      if (response == null) {
        // API indisponible — garder les itinéraires demo
        state = state.copyWith(itineraries: _demoItineraries);
        return;
      }

      // Convertir les options API → modèles Itinerary Flutter
      final itineraries = response.options.map((opt) {
        final type = switch (opt.type) {
          'rapide' => ItineraryType.fastest,
          'economique' => ItineraryType.cheapest,
          'sur' => ItineraryType.safest,
          _ => ItineraryType.fastest,
        };

        return Itinerary(
          id: 'api_${opt.type}',
          type: type,
          priceFtg: opt.costHtg,
          durationMin: opt.durationMinutes,
          steps: opt.steps.map((s) => ItineraryStep(
            label: s,
            transport: type,
          )).toList(),
        );
      }).toList();

      // Alertes incidents remontées par l'IA
      final incidentWarnings = response.nearbyIncidents
          .where((i) => i.isActive)
          .map((i) => Incident(
                id: 'api_${i.id}',
                description: '${i.title} — ${i.description}',
                severity: switch (i.severity) {
                  'high' => IncidentSeverity.high,
                  'medium' => IncidentSeverity.medium,
                  _ => IncidentSeverity.low,
                },
                position: LatLng(i.latitude, i.longitude),
                timeAgo: _timeAgo(i.createdAt),
                confirmations: 1,
              ))
          .toList();

      final allIncidents = [...state.activeIncidents, ...incidentWarnings];

      state = state.copyWith(
        itineraries: itineraries,
        selectedItinerary: itineraries.isNotEmpty ? itineraries.first : null,
        activeIncidents: allIncidents,
        showAlert: incidentWarnings.isNotEmpty,
        alertMessage: incidentWarnings.isNotEmpty
            ? incidentWarnings.first.description
            : null,
      );

      debugPrint('✓ Itinéraires chargés (source: ${response.source})');
    } catch (e) {
      debugPrint('Erreur chargement itinéraires : $e');
      state = state.copyWith(itineraries: _demoItineraries);
    }
  }

  /// Formate une date ISO en "Il y a X min/h".
  String _timeAgo(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      return 'Il y a ${diff.inDays}j';
    } catch (_) {
      return '';
    }
  }

  // ─── Search / filter ──────────────────────────────────────────────────────

  void setFilter(TransportFilter filter) =>
      state = state.copyWith(filter: filter);

  void setSearchQuery(String q) =>
      state = state.copyWith(searchQuery: q);

  // ─── Points de carte ──────────────────────────────────────────────────────

  void setUserLocation(LatLng loc) =>
      state = state.copyWith(userLocation: loc);

  void setOrigin(LatLng? loc) =>
      state = state.copyWith(origin: loc);

  void setDestination(LatLng dest) {
    // Clear existing route whenever destination changes
    state = state.copyWith(
      destination: dest,
      routePoints: [],
      routeSteps: [],
      isNavigating: false,
      routeError: null,
      arrivedAtDestination: false,
    );
    // Déclencher le calcul d'itinéraire IA automatiquement
    Future.microtask(loadItineraries);
  }

  void clearDestination() {
    state = state.copyWith(
      destination: null,
      routePoints: [],
      routeSteps: [],
      isNavigating: false,
      routeError: null,
      arrivedAtDestination: false,
    );
  }

  void swapOriginDest() {
    final oldOrigin = state.effectiveOrigin;
    final oldDest = state.destination;
    if (oldDest == null) return;
    state = state.copyWith(
      origin: oldDest,
      destination: oldOrigin,
      routePoints: [],
      routeSteps: [],
      isNavigating: false,
      routeError: null,
    );
  }

  // ─── Itinéraires (sélection) ──────────────────────────────────────────────

  void selectItinerary(Itinerary itinerary) =>
      state = state.copyWith(selectedItinerary: itinerary);

  void dismissAlert() => state = state.copyWith(showAlert: false);

  // ─── Routage OSRM ─────────────────────────────────────────────────────────

  Future<void> fetchAndSetRoute() async {
    final origin = state.effectiveOrigin;
    final destination = state.destination;
    if (origin == null || destination == null) return;

    state = state.copyWith(
      isFetchingRoute: true,
      routeError: null,
      routePoints: [],
      routeSteps: [],
    );

    final result = await RoutingService.fetchRoute(origin, destination);

    if (result == null) {
      state = state.copyWith(
        isFetchingRoute: false,
        routeError: 'Itinéraire introuvable',
      );
      return;
    }

    // Estimate remaining time as durationMin (will be updated during nav)
    state = state.copyWith(
      isFetchingRoute: false,
      routePoints: result.polyline,
      routeSteps: result.steps,
      remainingDistanceKm: result.distanceKm,
      remainingTimeMin: result.durationMin,
      currentStepIndex: 0,
      routeError: null,
    );
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void startNavigation() {
    if (state.routePoints.isEmpty) return;
    state = state.copyWith(
      isNavigating: true,
      currentStepIndex: 0,
      arrivedAtDestination: false,
    );
  }

  void stopNavigation() {
    state = state.copyWith(
      isNavigating: false,
      currentStepIndex: 0,
      routePoints: [],
      routeSteps: [],
      remainingDistanceKm: null,
      remainingTimeMin: null,
      arrivedAtDestination: false,
    );
  }

  /// Called on every GPS update while navigating.
  void updateNavigationProgress(LatLng userPos) {
    if (!state.isNavigating) return;

    // ── Check arrival at destination ──────────────────────────────────────
    final dest = state.destination;
    if (dest != null) {
      final distToDest = const Distance()
          .as(LengthUnit.Meter, userPos, dest);
      if (distToDest < 40) {
        state = state.copyWith(
          isNavigating: false,
          arrivedAtDestination: true,
          remainingDistanceKm: 0.0,
          remainingTimeMin: 0,
        );
        return;
      }
    }

    // ── Update remaining distance (straight-line to destination) ─────────
    double? distToDestKm;
    if (dest != null) {
      distToDestKm = const Distance()
          .as(LengthUnit.Kilometer, userPos, dest);
    }

    // ── Advance to next step if close enough ─────────────────────────────
    int nextStep = state.currentStepIndex;
    final steps = state.routeSteps;
    if (steps.length > 1 && state.currentStepIndex < steps.length - 1) {
      final nextIdx = state.currentStepIndex + 1;
      final distToNext = const Distance()
          .as(LengthUnit.Meter, userPos, steps[nextIdx].location);
      if (distToNext < 35) {
        nextStep = nextIdx;
      }
    }

    // ── Estimate remaining time based on remaining distance ───────────────
    // Assume ~18 km/h average speed in Port-au-Prince
    final remainingMin = distToDestKm != null
        ? ((distToDestKm / 18) * 60).round()
        : state.remainingTimeMin;

    state = state.copyWith(
      currentStepIndex: nextStep,
      remainingDistanceKm: distToDestKm,
      remainingTimeMin: remainingMin,
    );
  }

  void dismissArrival() {
    state = state.copyWith(arrivedAtDestination: false);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final mapProvider =
    NotifierProvider<MapNotifier, MapState>(MapNotifier.new);

final filteredStationsProvider = Provider<List<Station>>((ref) {
  final mapState = ref.watch(mapProvider);
  final stations = mapState.stations;
  final filter = mapState.filter;
  final q = mapState.searchQuery.toLowerCase().trim();

  var result = stations;
  if (filter != TransportFilter.all) {
    result = result.where((s) {
      return switch (filter) {
        TransportFilter.bus => s.type == StationType.bus,
        TransportFilter.taptap => s.type == StationType.taptap,
        TransportFilter.moto => s.type == StationType.moto,
        TransportFilter.all => true,
      };
    }).toList();
  }
  if (q.isNotEmpty) {
    result = result
        .where((s) => s.name.toLowerCase().contains(q))
        .toList();
  }
  return result;
});
