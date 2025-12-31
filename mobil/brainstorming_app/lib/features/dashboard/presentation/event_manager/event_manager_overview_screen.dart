import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user.dart';
import '../../../../data/core/api_client.dart';
import '../../../../data/repository/event_manager_repository.dart';

/// ------------------------------------------------------------
/// MODEL + PROVIDER 
/// ------------------------------------------------------------

class EventManagerOverviewData {
  final int activeEvents;
  final int totalParticipants;
  final int activeTeams;
  final int totalSessions;

  const EventManagerOverviewData({
    required this.activeEvents,
    required this.totalParticipants,
    required this.activeTeams,
    required this.totalSessions,
  });

  factory EventManagerOverviewData.empty() => const EventManagerOverviewData(
        activeEvents: 0,
        totalParticipants: 0,
        activeTeams: 0,
        totalSessions: 0,
      );
}

final eventManagerOverviewProvider =
    FutureProvider.autoDispose<EventManagerOverviewData>((ref) async {
  final eventManagerRepo = ref.read(eventManagerRepositoryProvider);
  final apiClient = ref.read(apiClientProvider);

  int activeEventsCount = 0;
  int activeTeamsCount = 0;
  int participantsCount = 0;
  int sessionsCount = 0;

  // Tüm event'leri bir kere çekip hem activeEvents hem teams için kullanacağız
  List<UiEventSummary> allEvents = [];

  // 1) Events
  try {
    allEvents = await eventManagerRepo.getAllEvents();
    activeEventsCount =
        allEvents.where((e) => e.status == EventStatus.live).length;
  } catch (e, st) {
    debugPrint('getAllEvents error: $e\n$st');
  }

  // 2) Teams (GLOBAL /teams yok; her event için /events/{id}/teams çağırıyoruz)
  try {
    int totalTeams = 0;

    for (final event in allEvents) {
      try {
        final teamsForEvent =
            await eventManagerRepo.getTeamsForEvent(event.id);
        totalTeams += teamsForEvent.length;
      } catch (inner) {
        debugPrint('getTeamsForEvent(${event.id}) error: $inner');
      }
    }

    activeTeamsCount = totalTeams;
  } catch (e, st) {
    debugPrint('Teams aggregation error: $e\n$st');
  }

  // 3) Participants (global /participants endpoint'in varsa bu kısım çalışır)
  try {
    final participantsResponse = await apiClient.get('/participants');
    final pData = participantsResponse.data;
    if (pData is List) {
      participantsCount = pData.length;
    } else if (pData is Map<String, dynamic>) {
      final list = (pData['participants'] as List?) ??
          (pData['data'] as List?) ??
          const [];
      participantsCount = list.length;
    }
  } catch (e, st) {
    debugPrint('GET /participants error: $e\n$st');
  }

  // 4) Sessions (benzer şekilde global /sessions varsa)
  try {
    final sessionsResponse = await apiClient.get('/sessions');
    final sData = sessionsResponse.data;
    if (sData is List) {
      sessionsCount = sData.length;
    } else if (sData is Map<String, dynamic>) {
      final list = (sData['sessions'] as List?) ??
          (sData['data'] as List?) ??
          const [];
      sessionsCount = list.length;
    }
  } catch (e, st) {
    debugPrint('GET /sessions error: $e\n$st');
  }

  return EventManagerOverviewData(
    activeEvents: activeEventsCount,
    totalParticipants: participantsCount,
    activeTeams: activeTeamsCount,
    totalSessions: sessionsCount,
  );
});

/// ------------------------------------------------------------
/// EKRAN
/// ------------------------------------------------------------

class EventManagerOverviewScreen extends ConsumerWidget {
  final AppUser user;

  const EventManagerOverviewScreen({super.key, required this.user});

  String get _greeting {
    final firstName = user.name.trim().split(' ').first;
    return 'Good morning, $firstName.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(eventManagerOverviewProvider);

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
            '$_greeting Here\'s what\'s happening across your events.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // İstatistik kartları – backend verisi ile
          overviewAsync.when(
            data: (data) => _StatsGrid(data: data),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, st) {
              return _StatsGrid(data: EventManagerOverviewData.empty());
            },
          ),
          const SizedBox(height: 24),

          // Latest AI summary + Recent activity (şimdilik dummy, ileride /ai & /reports ile bağlanır)
          const _LatestAndActivitySection(),
          const SizedBox(height: 24),

