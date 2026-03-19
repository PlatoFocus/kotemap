import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/models/itinerary.dart';
import '../providers/map_provider.dart';

class ItineraryBottomSheet extends ConsumerWidget {
  const ItineraryBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapProvider);
    final s = ref.watch(stringsProvider);
    final itineraries = state.itineraries;

    if (itineraries.isEmpty) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.18,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.18, 0.32, 0.88],
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.tc.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.zero,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.route, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.itinerariesTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (state.routeError != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.routeNotFound,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    Text(
                      '${itineraries.length} ${s.options}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),

            // ── Origin → destination summary ────────────────────────────────
            _OriginDestSummary(s: s),

            // ── Main card (selected itinerary + steps) ──────────────────────
            _ItineraryCardMain(
              itinerary: itineraries.first,
              isSelected: state.selectedItinerary?.id == itineraries.first.id,
              aiStepIndex: state.aiStepIndex,
              s: s,
            ),

            // ── Compact alternatives ─────────────────────────────────────────
            ...itineraries.skip(1).map(
                  (it) => _ItineraryCardCompact(
                    itinerary: it,
                    isSelected: state.selectedItinerary?.id == it.id,
                    onSelect: () =>
                        ref.read(mapProvider.notifier).selectItinerary(it),
                    s: s,
                  ),
                ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Origin / Destination summary ────────────────────────────────────────────

class _OriginDestSummary extends ConsumerWidget {
  final S s;
  const _OriginDestSummary({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapProvider);
    final origin = state.effectiveOrigin;
    final dest = state.destination;
    if (origin == null && dest == null) return const SizedBox.shrink();

    String coordLabel(dynamic ll) =>
        '${ll.latitude.toStringAsFixed(3)}, ${ll.longitude.toStringAsFixed(3)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle)),
              Container(
                  width: 1.5, height: 14, color: AppColors.border),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(2))),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  origin != null ? coordLabel(origin) : s.myPosition,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  state.destinationName ??
                      (dest != null ? coordLabel(dest) : '—'),
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main card with steps ─────────────────────────────────────────────────────

class _ItineraryCardMain extends ConsumerStatefulWidget {
  final Itinerary itinerary;
  final bool isSelected;
  final int aiStepIndex;
  final S s;

  const _ItineraryCardMain({
    required this.itinerary,
    required this.isSelected,
    required this.aiStepIndex,
    required this.s,
  });

  @override
  ConsumerState<_ItineraryCardMain> createState() =>
      _ItineraryCardMainState();
}

class _ItineraryCardMainState extends ConsumerState<_ItineraryCardMain> {
  bool _loading = false;

  Future<void> _startNavigation() async {
    if (_loading) return;
    setState(() => _loading = true);
    final notifier = ref.read(mapProvider.notifier);
    notifier.selectItinerary(widget.itinerary);
    await notifier.fetchAndSetRoute();
    if (!mounted) return;
    if (ref.read(mapProvider).routePoints.isNotEmpty) {
      notifier.startNavigation();
    }
    setState(() => _loading = false);
  }

  IconData _stepIcon(StepTransport? mode) => switch (mode) {
        StepTransport.bus => Icons.directions_bus,
        StepTransport.taptap => Icons.airport_shuttle,
        StepTransport.moto => Icons.two_wheeler,
        StepTransport.walk => Icons.directions_walk,
        null => Icons.airport_shuttle,
      };

  Color _stepColor(StepTransport? mode) => switch (mode) {
        StepTransport.bus => AppColors.bus,
        StepTransport.taptap => AppColors.taptap,
        StepTransport.moto => const Color(0xFF7C3AED),
        StepTransport.walk => const Color(0xFF059669),
        null => AppColors.taptap,
      };

  @override
  Widget build(BuildContext context) {
    final it = widget.itinerary;
    final s = widget.s;
    final steps = it.steps;
    final aiStep = widget.aiStepIndex;
    final isSelected = widget.isSelected;
    final allDone = aiStep >= steps.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                _ItineraryTag(type: it.type, s: s),
                const Spacer(),
                Text(
                  '${it.priceFtg} ${s.routeHTG}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '~${it.durationMin} ${s.routeMin}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ── Safety note ────────────────────────────────────────────────────
          if (it.safetyNote != null && it.safetyNote!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 13, color: Color(0xFF15803D)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      it.safetyNote!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),

          // ── Warnings ───────────────────────────────────────────────────────
          if (it.warnings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      it.warnings.first,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFD97706)),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // ── Steps list (numbered, with progress) ──────────────────────────
          if (steps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Text(
                'ÉTAPES'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 6),
            ...steps.asMap().entries.map((e) {
              final i = e.key;
              final step = e.value;
              final isDone = i < aiStep;
              final isCurrent = i == aiStep && !allDone;
              final stepMode = step.mode ?? ItineraryStep.detectMode(step.label);

              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step number / status column
                    SizedBox(
                      width: 28,
                      child: Column(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF15803D)
                                  : isCurrent
                                      ? AppColors.primary
                                      : const Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: isDone
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : isCurrent
                                    ? Icon(_stepIcon(stepMode),
                                        size: 12, color: Colors.white)
                                    : Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isCurrent
                                                ? Colors.white
                                                : AppColors.textTertiary,
                                          ),
                                        ),
                                      ),
                          ),
                          // Connector line
                          if (i < steps.length - 1)
                            Container(
                              width: 2,
                              height: 24,
                              color: isDone
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFE5E7EB),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Step text
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Transport badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _stepColor(stepMode)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_stepIcon(stepMode),
                                          size: 10,
                                          color: _stepColor(stepMode)),
                                      const SizedBox(width: 3),
                                      Text(
                                        _modeLabel(stepMode),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: _stepColor(stepMode),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isDone
                                    ? AppColors.textTertiary
                                    : isCurrent
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // ── Action buttons ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              children: [
                // "Étape suivante" during planning (not navigating)
                if (!allDone)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(mapProvider.notifier).advanceAiStep(),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(
                        aiStep == 0
                            ? 'Commencer l\'itinéraire'
                            : 'Étape ${aiStep + 1} terminée ✓',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side:
                            const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (!allDone) const SizedBox(height: 8),
                // Navigate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _startNavigation,
                    icon: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.navigation, size: 15),
                    label: Text(
                      _loading ? s.fetchingRoute : s.startNavigation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _modeLabel(StepTransport mode) => switch (mode) {
        StepTransport.bus => 'Bus',
        StepTransport.taptap => 'Tap-tap',
        StepTransport.moto => 'Moto',
        StepTransport.walk => 'À pied',
      };
}

// ─── Compact alternative card ─────────────────────────────────────────────────

class _ItineraryCardCompact extends StatelessWidget {
  final Itinerary itinerary;
  final bool isSelected;
  final VoidCallback onSelect;
  final S s;

  const _ItineraryCardCompact({
    required this.itinerary,
    required this.isSelected,
    required this.onSelect,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.tc.primaryLight
              : context.tc.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _ItineraryTag(type: itinerary.type, s: s),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${itinerary.steps.map((st) => st.label).join(' · ')} · ${itinerary.durationMin} ${s.routeMin}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${itinerary.priceFtg} ${s.routeHTG}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ItineraryTag extends StatelessWidget {
  final ItineraryType type;
  final S s;
  const _ItineraryTag({required this.type, required this.s});

  Color get _bg => switch (type) {
        ItineraryType.fastest => AppColors.tagFastBg,
        ItineraryType.safest => AppColors.tagSafeBg,
        ItineraryType.cheapest => AppColors.tagCheapBg,
      };

  Color get _text => switch (type) {
        ItineraryType.fastest => AppColors.tagFastText,
        ItineraryType.safest => AppColors.tagSafeText,
        ItineraryType.cheapest => AppColors.tagCheapText,
      };

  String _label(S s) => switch (type) {
        ItineraryType.fastest => s.tagFastest,
        ItineraryType.safest => s.tagSafest,
        ItineraryType.cheapest => s.tagCheapest,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(s),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _text,
        ),
      ),
    );
  }
}
