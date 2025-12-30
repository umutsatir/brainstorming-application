import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';

/// ------------------------------------------------------------
/// TEAM LEADER OVERVIEW SCREEN
/// ------------------------------------------------------------
/// Not:
///  - upcomingSessions / completedSessions / totalIdeas şu an dummy.
///  - Phase 3’te bunları örneğin:
///      GET /api/sessions         (team leader’ın takımı için)
///      GET /api/ideas?sessionId=
///    gibi endpoint’lerden hesaplayabilirsin.
class TeamLeaderOverviewScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback onOpenCurrentSession;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenMyTeam;

  const TeamLeaderOverviewScreen({
    super.key,
    required this.user,
    required this.onOpenCurrentSession,
    required this.onOpenHistory,
    required this.onOpenMyTeam,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Şimdilik dummy metrikler: backend bağlanınca değiştirirsin
    const int upcomingSessions = 1;
    const int completedSessions = 5;
    const int totalIdeas = 120;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${user.name} 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here is a quick snapshot of your team\'s 6-3-5 activity.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),

          // Özet metrikler
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SmallMetricPill(
                      icon: Icons.schedule,
                      value: '$upcomingSessions',
                      label: 'Upcoming session',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallMetricPill(
                      icon: Icons.history,
                      value: '$completedSessions',
                      label: 'Completed sessions',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallMetricPill(
                      icon: Icons.lightbulb_outline,
                      value: '$totalIdeas',
                      label: 'Ideas logged',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Shortcuts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          _ShortcutCard(
            icon: Icons.play_circle_fill,
            title: 'Go to current session',
            description:
                'Open the 6-3-5 leader screen and manage the live rounds.',
            onTap: onOpenCurrentSession,
          ),
          const SizedBox(height: 8),
          _ShortcutCard(
            icon: Icons.history,
            title: 'Review session history',
            description:
                'See previous sessions and check idea volume per round.',
            onTap: onOpenHistory,
          ),
          const SizedBox(height: 8),
          _ShortcutCard(
            icon: Icons.group,
            title: 'Check your team',
            description:
                'View team members and make sure everyone is ready to join.',
            onTap: onOpenMyTeam,
          ),
        ],
      ),
    );
  }
}

class _SmallMetricPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SmallMetricPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
