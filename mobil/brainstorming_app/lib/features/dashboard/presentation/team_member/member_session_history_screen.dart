import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// MEMBER – MY SESSIONS (History)
/// ------------------------------------------------------------

class UiMemberSessionHistoryItem {
  final int sessionId;
  final String topicTitle;
  final String eventName;
  final DateTime startedAt;
  final int contributedIdeas;
  final bool isCompleted;

  const UiMemberSessionHistoryItem({
    required this.sessionId,
    required this.topicTitle,
    required this.eventName,
    required this.startedAt,
    required this.contributedIdeas,
    required this.isCompleted,
  });
}

// Dummy data – Phase 3’te backend’den ("/members/{id}/sessions") gelecek
final List<UiMemberSessionHistoryItem> _dummyMemberHistory = [
  UiMemberSessionHistoryItem(
    sessionId: 201,
    topicTitle: 'Increase user engagement for mobile app',
    eventName: 'Q1 Growth Strategy 6-3-5',
    startedAt: DateTime(2025, 7, 1, 10, 0),
    contributedIdeas: 18,
    isCompleted: true,
  ),
  UiMemberSessionHistoryItem(
    sessionId: 202,
    topicTitle: 'Reduce onboarding friction',
    eventName: 'Customer Experience Sprint',
    startedAt: DateTime(2025, 6, 15, 14, 30),
    contributedIdeas: 9,
    isCompleted: false,
  ),
];

class MemberSessionHistoryScreen extends StatelessWidget {
  const MemberSessionHistoryScreen({super.key});

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _dummyMemberHistory;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${items.length} session(s) you joined',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text(
                    'You haven’t joined any sessions yet.\n'
                    'Once you participate in a 6-3-5, it will appear here.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final s = items[index];
                    final statusColor = s.isCompleted
                        ? Colors.green[700]
                        : theme.colorScheme.primary;
                    final statusLabel =
                        s.isCompleted ? 'Completed' : 'In progress';

                    return Card(
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.topicTitle,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor!.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.eventName,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.schedule, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(s.startedAt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${s.contributedIdeas} ideas you contributed',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
