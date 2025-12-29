import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';

/// ------------------------------------------------------------
/// MEMBER OVERVIEW SCREEN
/// ------------------------------------------------------------

class MemberOverviewScreen extends StatelessWidget {
  final AppUser user;

  /// Şu an aktif bir 6-3-5 session var mı?
  final bool hasActiveSession;

  /// Aktif session varsa “Go to live session” butonu bu callback’i çağıracak
  final VoidCallback onGoToLiveSession;

  /// “My past sessions” shortcut’ı
  final VoidCallback onOpenHistory;

  /// “Settings” shortcut’ı
  final VoidCallback onOpenSettings;

  const MemberOverviewScreen({
    super.key,
    required this.user,
    required this.hasActiveSession,
    required this.onGoToLiveSession,
    required this.onOpenHistory,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Şimdilik dummy current / upcoming session bilgisi:
    const String eventName = 'Q1 Growth Strategy 6-3-5';
    const String topicTitle = 'Increase user engagement for mobile app';
    const String teamName = 'Growth Squad Alpha';
    const int teamSize = 6;
    const int totalRounds = 6;
    const int roundMinutes = 5;
    const String nextStartTime = '14:30';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------------
          // Greeting
          // ----------------------------------------------------------
          Text(
            'Hello, ${user.name} 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here is what’s happening with your team’s 6-3-5 sessions.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),

          // ----------------------------------------------------------
          // Current / Upcoming Session Card
          // ----------------------------------------------------------
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasActiveSession
                        ? 'Current 6-3-5 session'
                        : 'Next 6-3-5 session',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    eventName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Topic: $topicTitle',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$teamSize participants',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.all_inclusive, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$totalRounds rounds · $roundMinutes min each',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        hasActiveSession
                            ? Icons.circle
                            : Icons.schedule_outlined,
                        size: 12,
                        color: hasActiveSession
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasActiveSession
                            ? 'LIVE – you can join now'
                            : 'Scheduled – starts at $nextStartTime (dummy)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        hasActiveSession
                            ? Icons.play_arrow
                            : Icons.info_outline,
                      ),
                      label: Text(
                        hasActiveSession
                            ? 'Go to live session'
                            : 'Session not started yet',
                      ),
                      onPressed: hasActiveSession ? onGoToLiveSession : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------------
          // Shortcuts
          // ----------------------------------------------------------
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
            icon: Icons.history,
            title: 'My past sessions',
            description:
                'See which 6-3-5 sessions you joined and your idea count.',
            onTap: onOpenHistory,
          ),
          const SizedBox(height: 8),
          _ShortcutCard(
            icon: Icons.settings,
            title: 'Settings',
            description:
                'Change your name or password, and log out of the app.',
            onTap: onOpenSettings,
          ),

          const SizedBox(height: 20),

          // ----------------------------------------------------------
          // Info: How 6-3-5 works?
          // ----------------------------------------------------------
          Text(
            'How does 6-3-5 work?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'The 6-3-5 method means:\n'
                    '• 6 participants\n'
                    '• 3 ideas each per round\n'
                    '• 5 minutes per round',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'On the live screen, you will see a timer and an idea grid. '
                    'In each round, you quickly write or refine ideas. '
                    'When the timer ends, your sheet is rotated to the next person.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
