import 'dart:ui';

enum ModerationStatus { pending, validated, toModerate }

enum IncidentSeverityLevel { high, medium, resolved }

class ModerationCard {
  final String id;
  final String initials;
  final Color avatarColor;
  final String name;
  final String subtitle;
  final ModerationStatus status;

  const ModerationCard({
    required this.id,
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.subtitle,
    required this.status,
  });
}

class IncidentItem {
  final String id;
  final String text;
  final String time;
  final int confirmations;
  final IncidentSeverityLevel level;
  final bool resolved;

  const IncidentItem({
    required this.id,
    required this.text,
    required this.time,
    required this.confirmations,
    required this.level,
    this.resolved = false,
  });
}

class DashboardStats {
  final int activeStations;
  final int activeUsers;
  final int verifiedContributors;
  final int activeIncidents;
  final int unconfirmedIncidents;

  const DashboardStats({
    required this.activeStations,
    required this.activeUsers,
    required this.verifiedContributors,
    required this.activeIncidents,
    required this.unconfirmedIncidents,
  });
}
