import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/models/dashboard_models.dart';
import '../providers/admin_provider.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  String _currentPeriod(S s) {
    final now = DateTime.now();
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: context.tc.background,
      body: Column(
        children: [
          _DashHeader(context: context, period: _currentPeriod(s)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatsGrid(stats: state.stats, s: s),
                  const SizedBox(height: 16),
                  _ModerationSection(cards: state.moderationCards, s: s),
                  const SizedBox(height: 12),
                  _IncidentsSection(incidents: state.incidents, s: s),
                  const SizedBox(height: 16),
                  _ExportButton(s: s),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DashHeader extends StatelessWidget {
  final BuildContext context;
  final String period;
  const _DashHeader({required this.context, required this.period});

  @override
  Widget build(BuildContext _) {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final s = ref.watch(stringsProvider);
                  return Text(s.dashTitle,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500));
                },
              ),
              const SizedBox(height: 2),
              const Text('Port-au-Prince',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(period,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final S s;
  const _StatsGrid({required this.stats, required this.s});

  String _formatNumber(int n) {
    if (n >= 1000) {
      final k = (n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1);
      return '$k k';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _StatCard(
          value: stats.activeStations.toString(),
          label: s.activeStations,
          trend: '+12',
          valueColor: const Color(0xFF15803D),
        ),
        _StatCard(
          value: _formatNumber(stats.activeUsers),
          label: s.activeUsers,
          trend: '+340',
        ),
        _StatCard(
          value: stats.verifiedContributors.toString(),
          label: s.verifiedContributors,
          trend: '+5',
        ),
        _StatCard(
          value: stats.activeIncidents.toString(),
          label: s.activeIncidents,
          valueColor: const Color(0xFFDC2626),
          subNote: s.unconfirmedIncidents(stats.unconfirmedIncidents),
          subNoteColor: const Color(0xFFDC2626),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? trend;
  final Color? valueColor;
  final String? subNote;
  final Color? subNoteColor;

  const _StatCard({
    required this.value,
    required this.label,
    this.trend,
    this.valueColor,
    this.subNote,
    this.subNoteColor,
  });

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? context.tc.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6C6C6C),
                  fontWeight: FontWeight.w500)),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.arrow_upward,
                    size: 11, color: Color(0xFF15803D)),
                const SizedBox(width: 2),
                Text(trend!,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF15803D))),
              ],
            ),
          ],
          if (subNote != null)
            Text(subNote!,
                style: TextStyle(
                    fontSize: 10,
                    color: subNoteColor ?? const Color(0xFF6C6C6C))),
        ],
      ),
    );
  }
}

// ─── Moderation Section ───────────────────────────────────────────────────────

class _ModerationSection extends StatelessWidget {
  final List<ModerationCard> cards;
  final S s;
  const _ModerationSection({required this.cards, required this.s});

  @override
  Widget build(BuildContext context) {
    return _DashSection(
      title: s.pendingContributions(cards.length),
      linkLabel: s.seeAll,
      onLinkTap: () {},
      child: cards.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.statusValidated,
                  style:
                      const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
            )
          : Column(
              children: cards
                  .map((c) => _ModerationRow(
                        card: c,
                        isLast: c == cards.last,
                        s: s,
                      ))
                  .toList(),
            ),
    );
  }
}

class _ModerationRow extends ConsumerWidget {
  final ModerationCard card;
  final bool isLast;
  final S s;
  const _ModerationRow(
      {required this.card, required this.isLast, required this.s});

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.moderationAction,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Text(card.name,
                style: const TextStyle(color: Color(0xFF6C6C6C))),
            Text(card.subtitle,
                style: const TextStyle(
                    color: Color(0xFF8E8E93), fontSize: 12)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(adminProvider.notifier).reject(card.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close,
                          size: 16, color: Color(0xFFDC2626)),
                      label: Text(s.rejectBtn,
                          style: const TextStyle(
                              color: Color(0xFFDC2626))),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFDC2626))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(adminProvider.notifier)
                            .approve(card.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(s.approveBtn),
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        InkWell(
          onTap: () => _showActions(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: card.avatarColor, shape: BoxShape.circle),
                  child: Center(
                    child: Text(card.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(card.subtitle,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8E8E93))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: card.status, s: s),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
              height: 1, indent: 60, color: context.tc.border),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ModerationStatus status;
  final S s;
  const _StatusBadge({required this.status, required this.s});

  @override
  Widget build(BuildContext context) {
    final (text, fg, bg) = switch (status) {
      ModerationStatus.pending => (
          s.statusPending,
          const Color(0xFF854D0E),
          const Color(0xFFFEF9C3)
        ),
      ModerationStatus.validated => (
          s.statusValidated,
          const Color(0xFF14532D),
          const Color(0xFFDCFCE7)
        ),
      ModerationStatus.toModerate => (
          s.statusToModerate,
          const Color(0xFF7C2D12),
          const Color(0xFFFFEDD5)
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }
}

// ─── Incidents Section ────────────────────────────────────────────────────────

class _IncidentsSection extends StatelessWidget {
  final List<IncidentItem> incidents;
  final S s;
  const _IncidentsSection({required this.incidents, required this.s});

  @override
  Widget build(BuildContext context) {
    return _DashSection(
      title: s.securityIncidents,
      linkLabel: s.mapLink,
      onLinkTap: () {},
      child: Column(
        children: incidents
            .map((i) =>
                _IncidentRow(item: i, isLast: i == incidents.last, s: s))
            .toList(),
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  final IncidentItem item;
  final bool isLast;
  final S s;
  const _IncidentRow(
      {required this.item, required this.isLast, required this.s});

  Color get _dotColor => switch (item.level) {
        IncidentSeverityLevel.high => const Color(0xFFDC2626),
        IncidentSeverityLevel.medium => const Color(0xFFF59E0B),
        IncidentSeverityLevel.resolved => const Color(0xFF16A34A),
      };

  (String, Color, Color) get _badge => switch (item.level) {
        IncidentSeverityLevel.high => (
            s.confirmations(item.confirmations),
            const Color(0xFF7F1D1D),
            const Color(0xFFFEE2E2)
          ),
        IncidentSeverityLevel.medium => (
            s.confirmations(item.confirmations),
            const Color(0xFF78350F),
            const Color(0xFFFEF3C7)
          ),
        IncidentSeverityLevel.resolved => (
            s.confirmed,
            const Color(0xFF14532D),
            const Color(0xFFDCFCE7)
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (badgeText, fg, bg) = _badge;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _dotColor, shape: BoxShape.circle)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.text,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(item.time,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(badgeText,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: fg)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1, indent: 34, color: context.tc.border),
      ],
    );
  }
}

// ─── Export Button ────────────────────────────────────────────────────────────

class _ExportButton extends ConsumerWidget {
  final S s;
  const _ExportButton({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.exportSoon),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.download_outlined, size: 18),
        label: Text(s.exportBtn),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Shared Section Wrapper ───────────────────────────────────────────────────

class _DashSection extends StatelessWidget {
  final String title;
  final String linkLabel;
  final VoidCallback onLinkTap;
  final Widget child;

  const _DashSection({
    required this.title,
    required this.linkLabel,
    required this.onLinkTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.tc.textPrimary)),
              GestureDetector(
                onTap: onLinkTap,
                child: Text(linkLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Container(
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
          child: child,
        ),
      ],
    );
  }
}
