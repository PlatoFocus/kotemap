import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../domain/models/route_result.dart';
import '../providers/map_provider.dart';

class NavigationOverlay extends ConsumerWidget {
  const NavigationOverlay({super.key});

  // ─── Maneuver → icon ────────────────────────────────────────────────────────

  IconData _icon(ManeuverType type) => switch (type) {
        ManeuverType.depart => Icons.navigation,
        ManeuverType.arrive => Icons.flag,
        ManeuverType.turnLeft => Icons.turn_left,
        ManeuverType.turnRight => Icons.turn_right,
        ManeuverType.sharpLeft => Icons.turn_sharp_left,
        ManeuverType.sharpRight => Icons.turn_sharp_right,
        ManeuverType.slightLeft => Icons.turn_slight_left,
        ManeuverType.slightRight => Icons.turn_slight_right,
        ManeuverType.uturn => Icons.u_turn_left,
        ManeuverType.roundabout => Icons.roundabout_left,
        ManeuverType.straight || ManeuverType.unknown => Icons.straight,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapProvider);
    final s = ref.watch(stringsProvider);

    final steps = state.routeSteps;
    final stepIdx = state.currentStepIndex.clamp(0, steps.isEmpty ? 0 : steps.length - 1);
    final currentStep = steps.isEmpty ? null : steps[stepIdx];

    // Next step preview (shown below the current instruction)
    final nextStep =
        steps.isNotEmpty && stepIdx + 1 < steps.length
            ? steps[stepIdx + 1]
            : null;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Current step ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Maneuver icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _icon(currentStep?.maneuver ?? ManeuverType.straight),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Instruction + distance to next turn
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentStep != null &&
                              currentStep.distanceM > 0)
                            Text(
                              s.formatDistanceM(currentStep.distanceM),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            currentStep?.instruction ??
                                s.continueNavigation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Stop button
                    GestureDetector(
                      onTap: () =>
                          ref.read(mapProvider.notifier).stopNavigation(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar + remaining info ──────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.schedule,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      state.remainingTimeMin != null
                          ? '${state.remainingTimeMin} min'
                          : '—',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.straighten,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      state.remainingDistanceKm != null
                          ? state.remainingDistanceKm! >= 1
                              ? '${state.remainingDistanceKm!.toStringAsFixed(1)} km'
                              : '${(state.remainingDistanceKm! * 1000).round()} m'
                          : '—',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    // Next turn preview
                    if (nextStep != null) ...[
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 10),
                      const SizedBox(width: 4),
                      Icon(
                        _icon(nextStep.maneuver),
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.formatDistanceM(nextStep.distanceM),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                    const Spacer(),
                    // Stop label
                    GestureDetector(
                      onTap: () =>
                          ref.read(mapProvider.notifier).stopNavigation(),
                      child: Text(
                        s.stopNavigation,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Arrival card (shown after navigation ends) ────────────────────────────────

class ArrivalCard extends ConsumerWidget {
  const ArrivalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF15803D),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.flag, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.arrived,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    ref.read(mapProvider.notifier).dismissArrival(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