          // Active topics tablosu (şimdilik dummy, ileride /topics ve /events/{id}/topics ile bağlanır)
          const _ActiveTopicsSection(),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// İSTATİSTİK GRIDİ
/// ------------------------------------------------------------

class _StatInfo {
  final String title;
  final String value;
  final String subtitle;

  const _StatInfo({
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class _StatsGrid extends StatelessWidget {
  final EventManagerOverviewData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stats = <_StatInfo>[
      _StatInfo(
        title: 'Active events',
        value: data.activeEvents.toString(),
        subtitle: 'Status = LIVE',
      ),
      _StatInfo(
        title: 'Participants',
        value: data.totalParticipants.toString(),
        subtitle: 'Across all roles',
      ),
      _StatInfo(
        title: 'Teams',
        value: data.activeTeams.toString(),
        subtitle: 'Configured in system',
      ),
      _StatInfo(
        title: 'Sessions',
        value: data.totalSessions.toString(),
        subtitle: 'All brainstorming sessions',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = (width - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats.map((info) {
            return SizedBox(
              width: itemWidth,
              child: _StatCard(info: info),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatInfo info;

  const _StatCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.title,
              style: theme.textTheme.labelLarge?.copyWith(
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
            Text(
              info.subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// LATEST AI SUMMARY + RECENT ACTIVITY (şimdilik statik)
/// ------------------------------------------------------------

class _LatestAndActivitySection extends StatelessWidget {
  const _LatestAndActivitySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Latest AI session summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer onboarding improvements – Team Alpha',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The last brainstorming session focused on reducing churn in the first 14 days. '
                  'AI summarised the ideas into three main clusters: education, nudges, and product fit.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Key takeaways',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _bullet('Automated in-app checklist for new users.'),
                _bullet('Short explainer videos embedded in critical flows.'),
                _bullet('Referral nudges after first successful milestone.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Recent activity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _activityItem(
          context,
          title: 'Team Beta completed a 6-3-5 session on “Pricing strategy”.',
          timeAgo: '5 min ago',
        ),
        _activityItem(
          context,
          title: '2 new participants joined “Winter Hackathon 2025”.',
          timeAgo: '23 min ago',
        ),
        _activityItem(
          context,
          title: 'AI summary generated for “Zero-Waste Kit launch ideas”.',
          timeAgo: '1 hour ago',
        ),
      ],
    );
  }

  static Widget _bullet(String text) {
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

  static Widget _activityItem(
    BuildContext context, {
    required String title,
    required String timeAgo,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        radius: 16,
        child: Icon(Icons.bolt, size: 18),
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

/// ------------------------------------------------------------
/// ACTIVE TOPICS (şimdilik dummy – ileride /topics ile bağlanır)
/// ------------------------------------------------------------

class _ActiveTopicsSection extends StatelessWidget {
  const _ActiveTopicsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Şimdilik statik; ileride EventManagerRepository.getTopicsForEvent() veya
    // backend'den bir özet endpoint ile bağlayabiliriz.
    final topics = [
      _ActiveTopicRow(
        topic: 'Zero-waste kit launch',
        eventName: 'Sustainability Ideathon',
        teamsInvolved: 3,
        progress: 0.7,
      ),
      _ActiveTopicRow(
        topic: 'Onboarding funnel optimisation',
        eventName: 'Growth Hack Week',
        teamsInvolved: 2,
        progress: 0.5,
      ),
      _ActiveTopicRow(
        topic: 'Employee wellness perks',
        eventName: 'HR Innovation Day',
        teamsInvolved: 1,
        progress: 0.3,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active topics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...topics.map((t) => _ActiveTopicTile(row: t)),
      ],
    );
  }
}

class _ActiveTopicRow {
  final String topic;
  final String eventName;
  final int teamsInvolved;
  final double progress; // 0..1 arası

  const _ActiveTopicRow({
    required this.topic,
    required this.eventName,
    required this.teamsInvolved,
    required this.progress,
  });
}

class _ActiveTopicTile extends StatelessWidget {
  final _ActiveTopicRow row;

  const _ActiveTopicTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.topic,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              row.eventName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: row.progress,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(row.progress * 100).round()}%',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${row.teamsInvolved} team(s) involved',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
