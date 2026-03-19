import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/providers/tab_provider.dart';
import '../../../map/domain/models/place_location.dart';
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
                  _TypeGrid(s: s),
                  const SizedBox(height: 20),
                  _FieldGroup(state: state, s: s),
                  const SizedBox(height: 20),
                  _sectionLabel(s.gpsSection, context),
                  const SizedBox(height: 8),
                  const _MiniMap(),
                  if (state.selectedType == ContributionType.newStation ||
                      state.selectedType == ContributionType.fare) ...[
                    const SizedBox(height: 20),
                    _sectionLabel(s.fareSection, context),
                    const SizedBox(height: 8),
                    _FareRow(fareMin: state.fareMin, fareMax: state.fareMax, s: s),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(state.error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
                      ]),
                    ),
                  ],
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
  final S s;
  const _TypeGrid({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(contributeProvider).selectedType;
    final types = [
      (ContributionType.newStation, s.typeNewStation, Icons.location_on_outlined),
      (ContributionType.fare, s.typeFare, Icons.attach_money),
      (ContributionType.incident, s.typeIncident, Icons.warning_amber_outlined),
      (ContributionType.correction, s.typeCorrection, Icons.edit_outlined),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final isSelected = current == t.$1;
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 52) / 2,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => ref.read(contributeProvider.notifier).setType(t.$1),
            icon: Icon(t.$3, size: 16),
            label: Text(t.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? AppColors.primary : Colors.white,
              foregroundColor: isSelected ? Colors.white : const Color(0xFF1C1C1E),
              elevation: isSelected ? 2 : 1,
              side: BorderSide(
                color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Field Group (dynamique selon le type) ────────────────────────────────────

class _FieldGroup extends ConsumerWidget {
  final ContributeState state;
  final S s;
  const _FieldGroup({required this.state, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state.selectedType) {
      ContributionType.newStation => _NewStationFields(state: state, s: s),
      ContributionType.incident => _IncidentFields(state: state, s: s),
      ContributionType.fare => _FareCorrectionFields(state: state, s: s),
      ContributionType.correction => _CorrectionFields(state: state, s: s),
    };
  }
}

// ── Nouvelle station ──────────────────────────────────────────────────────────

class _NewStationFields extends ConsumerWidget {
  final ContributeState state;
  final S s;
  const _NewStationFields({required this.state, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contributeProvider.notifier);
    return _Card(children: [
      // Station de départ
      _FieldRow(
        iconBg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF3730A3),
        icon: Icons.trip_origin,
        label: 'Station de départ',
        value: state.departureStation.isEmpty ? 'Ex: Champ de Mars' : state.departureStation,
        onTap: () => _showStationPicker(
          context,
          title: 'Station de départ',
          hint: 'Ex: Champ de Mars, Delmas 32...',
          initial: state.departureStation,
          onSave: notifier.setDepartureStation,
          s: s,
        ),
        isLast: false,
      ),
      // Flèche entre départ et arrivée
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Column(
              children: [
                Container(width: 1.5, height: 8, color: const Color(0xFFD1D5DB)),
                const Icon(Icons.arrow_downward, size: 14, color: Color(0xFF9CA3AF)),
                Container(width: 1.5, height: 8, color: const Color(0xFFD1D5DB)),
              ],
            ),
            const SizedBox(width: 26),
            Expanded(
              child: Text(
                state.stationName.isNotEmpty
                    ? state.stationName
                    : 'Ligne : ${state.departureStation.isEmpty ? "?" : state.departureStation} → ${state.arrivalStation.isEmpty ? "?" : state.arrivalStation}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
      // Station d'arrivée
      _FieldRow(
        iconBg: const Color(0xFFF0FDF4),
        iconColor: const Color(0xFF15803D),
        icon: Icons.location_on,
        label: 'Station d\'arrivée / Destination',
        value: state.arrivalStation.isEmpty ? 'Ex: Pétion-Ville' : state.arrivalStation,
        onTap: () => _showStationPicker(
          context,
          title: 'Station d\'arrivée',
          hint: 'Ex: Pétion-Ville, Aéroport...',
          initial: state.arrivalStation,
          onSave: notifier.setArrivalStation,
          s: s,
        ),
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
    ]);
  }
}

// ── Incident ──────────────────────────────────────────────────────────────────

class _IncidentFields extends ConsumerWidget {
  final ContributeState state;
  final S s;
  const _IncidentFields({required this.state, required this.s});

  static const _severities = [
    ('high', 'Grave / Danger immédiat', Color(0xFFDC2626)),
    ('medium', 'Modéré', Color(0xFFD97706)),
    ('low', 'Mineur / Informatif', Color(0xFF15803D)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contributeProvider.notifier);
    final sevLabel = _severities
        .firstWhere((e) => e.$1 == state.incidentSeverity,
            orElse: () => _severities[1])
        .$2;
    final sevColor = _severities
        .firstWhere((e) => e.$1 == state.incidentSeverity,
            orElse: () => _severities[1])
        .$3;

    return _Card(children: [
      _FieldRow(
        iconBg: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
        icon: Icons.warning_amber_outlined,
        label: 'Titre de l\'incident',
        value: state.incidentTitle.isEmpty ? 'Ex: Route bloquée Delmas 33' : state.incidentTitle,
        onTap: () => _showTextDialog(
          context,
          title: 'Titre de l\'incident',
          hint: 'Ex: Route bloquée, manifestation...',
          initial: state.incidentTitle,
          onSave: notifier.setIncidentTitle,
          s: s,
        ),
        isLast: false,
      ),
      _FieldRow(
        iconBg: const Color(0xFFF1F5F9),
        iconColor: const Color(0xFF475569),
        icon: Icons.notes_outlined,
        label: 'Description (optionnel)',
        value: state.incidentDescription.isEmpty ? 'Ajouter des détails...' : state.incidentDescription,
        onTap: () => _showTextDialog(
          context,
          title: 'Description',
          hint: 'Décrivez l\'incident...',
          initial: state.incidentDescription,
          onSave: notifier.setIncidentDescription,
          s: s,
          multiline: true,
        ),
        isLast: false,
      ),
      _FieldRow(
        iconBg: const Color(0xFFFEF3C7),
        iconColor: sevColor,
        icon: Icons.flag_outlined,
        label: 'Sévérité',
        value: sevLabel,
        valueColor: sevColor,
        onTap: () => showModalBottomSheet(
          context: context,
          builder: (_) => Column(
            mainAxisSize: MainAxisSize.min,
            children: _severities
                .map((sev) => ListTile(
                      leading: Icon(Icons.circle, color: sev.$3, size: 14),
                      title: Text(sev.$2, style: TextStyle(color: sev.$3)),
                      onTap: () {
                        notifier.setIncidentSeverity(sev.$1);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        ),
        isLast: true,
      ),
    ]);
  }
}

// ── Correction tarif ──────────────────────────────────────────────────────────

class _FareCorrectionFields extends ConsumerWidget {
  final ContributeState state;
  final S s;
  const _FareCorrectionFields({required this.state, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contributeProvider.notifier);
    return _Card(children: [
      _FieldRow(
        iconBg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF3730A3),
        icon: Icons.location_on_outlined,
        label: 'Station concernée',
        value: state.correctionTarget.isEmpty ? 'Ex: Station Delmas 32' : state.correctionTarget,
        onTap: () => _showTextDialog(
          context,
          title: 'Station concernée',
          hint: 'Ex: Station Delmas 32',
          initial: state.correctionTarget,
          onSave: notifier.setCorrectionTarget,
          s: s,
        ),
        isLast: true,
      ),
    ]);
  }
}

// ── Correction générale ───────────────────────────────────────────────────────

class _CorrectionFields extends ConsumerWidget {
  final ContributeState state;
  final S s;
  const _CorrectionFields({required this.state, required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(contributeProvider.notifier);
    return _Card(children: [
      _FieldRow(
        iconBg: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF3730A3),
        icon: Icons.location_on_outlined,
        label: 'Station concernée',
        value: state.correctionTarget.isEmpty ? 'Ex: Station Delmas 32' : state.correctionTarget,
        onTap: () => _showTextDialog(
          context,
          title: 'Station concernée',
          hint: 'Ex: Station Delmas 32',
          initial: state.correctionTarget,
          onSave: notifier.setCorrectionTarget,
          s: s,
        ),
        isLast: false,
      ),
      _FieldRow(
        iconBg: const Color(0xFFFFF7ED),
        iconColor: const Color(0xFFC2410C),
        icon: Icons.edit_outlined,
        label: 'Correction à apporter',
        value: state.correctionDescription.isEmpty ? 'Décrivez l\'erreur...' : state.correctionDescription,
        onTap: () => _showTextDialog(
          context,
          title: 'Correction',
          hint: 'Ex: Le nom correct est...',
          initial: state.correctionDescription,
          onSave: notifier.setCorrectionDescription,
          s: s,
          multiline: true,
        ),
        isLast: true,
      ),
    ]);
  }
}

// ── Card conteneur ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
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
      child: Column(children: children),
    );
  }
}

// ── Helpers communs ───────────────────────────────────────────────────────────

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

void _showTextDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required String initial,
  required void Function(String) onSave,
  required S s,
  bool multiline = false,
}) async {
  final ctrl = TextEditingController(text: initial);
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        FilledButton(
          onPressed: () {
            onSave(ctrl.text.trim());
            Navigator.pop(context);
          },
          child: Text(s.ok),
        ),
      ],
    ),
  );
}

void _showStationPicker(
  BuildContext context, {
  required String title,
  required String hint,
  required String initial,
  required void Function(String) onSave,
  required S s,
}) {
  final ctrl = TextEditingController(text: initial);
  final searchCtrl = TextEditingController();
  String query = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final filtered = query.isEmpty
            ? kPortAuPrincePlaces
            : kPortAuPrincePlaces.where((p) => p.matches(query)).toList();

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                // Text input at top
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: hint,
                      prefixIcon: const Icon(Icons.edit_location_alt_outlined, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Search predefined places
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Chercher un quartier...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                    onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(height: 4),
                // Suggestions list
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final place = filtered[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                        title: Text(place.name, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(place.zone, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                        onTap: () {
                          onSave(place.name);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
                // Confirm custom text
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: () {
                        final text = ctrl.text.trim();
                        if (text.isNotEmpty) onSave(text);
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(s.ok),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
