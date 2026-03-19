import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/tab_provider.dart';
import 'bottom_nav_bar.dart' show NavTab;
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/models/station.dart';
import '../providers/map_provider.dart';

/// Panneau affiché quand l'utilisateur a choisi une destination prédéfinie.
/// Montre les stations qui desservent ce lieu + la plus proche de l'utilisateur.
class DestinationStationsSheet extends ConsumerWidget {
  const DestinationStationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapProvider);
    final place = state.selectedPlace;
    if (place == null) return const SizedBox.shrink();

    final userLoc = state.effectiveOrigin;
    final nearest = state.nearestStation;
    final serving = state.servingStations;

    // Stations desservantes (hors la plus proche pour éviter le doublon)
    final othersServing =
        serving.where((s) => s.id != nearest?.id).take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.tc.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header — destination + fermer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stations pour aller à',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      ref.read(mapProvider.notifier).clearDestination(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Station la plus proche ───────────────────────────────────────
          if (nearest != null) ...[
            _SectionLabel(
              label: 'La plus proche de vous',
              icon: Icons.near_me,
              color: AppColors.primary,
            ),
            _StationCard(
              station: nearest,
              userLoc: userLoc,
              isHighlighted: true,
              isDirect: serving.any((s) => s.id == nearest.id),
              onNavigate: () =>
                  ref.read(mapProvider.notifier).navigateToStation(nearest),
            ),
          ],

          // ── Stations qui desservent directement ─────────────────────────
          if (serving.isNotEmpty) ...[
            _SectionLabel(
              label: 'Desservent ${place.name}',
              icon: Icons.directions_bus_rounded,
            ),
            ...othersServing.map(
              (s) => _StationCard(
                station: s,
                userLoc: userLoc,
                isHighlighted: false,
                isDirect: true,
                onNavigate: () =>
                    ref.read(mapProvider.notifier).navigateToStation(s),
              ),
            ),
          ],

          // ── État vide ───────────────────────────────────────────────────
          if (nearest == null && serving.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                children: [
                  const Icon(Icons.search_off,
                      size: 40, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune station trouvée pour ${place.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => ref.read(tabProvider.notifier).go(NavTab.contribute),
                    icon: const Icon(Icons.add_location_alt, size: 16),
                    label: const Text('Contribuer une station',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _SectionLabel(
      {required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color ?? AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Station card ─────────────────────────────────────────────────────────────

class _StationCard extends StatelessWidget {
  final Station station;
  final LatLng? userLoc;
  final bool isHighlighted;
  final bool isDirect;
  final VoidCallback onNavigate;

  const _StationCard({
    required this.station,
    required this.userLoc,
    required this.isHighlighted,
    required this.isDirect,
    required this.onNavigate,
  });

  Color get _typeColor => switch (station.type) {
        StationType.bus => AppColors.bus,
        StationType.taptap => AppColors.taptap,
        StationType.moto => AppColors.moto,
      };

  String _distLabel() {
    if (userLoc == null) return '';
    final lat1 = userLoc!.latitude * pi / 180;
    final lat2 = station.position.latitude * pi / 180;
    final dLat = (station.position.latitude - userLoc!.latitude) * pi / 180;
    final dLng =
        (station.position.longitude - userLoc!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final d = 6371000 * 2 * atan2(sqrt(a), sqrt(1 - a));
    return d < 1000 ? '${d.round()} m' : '${(d / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distLabel();
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFEEF2FF)
            : context.tc.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted ? AppColors.primary : AppColors.border,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Type badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              station.typeInitial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      station.typeLabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (dist.isNotEmpty) ...[
                      const Text(' · ',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary)),
                      Text(dist,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                    if (isDirect) ...[
                      const Text(' · ',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary)),
                      const Text(
                        'Direct',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (station.fareMin != null)
                  Text(
                    '${station.fareMin}–${station.fareMax} HTG',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Navigate button
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onNavigate,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isHighlighted ? AppColors.primary : AppColors.background,
              foregroundColor:
                  isHighlighted ? Colors.white : AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Aller',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
