import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../map/domain/models/station.dart';
import '../../domain/models/contribution.dart';
import '../../../../core/services/api_service.dart';

class ContributeState {
  final ContributionType selectedType;
  // Nouvelle station — départ + arrivée
  final String departureStation; // station de départ
  final String arrivalStation;   // station d'arrivée / destination
  final String stationName;      // nom complet de la ligne (auto-généré ou saisi)
  final StationType vehicleType;
  final SecurityLevel securityLevel;
  final int fareMin;
  final int fareMax;
  // Incident
  final String incidentTitle;
  final String incidentDescription;
  final String incidentSeverity; // "low" | "medium" | "high"
  // Correction / Tarif
  final String correctionTarget; // nom de la station concernée
  final String correctionDescription;
  // Commun
  final bool isSubmitting;
  final bool submitted;
  final double? latitude;
  final double? longitude;
  final String? error;

  const ContributeState({
    this.selectedType = ContributionType.newStation,
    this.departureStation = '',
    this.arrivalStation = '',
    this.stationName = '',
    this.vehicleType = StationType.taptap,
    this.securityLevel = SecurityLevel.moderate,
    this.fareMin = 35,
    this.fareMax = 50,
    this.incidentTitle = '',
    this.incidentDescription = '',
    this.incidentSeverity = 'medium',
    this.correctionTarget = '',
    this.correctionDescription = '',
    this.isSubmitting = false,
    this.submitted = false,
    this.latitude,
    this.longitude,
    this.error,
  });

  ContributeState copyWith({
    ContributionType? selectedType,
    String? departureStation,
    String? arrivalStation,
    String? stationName,
    StationType? vehicleType,
    SecurityLevel? securityLevel,
    int? fareMin,
    int? fareMax,
    String? incidentTitle,
    String? incidentDescription,
    String? incidentSeverity,
    String? correctionTarget,
    String? correctionDescription,
    bool? isSubmitting,
    bool? submitted,
    double? latitude,
    double? longitude,
    String? error,
  }) =>
      ContributeState(
        selectedType: selectedType ?? this.selectedType,
        departureStation: departureStation ?? this.departureStation,
        arrivalStation: arrivalStation ?? this.arrivalStation,
        stationName: stationName ?? this.stationName,
        vehicleType: vehicleType ?? this.vehicleType,
        securityLevel: securityLevel ?? this.securityLevel,
        fareMin: fareMin ?? this.fareMin,
        fareMax: fareMax ?? this.fareMax,
        incidentTitle: incidentTitle ?? this.incidentTitle,
        incidentDescription: incidentDescription ?? this.incidentDescription,
        incidentSeverity: incidentSeverity ?? this.incidentSeverity,
        correctionTarget: correctionTarget ?? this.correctionTarget,
        correctionDescription:
            correctionDescription ?? this.correctionDescription,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        submitted: submitted ?? this.submitted,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        error: error ?? this.error,
      );
}

class ContributeNotifier extends Notifier<ContributeState> {
  @override
  ContributeState build() => const ContributeState();

  void setType(ContributionType type) =>
      state = state.copyWith(selectedType: type);

  void setDepartureStation(String v) {
    state = state.copyWith(departureStation: v);
    _autoUpdateStationName();
  }

  void setArrivalStation(String v) {
    state = state.copyWith(arrivalStation: v);
    _autoUpdateStationName();
  }

  void _autoUpdateStationName() {
    final dep = state.departureStation;
    final arr = state.arrivalStation;
    if (dep.isNotEmpty && arr.isNotEmpty) {
      state = state.copyWith(stationName: '$dep → $arr');
    }
  }

  void setStationName(String name) =>
      state = state.copyWith(stationName: name);

  void setVehicleType(StationType type) =>
      state = state.copyWith(vehicleType: type);

  void setSecurityLevel(SecurityLevel level) =>
      state = state.copyWith(securityLevel: level);

