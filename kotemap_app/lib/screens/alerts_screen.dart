import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/i18n/app_strings.dart';
import '../core/theme/app_theme_colors.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    final alerts = [
      _AlertData(
        text: 'Bel Air — Blocus signalé',
        time: 'Il y a 45 min',
        dotColor: const Color(0xFFDC2626),
        cardColor: const Color(0xFFFEF2F2),
        badge: s.confirmations(4),
        badgeColor: const Color(0xFFDC2626),
      ),
      _AlertData(
        text: 'Delmas 32 — Ralentissement',
        time: 'Il y a 2h',
        dotColor: const Color(0xFFF59E0B),
        cardColor: const Color(0xFFFFF9EB),
        badge: s.confirmations(2),
        badgeColor: const Color(0xFFF59E0B),
      ),
      _AlertData(
        text: 'Route Nationale 1 — Travaux',
        time: 'Il y a 4h',
        dotColor: const Color(0xFF3B82F6),
        cardColor: const Color(0xFFEFF6FF),
        badge: s.information,
        badgeColor: const Color(0xFF3B82F6),
      ),
      _AlertData(
        text: 'Pétion-Ville — Route dégagée',
        time: 'Il y a 3h · Résolu',
        dotColor: const Color(0xFF16A34A),
        cardColor: const Color(0xFFF0FDF4),
        badge: s.confirmed,
        badgeColor: const Color(0xFF16A34A),
      ),
    ];

    return Scaffold(
      backgroundColor: context.tc.background,
      body: Column(
        children: [
          _AlertsHeader(context: context, s: s),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
              itemBuilder: (_, i) => _AlertCard(
                data: alerts[i],
                onTap: () => _showAlertDetail(context, alerts[i], s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertDetail(
      BuildContext context, _AlertData data, S s) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: data.dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(data.text,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(data.time,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF8E8E93))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: data.dotColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(data.badge,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: data.badgeColor)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertData {
  final String text;
  final String time;
  final Color dotColor;
  final Color cardColor;
  final String badge;
  final Color badgeColor;

  const _AlertData({
    required this.text,
    required this.time,
    required this.dotColor,
    required this.cardColor,
    required this.badge,
    required this.badgeColor,
  });
}

class _AlertsHeader extends StatelessWidget {
  final BuildContext context;
  final S s;
  const _AlertsHeader({required this.context, required this.s});

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
        children: [
          Text(s.alertsTitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const Spacer(),
          const Icon(Icons.notifications_active,
              color: Colors.white, size: 22),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _AlertData data;
  final VoidCallback onTap;

  const _AlertCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: data.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: data.dotColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: data.dotColor, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.text,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(data.time,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8E8E93))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          data.dotColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(data.badge,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: data.badgeColor)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }
}
