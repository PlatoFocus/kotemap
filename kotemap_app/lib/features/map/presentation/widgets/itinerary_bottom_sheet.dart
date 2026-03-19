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

          // Title + count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  s.itinerariesTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
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

          // Origin → destination summary
          _OriginDestSummary(s: s),

          // Main card
          _ItineraryCardMain(
            itinerary: itineraries.first,
            isSelected: state.selectedItinerary?.id == itineraries.first.id,
            s: s,
          ),

          // Compact alternatives
          ...itineraries.skip(1).map(
                (it) => _ItineraryCardCompact(
                  itinerary: it,
                  isSelected: state.selectedItinerary?.id == it.id,
                  onSelect: () =>
                      ref.read(mapProvider.notifier).selectItinerary(it),
                  s: s,
                ),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Origin / Destination summary strip ───────────────────────────────────────

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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle)),
              Container(width: 1.5, height: 12, color: AppColors.border),
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

// ─── Main card with navigation button ─────────────────────────────────────────

class _ItineraryCardMain extends ConsumerStatefulWidget {
  final Itinerary itinerary;
  final bool isSelected;
  final S s;

  const _ItineraryCardMain({
    required this.itinerary,
    required this.isSelected,
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

    final state = ref.read(mapProvider);
    if (state.routePoints.isNotEmpty) {
      notifier.startNavigation();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary;
    final s = widget.s;
    final isSelected = widget.isSelected;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ItineraryTag(type: itinerary.type, s: s),
              const Spacer(),
              Text(
                '${itinerary.priceFtg} ${s.routeHTG}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '~${itinerary.durationMin} ${s.routeMin}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StepsRow(steps: itinerary.steps),
          const SizedBox(height: 10),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.tc.primaryLight : context.tc.surface,
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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

class _StepsRow extends StatelessWidget {
  final List<ItineraryStep> steps;
  const _StepsRow({required this.steps});

  Color _dotColor(ItineraryType t) => switch (t) {
        ItineraryType.fastest => AppColors.taptap,
        ItineraryType.safest => AppColors.bus,
        ItineraryType.cheapest => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    for (int i = 0; i < steps.length; i++) {
      children.add(
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: _dotColor(steps[i].transport),
            shape: BoxShape.circle,
          ),
        ),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            steps[i].label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),
      );
      if (i < steps.length - 1) {
        children.add(
          Expanded(child: Container(height: 2, color: AppColors.border)),
        );
      }
    }

    children.add(
      Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );

    return Row(children: children);
  }
}
