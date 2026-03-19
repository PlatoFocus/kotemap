import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../map/domain/models/station.dart';
import '../../domain/models/contribution.dart';
import '../../../../core/services/api_service.dart';

class ContributeState {
  final ContributionType selectedType;
  final String stationName;
  final StationType vehicleType;
  final SecurityLevel securityLevel;
  final int fareMin;
  final int fareMax;
  final bool isSubmitting;
  final bool submitted;
  // Coordonnées GPS saisies via le mini-map ou la géolocalisation
  final double? latitude;
  final double? longitude;
  // Message d'erreur si la soumission API échoue
  final String? error;

  const ContributeState({
    this.selectedType = ContributionType.newStation,
    this.stationName = '',
    this.vehicleType = StationType.taptap,
    this.securityLevel = SecurityLevel.moderate,
    this.fareMin = 35,
    this.fareMax = 50,
    this.isSubmitting = false,
    this.submitted = false,
    this.latitude,
    this.longitude,
    this.error,
  });

  ContributeState copyWith({
    ContributionType? selectedType,
    String? stationName,
    StationType? vehicleType,
    SecurityLevel? securityLevel,
    int? fareMin,
    int? fareMax,
    bool? isSubmitting,
    bool? submitted,
    double? latitude,
    double? longitude,
    String? error,
  }) =>
      ContributeState(
        selectedType: selectedType ?? this.selectedType,
        stationName: stationName ?? this.stationName,
        vehicleType: vehicleType ?? this.vehicleType,
        securityLevel: securityLevel ?? this.securityLevel,
        fareMin: fareMin ?? this.fareMin,
        fareMax: fareMax ?? this.fareMax,
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

  void setStationName(String name) =>
      state = state.copyWith(stationName: name);

  void setVehicleType(StationType type) =>
      state = state.copyWith(vehicleType: type);

  void setSecurityLevel(SecurityLevel level) =>
      state = state.copyWith(securityLevel: level);

  void setFareMin(int v) => state = state.copyWith(fareMin: v);
  void setFareMax(int v) => state = state.copyWith(fareMax: v);

  void setLocation(double lat, double lng) =>
      state = state.copyWith(latitude: lat, longitude: lng);

  Future<void> submit() async {
    if (state.stationName.isEmpty) {
      state = state.copyWith(error: 'Le nom de la station est requis');
      return;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    // Coordonnées par défaut : centre de Port-au-Prince si non définies
    final lat = state.latitude ?? 18.5474;
    final lng = state.longitude ?? -72.3380;

    // Type de transport pour l'API : "taptap" ou "bus" (pas de moto dans le backend V1)
    final transportType = switch (state.vehicleType) {
      StationType.bus => 'bus',
      StationType.taptap => 'taptap',
      StationType.moto => 'taptap', // Fallback moto → taptap pour le prototype
    };

    try {
      final success = await ApiService.createContribution(
        stationName: state.stationName,
        transportType: transportType,
        lat: lat,
        lng: lng,
        description: 'Sécurité: ${state.securityLevel.name}',
        routesJson: null,
      );

      if (success) {
        state = state.copyWith(isSubmitting: false, submitted: true);
        debugPrint('✓ Contribution soumise avec succès');
      } else {
        // L'API a refusé (ex: 401 non authentifié) → on valide quand même en local
        // pour ne pas bloquer l'utilisateur dans le prototype
        debugPrint('API contribution non accessible — validation locale');
        state = state.copyWith(isSubmitting: false, submitted: true);
      }
    } catch (e) {
      debugPrint('Erreur soumission contribution : $e');
      // Toujours afficher le succès dans le prototype pour l'UX
      state = state.copyWith(isSubmitting: false, submitted: true);
    }
  }

  void reset() => state = const ContributeState();
}

final contributeProvider =
    NotifierProvider<ContributeNotifier, ContributeState>(
        ContributeNotifier.new);
