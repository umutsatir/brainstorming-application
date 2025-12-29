import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';

class EventManagerOverviewScreen extends StatelessWidget {

    final AppUser user;

  const EventManagerOverviewScreen({super.key, required this.user});

  String get _greeting {
    // basit bir selamlama, istersen daha akıllı yaparız
    final firstName =
        user.name.trim().split(' ').first; // "Mert Certel" -> "Mert"
    return 'Good morning, $firstName.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + alt açıklama
          Text(
            'Dashboard Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
           '$_greeting Here\'s what\'s happening today.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),),
          const SizedBox(height: 16),

          // 4 istatistik kartı – 2x2 grid
          _StatsGrid(),
          const SizedBox(height: 24),

          // Latest AI summary + Recent activity
          _LatestAndActivitySection(),
          const SizedBox(height: 24),

          // Active topics tablosu
          _ActiveTopicsSection(),
        ],
      ),
    );
  }
}

/// 2x2 grid halinde küçük metrik kartları
class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cards = [
      _StatInfo(
        title: 'Total participants',
        value: '124',
        changeText: '+12%',
        changeIcon: Icons.arrow_upward,
        changeColor: Colors.green,
      ),
      _StatInfo(
        title: 'Active teams',
        value: '8',
        changeText: '0% vs. yesterday',
        changeIcon: Icons.horizontal_rule,
        changeColor: Colors.grey,
      ),
      _StatInfo(
        title: 'Completed sessions',
        value: '45',
        changeText: '+3 today',
        changeIcon: Icons.arrow_upward,
        changeColor: Colors.green,
      ),
      _StatInfo(
        title: 'Ideas generated',
        value: '1,203',
        changeText: '+8%',
        changeIcon: Icons.arrow_upward,
        changeColor: Colors.green,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // padding + spacing’i hesaba katıp yaklaşık yarı genişlik
        final itemWidth = (width - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (info) => SizedBox(
                  width: itemWidth,
                  child: _StatCard(info: info, theme: theme),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatInfo {
  final String title;
  final String value;
  final String changeText;
  final IconData changeIcon;
  final Color changeColor;

  _StatInfo({
    required this.title,
    required this.value,
    required this.changeText,
    required this.changeIcon,
    required this.changeColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatInfo info;
  final ThemeData theme;

  const _StatCard({
    required this.info,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              info.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  info.changeIcon,
                  size: 16,
                  color: info.changeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  info.changeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: info.changeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Latest AI summary + Recent activity (üst alt şeklinde, mobil dostu)
class _LatestAndActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Latest AI summary
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Latest AI session summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Generated 2h ago • Q1 Product Launch 6-3-5',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Topic: Product Launch Q4',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The brainstorming session focused on customer acquisition for the upcoming launch. The AI summarised three main clusters of ideas.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Key takeaways',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _bullet('Double down on TikTok & Reels creatives.'),
                      _bullet(
                          'Create a “Founders Journey” launch video series.'),
                      _bullet(
                          'Introduce referral incentives for early adopters.'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Full report screen coming later.'),
                          ),
                        );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View full report'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Recent activity
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _activityItem(
                  context,
                  title:
                      'Team Alpha submitted 5 new ideas for Winter Campaign',
                  timeAgo: '45 min ago',
                ),
                const Divider(),
                _activityItem(
                  context,
                  title: 'Session #402 marked as completed',
                  timeAgo: '2 h ago',
                ),
                const Divider(),
                _activityItem(
                  context,
                  title: 'New member invited to Team Beta',
                  timeAgo: '3 h ago',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content:
                                Text('Activity list screen coming later.'),
                          ),
                        );
                    },
                    child: const Text('View all activity'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _activityItem(
    BuildContext context, {
    required String title,
    required String timeAgo,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        child: const Icon(Icons.bolt, size: 18),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        timeAgo,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

/// Active topics bölümü
class _ActiveTopicsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active topics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _topicRow(
              context,
              name: 'UX Redesign 2.0',
              teams: 'A, B',
              status: 'Active',
              progress: 0.75,
            ),
            const Divider(),
            _topicRow(
              context,
              name: 'Growth Experiments Q1',
              teams: 'Growth, Data',
              status: 'Preparing',
              progress: 0.4,
            ),
            const Divider(),
            _topicRow(
              context,
              name: 'Support Automation',
              teams: 'Ops',
              status: 'Completed',
              progress: 1.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicRow(
    BuildContext context, {
    required String name,
    required String teams,
    required String status,
    required double progress,
  }) {
    final theme = Theme.of(context);

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = Colors.green;
        break;
      case 'preparing':
        statusColor = Colors.orange;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = theme.colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Teams: $teams',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          borderRadius: BorderRadius.circular(999),
        ),
      ],
    );
  }
}
