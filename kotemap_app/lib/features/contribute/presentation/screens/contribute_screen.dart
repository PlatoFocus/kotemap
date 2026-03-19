import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/providers/tab_provider.dart';
import '../../../map/domain/models/station.dart';
import '../../../map/presentation/widgets/bottom_nav_bar.dart';
import '../../domain/models/contribution.dart';
import '../providers/contribute_provider.dart';

class ContributeScreen extends ConsumerWidget {
  const ContributeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contributeProvider);
    final s = ref.watch(stringsProvider);

    if (state.submitted) {
      return _SuccessView(
        s: s,
        onReset: () => ref.read(contributeProvider.notifier).reset(),
      );
    }

    return Scaffold(
      backgroundColor: context.tc.background,
      body: Column(
        children: [
          _ContributeHeader(
            context: context,
            s: s,
            onBack: () => ref.read(tabProvider.notifier).go(NavTab.map),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel(s.contribTypeTitle, context),
                  const SizedBox(height: 8),
                  _TypeGrid(selectedType: state.selectedType, s: s),
                  const SizedBox(height: 20),
                  _FieldGroup(state: state, s: s),
                  const SizedBox(height: 20),
                  _sectionLabel(s.gpsSection, context),
                  const SizedBox(height: 8),
                  const _MiniMap(),
                  const SizedBox(height: 20),
                  _sectionLabel(s.fareSection, context),
                  const SizedBox(height: 8),
                  _FareRow(fareMin: state.fareMin, fareMax: state.fareMax, s: s),
                  const SizedBox(height: 24),
                  _SubmitSection(isSubmitting: state.isSubmitting, s: s),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, BuildContext context) => Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.tc.textSecondary,
          letterSpacing: 0.5,
        ),
      );
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ContributeHeader extends StatelessWidget {
  final BuildContext context;
  final S s;
  final VoidCallback onBack;
  const _ContributeHeader(
      {required this.context, required this.s, required this.onBack});

  @override
  Widget build(BuildContext _) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Row(
              children: [
                const Icon(Icons.chevron_left, color: Colors.white70, size: 20),
                Text(s.back,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
          const Spacer(),
          Text(
            s.newContrib,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(s.verifiedContrib,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type Grid ────────────────────────────────────────────────────────────────

class _TypeGrid extends ConsumerWidget {
  final ContributionType selectedType;
  final S s;
  const _TypeGrid({required this.selectedType, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = [
      (ContributionType.newStation, s.typeNewStation,
          Icons.location_on_outlined,
          const Color(0xFF3730A3), const Color(0xFFEEF2FF)),
      (ContributionType.fare, s.typeFare, Icons.attach_money,
          const Color(0xFF15803D), const Color(0xFFF0FDF4)),
      (ContributionType.incident, s.typeIncident,
          Icons.warning_amber_outlined,
          const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
      (ContributionType.correction, s.typeCorrection, Icons.edit_outlined,
          const Color(0xFFC2410C), const Color(0xFFFFF7ED)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: types
          .map((t) => _TypeCard(
                label: t.$2,
                icon: t.$3,
                iconColor: t.$4,
                bgColor: t.$5,
                selected: selectedType == t.$1,
                onTap: () =>
                    ref.read(contributeProvider.notifier).setType(t.$1),
              ))
          .toList(),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: context.tc.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF1C1C1E),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Field Group ──────────────────────────────────────────────────────────────

class _FieldGroup extends ConsumerWidget {
  final ContributeState state;
  final S s;
  const _FieldGroup({required this.state, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contributeProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: context.tc.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _FieldRow(
            iconBg: const Color(0xFFEEF2FF),
            iconColor: const Color(0xFF3730A3),
            icon: Icons.favorite_border,
            label: s.fieldStationName,
            value: state.stationName.isEmpty
                ? s.fieldStationPlaceholder
                : state.stationName,
            onTap: () => _showTextInput(context, notifier, state.stationName, s),
            isLast: false,
          ),
          _FieldRow(
            iconBg: const Color(0xFFF0FDF4),
            iconColor: const Color(0xFF15803D),
            icon: Icons.directions_bus_outlined,
            label: s.fieldVehicle,
            value: _vehicleLabel(state.vehicleType, s),
            onTap: () => _showVehiclePicker(context, ref, s),
            isLast: false,
          ),
          _FieldRow(
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            icon: Icons.info_outline,
            label: s.fieldSecurity,
            value: _securityLabel(state.securityLevel, s),
            valueColor: _securityColor(state.securityLevel),
            onTap: () => _showSecurityPicker(context, ref, s),
            isLast: true,
          ),
        ],
      ),
    );
  }

  String _vehicleLabel(StationType t, S s) => switch (t) {
        StationType.bus => s.typeBus,
        StationType.taptap => s.typeTaptap,
        StationType.moto => s.typeMoto,
      };

  String _securityLabel(SecurityLevel l, S s) => switch (l) {
        SecurityLevel.high => s.secSafe,
        SecurityLevel.moderate => s.secModerate,
        SecurityLevel.low => s.secDangerous,
      };

  Color _securityColor(SecurityLevel l) => switch (l) {
        SecurityLevel.high => const Color(0xFF15803D),
        SecurityLevel.moderate => const Color(0xFFD97706),
        SecurityLevel.low => const Color(0xFFDC2626),
      };

  void _showTextInput(BuildContext context, ContributeNotifier notifier,
      String currentName, S s) async {
    final ctrl = TextEditingController(text: currentName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.fieldStationName),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: s.fieldStationHint),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () {
                notifier.setStationName(ctrl.text);
                Navigator.pop(context);
              },
              child: Text(s.ok)),
        ],
      ),
    );
  }

  void _showVehiclePicker(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: StationType.values
            .map((t) => ListTile(
                  title: Text(_vehicleLabel(t, s)),
                  onTap: () {
                    ref.read(contributeProvider.notifier).setVehicleType(t);
                    Navigator.pop(context);
                  },
                  selected: ref.read(contributeProvider).vehicleType == t,
                  selectedColor: AppColors.primary,
                ))
            .toList(),
      ),
    );
  }

  void _showSecurityPicker(BuildContext context, WidgetRef ref, S s) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: SecurityLevel.values
            .map((l) => ListTile(
                  title: Text(_securityLabel(l, s)),
                  textColor: _securityColor(l),
                  onTap: () {
                    ref.read(contributeProvider.notifier).setSecurityLevel(l);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;
  final bool isLast;

  const _FieldRow({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isLast,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 11, color: context.tc.textSecondary)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                valueColor ?? context.tc.textPrimary,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: Color(0xFFC7C7CC)),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 60, color: context.tc.border),
      ],
    );
  }
}

// ─── Mini Map (GPS réel) ──────────────────────────────────────────────────────

class _MiniMap extends StatefulWidget {
  const _MiniMap();

  @override
  State<_MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<_MiniMap> {
  String _coords = '18.5474, -72.3121';

  @override
  void initState() {
    super.initState();
    _loadGps();
  }

  Future<void> _loadGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _coords =
                '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
          });
        }
      }
    } catch (_) {
      // Keep default PAP coordinates on web/desktop fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
                height: 3,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
          Center(
            child: Container(
                width: 3,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
          const Center(
            child: Icon(Icons.location_on, color: AppColors.primary, size: 32),
          ),
          Positioned(
            bottom: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _coords,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fare Row ─────────────────────────────────────────────────────────────────

class _FareRow extends ConsumerWidget {
  final int fareMin;
  final int fareMax;
  final S s;
  const _FareRow(
      {required this.fareMin, required this.fareMax, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
            child: _FareInput(
          label: s.fareMin,
          value: fareMin,
          onChanged: (v) =>
              ref.read(contributeProvider.notifier).setFareMin(v),
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _FareInput(
          label: s.fareMax,
          value: fareMax,
          onChanged: (v) =>
              ref.read(contributeProvider.notifier).setFareMax(v),
        )),
      ],
    );
  }
}

class _FareInput extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _FareInput(
      {required this.label, required this.value, required this.onChanged});

  @override
  State<_FareInput> createState() => _FareInputState();
}

class _FareInputState extends State<_FareInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tc.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label,
              style: TextStyle(
                  fontSize: 11, color: context.tc.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: context.tc.textPrimary),
                  decoration: const InputDecoration.collapsed(hintText: '0'),
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) widget.onChanged(parsed);
                  },
                ),
              ),
              const Text('HTG',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Submit Section ───────────────────────────────────────────────────────────

class _SubmitSection extends ConsumerWidget {
  final bool isSubmitting;
  final S s;
  const _SubmitSection({required this.isSubmitting, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: isSubmitting
                ? null
                : () => ref.read(contributeProvider.notifier).submit(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(s.submitBtn,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.submitNote,
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
        ),
      ],
    );
  }
}

// ─── Success View ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onReset;
  final S s;
  const _SuccessView({required this.onReset, required this.s});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tc.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF15803D), width: 2),
                ),
                child: const Icon(Icons.check,
                    color: Color(0xFF15803D), size: 36),
              ),
              const SizedBox(height: 20),
              Text(s.successTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                s.successBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF6C6C6C)),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: onReset,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(200, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(s.newContribBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