  void setFareMin(int v) => state = state.copyWith(fareMin: v);
  void setFareMax(int v) => state = state.copyWith(fareMax: v);
  void setIncidentTitle(String v) => state = state.copyWith(incidentTitle: v);
  void setIncidentDescription(String v) =>
      state = state.copyWith(incidentDescription: v);
  void setIncidentSeverity(String v) =>
      state = state.copyWith(incidentSeverity: v);
  void setCorrectionTarget(String v) =>
      state = state.copyWith(correctionTarget: v);
  void setCorrectionDescription(String v) =>
      state = state.copyWith(correctionDescription: v);

  void setLocation(double lat, double lng) =>
      state = state.copyWith(latitude: lat, longitude: lng);

  Future<void> submit() async {
    final lat = state.latitude ?? 18.5474;
    final lng = state.longitude ?? -72.3380;

    switch (state.selectedType) {
      case ContributionType.newStation:
        if (state.departureStation.isEmpty || state.arrivalStation.isEmpty) {
          state = state.copyWith(error: 'Indiquez la station de départ et d\'arrivée');
          return;
        }
        await _submitNewStation(lat, lng);

      case ContributionType.incident:
        if (state.incidentTitle.isEmpty) {
          state = state.copyWith(error: 'Le titre de l\'incident est requis');
          return;
        }
        await _submitIncident(lat, lng);

      case ContributionType.fare:
        if (state.correctionTarget.isEmpty) {
          state = state.copyWith(error: 'Indiquez la station concernée');
          return;
        }
        await _submitFare(lat, lng);

      case ContributionType.correction:
        if (state.correctionTarget.isEmpty) {
          state = state.copyWith(error: 'Indiquez la station concernée');
          return;
        }
        await _submitCorrection(lat, lng);
    }
  }

  Future<void> _submitNewStation(double lat, double lng) async {
    state = state.copyWith(isSubmitting: true, error: null);
    final transportType = switch (state.vehicleType) {
      StationType.bus => 'bus',
      StationType.taptap => 'taptap',
      StationType.moto => 'taptap',
    };
    final name = state.stationName.isNotEmpty
        ? state.stationName
        : '${state.departureStation} → ${state.arrivalStation}';
    try {
      await ApiService.createContribution(
        stationName: name,
        transportType: transportType,
        lat: lat,
        lng: lng,
        description:
            'Départ: ${state.departureStation} | Arrivée: ${state.arrivalStation} | Sécurité: ${state.securityLevel.name}',
        routesJson: '[\"${state.departureStation}\", \"${state.arrivalStation}\"]',
      );
    } catch (_) {}
    state = state.copyWith(isSubmitting: false, submitted: true);
  }

  Future<void> _submitIncident(double lat, double lng) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await ApiService.createIncident(
        title: state.incidentTitle,
        description: state.incidentDescription.isEmpty
            ? state.incidentTitle
            : state.incidentDescription,
        severity: state.incidentSeverity,
        lat: lat,
        lng: lng,
      );
    } catch (_) {}
    state = state.copyWith(isSubmitting: false, submitted: true);
  }

  Future<void> _submitFare(double lat, double lng) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await ApiService.createContribution(
        stationName: state.correctionTarget,
        transportType: 'taptap',
        lat: lat,
        lng: lng,
        description: 'Correction tarif: ${state.fareMin}–${state.fareMax} HTG',
        routesJson: null,
      );
    } catch (_) {}
    state = state.copyWith(isSubmitting: false, submitted: true);
  }

  Future<void> _submitCorrection(double lat, double lng) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await ApiService.createContribution(
        stationName: state.correctionTarget,
        transportType: 'taptap',
        lat: lat,
        lng: lng,
        description: state.correctionDescription,
        routesJson: null,
      );
    } catch (_) {}
    state = state.copyWith(isSubmitting: false, submitted: true);
  }

  void reset() => state = const ContributeState();
}

final contributeProvider =
    NotifierProvider<ContributeNotifier, ContributeState>(
        ContributeNotifier.new);
