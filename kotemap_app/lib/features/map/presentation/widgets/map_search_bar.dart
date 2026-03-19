import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/models/station.dart';
import '../providers/map_provider.dart';

// ─── MapSearchBar ─────────────────────────────────────────────────────────────

class MapSearchBar extends ConsumerWidget {
  final VoidCallback? onGpsTap;

  const MapSearchBar({super.key, this.onGpsTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapProvider);
    final s = ref.watch(stringsProvider);
    final hasDestination = state.destination != null;

    return Container(
      color: context.tc.surface,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: [
          if (hasDestination)
            _OriginDestinationRows(onGpsTap: onGpsTap, s: s)
          else
            _DestinationSearchRow(onGpsTap: onGpsTap, s: s),
          const SizedBox(height: 4),
          _FilterChipsRow(),
        ],
      ),
    );
  }
}

// ─── Single destination row (default state) ───────────────────────────────────

class _DestinationSearchRow extends ConsumerWidget {
  final VoidCallback? onGpsTap;
  final S s;
  const _DestinationSearchRow({required this.onGpsTap, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openSearch(context, ref, forOrigin: false),
      child: Container(
        decoration: BoxDecoration(
          color: context.tc.inputFill,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.search,
                color: AppColors.textTertiary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.searchHint,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textTertiary),
              ),
            ),
            GestureDetector(
              onTap: onGpsTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.my_location,
                    color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext ctx, WidgetRef ref,
      {required bool forOrigin}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SearchSheet(parentRef: ref, s: s, forOrigin: forOrigin),
    );
  }
}

// ─── Origin + Destination two-row planning bar ────────────────────────────────

class _OriginDestinationRows extends ConsumerWidget {
  final VoidCallback? onGpsTap;
  final S s;
  const _OriginDestinationRows({required this.onGpsTap, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapProvider);
    final origin = state.origin;
    final dest = state.destination;

    final originLabel = origin == null
        ? s.myPosition
        : '${origin.latitude.toStringAsFixed(4)}, ${origin.longitude.toStringAsFixed(4)}';
    final destLabel = dest != null
        ? '${dest.latitude.toStringAsFixed(4)}, ${dest.longitude.toStringAsFixed(4)}'
        : s.searchHint;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ── Origin row ────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => _openSearch(context, ref, forOrigin: true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      originLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: origin == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontWeight: origin == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // GPS shortcut: reset origin to live GPS
                  GestureDetector(
                    onTap: () {
                      ref.read(mapProvider.notifier).setOrigin(null);
                      onGpsTap?.call();
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.my_location,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Separator with swap button ────────────────────────────────────
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 21),
                child: SizedBox(
                  width: 0.5,
                  height: 16,
                  child: VerticalDivider(
                      color: AppColors.border, thickness: 1.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _swapOriginDest(ref, state),
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.swap_vert,
                      size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),

          // ── Destination row ───────────────────────────────────────────────
          GestureDetector(
            onTap: () => _openSearch(context, ref, forOrigin: false),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      destLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Clear destination button
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(mapProvider.notifier)
                          .clearDestination();
                    },
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSearch(BuildContext ctx, WidgetRef ref,
      {required bool forOrigin}) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SearchSheet(parentRef: ref, s: s, forOrigin: forOrigin),
    );
  }

  void _swapOriginDest(WidgetRef ref, MapState state) {
    ref.read(mapProvider.notifier).swapOriginDest();
  }
}

// ─── Search Sheet ─────────────────────────────────────────────────────────────

class _SearchSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  final S s;
  final bool forOrigin;
  const _SearchSheet({
    required this.parentRef,
    required this.s,
    required this.forOrigin,
  });

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      ref.read(mapProvider.notifier).setSearchQuery(_ctrl.text);
    });
  }

  @override
  void dispose() {
    ref.read(mapProvider.notifier).setSearchQuery('');
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(filteredStationsProvider);
    final s = widget.s;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.tc.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.forOrigin
                      ? s.searchOriginHint
                      : s.searchHint,
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textTertiary, size: 20),
                  filled: true,
                  fillColor: context.tc.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            // "Ma position GPS" tile (only for origin search)
            if (widget.forOrigin)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location,
                      color: Colors.white, size: 18),
                ),
                title: Text(s.myPosition,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(s.fromLabel,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF8E8E93))),
                onTap: () {
                  ref.read(mapProvider.notifier).setOrigin(null);
                  Navigator.of(context).pop();
                },
              ),
            if (widget.forOrigin)
              const Divider(height: 1, indent: 16, endIndent: 16),
            Expanded(
              child: stations.isEmpty
                  ? Center(
                      child: Text(s.searchHint,
                          style: const TextStyle(
                              color: Color(0xFF8E8E93))))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: stations.length,
                      itemBuilder: (_, i) => _StationResultTile(
                        station: stations[i],
                        forOrigin: widget.forOrigin,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationResultTile extends ConsumerWidget {
  final Station station;
  final bool forOrigin;
  const _StationResultTile(
      {required this.station, required this.forOrigin});

  Color get _typeColor => switch (station.type) {
        StationType.bus => AppColors.primary,
        StationType.taptap => AppColors.taptap,
        StationType.moto => const Color(0xFF7C3AED),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _typeColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            station.typeInitial,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
        ),
      ),
      title: Text(station.name,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(station.typeLabel,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF8E8E93))),
      trailing: station.fareMin != null
          ? Text(
              '${station.fareMin}–${station.fareMax} HTG',
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF8E8E93)),
            )
          : null,
      onTap: () {
        final notifier = ref.read(mapProvider.notifier);
        if (forOrigin) {
          notifier.setOrigin(station.position);
        } else {
          notifier.setDestination(station.position);
        }
        Navigator.of(context).pop();
      },
    );
  }
}

// ─── Filter Chips ─────────────────────────────────────────────────────────────

class _FilterChipsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapProvider).filter;
    final s = ref.watch(stringsProvider);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: s.filterAll,
            isActive: filter == TransportFilter.all,
            onTap: () => ref
                .read(mapProvider.notifier)
                .setFilter(TransportFilter.all),
          ),
          _FilterChip(
            label: s.legendBus,
            isActive: filter == TransportFilter.bus,
            onTap: () => ref
                .read(mapProvider.notifier)
                .setFilter(TransportFilter.bus),
          ),
          _FilterChip(
            label: 'Taptap',
            isActive: filter == TransportFilter.taptap,
            onTap: () => ref
                .read(mapProvider.notifier)
                .setFilter(TransportFilter.taptap),
          ),
          _FilterChip(
            label: 'Moto',
            isActive: filter == TransportFilter.moto,
            onTap: () => ref
                .read(mapProvider.notifier)
                .setFilter(TransportFilter.moto),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : context.tc.inputFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : context.tc.textPrimary,
          ),
        ),
      ),
    );
  }
}
