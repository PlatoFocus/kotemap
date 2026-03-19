import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/dashboard_models.dart';

class AdminState {
  final DashboardStats stats;
  final List<ModerationCard> moderationCards;
  final List<IncidentItem> incidents;

  const AdminState({
    required this.stats,
    required this.moderationCards,
    required this.incidents,
  });
}

class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() => AdminState(
        stats: const DashboardStats(
          activeStations: 247,
          activeUsers: 1840,
          verifiedContributors: 63,
          activeIncidents: 12,
          unconfirmedIncidents: 3,
        ),
        moderationCards: [
          ModerationCard(
            id: '1',
            initials: 'JB',
            avatarColor: const Color(0xFF6366F1),
            name: 'Jean-Baptiste M.',
            subtitle: 'Nouvelle station · Delmas 18',
            status: ModerationStatus.pending,
          ),
          ModerationCard(
            id: '2',
            initials: 'RC',
            avatarColor: const Color(0xFF0EA5E9),
            name: 'Rose-Claire F.',
            subtitle: 'Tarif · Taptap Carrefour',
            status: ModerationStatus.validated,
          ),
          ModerationCard(
            id: '3',
            initials: 'DM',
            avatarColor: const Color(0xFFF97316),
            name: 'Dieudonne M.',
            subtitle: 'Incident sécurité · Bel Air',
            status: ModerationStatus.toModerate,
          ),
        ],
        incidents: [
          IncidentItem(
            id: '1',
            text: 'Bel Air — Blocus signalé',
            time: 'Il y a 45 min',
            confirmations: 4,
            level: IncidentSeverityLevel.high,
          ),
          IncidentItem(
            id: '2',
            text: 'Delmas 32 — Ralentissement',
            time: 'Il y a 2h',
            confirmations: 2,
            level: IncidentSeverityLevel.medium,
          ),
          IncidentItem(
            id: '3',
            text: 'Pétion-Ville — Route dégagée',
            time: 'Il y a 3h · Résolu',
            confirmations: 5,
            level: IncidentSeverityLevel.resolved,
            resolved: true,
          ),
        ],
      );

  void approve(String id) {
    final updated = state.moderationCards.map((c) {
      if (c.id == id) {
        return ModerationCard(
          id: c.id,
          initials: c.initials,
          avatarColor: c.avatarColor,
          name: c.name,
          subtitle: c.subtitle,
          status: ModerationStatus.validated,
        );
      }
      return c;
    }).toList();
    state = AdminState(
        stats: state.stats,
        moderationCards: updated,
        incidents: state.incidents);
  }

  void reject(String id) {
    final updated =
        state.moderationCards.where((c) => c.id != id).toList();
    state = AdminState(
        stats: state.stats,
        moderationCards: updated,
        incidents: state.incidents);
  }
}

final adminProvider =
    NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);
