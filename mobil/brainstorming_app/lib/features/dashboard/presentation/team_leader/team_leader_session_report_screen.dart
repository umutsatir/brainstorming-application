import 'package:flutter/material.dart';

/// Tek bir 6-3-5 session için rapor / özet ekranı (Leader tarafı).
/// Phase 3’te:
/// - GET /reports/sessions/{sessionId}
/// - GET /sessions/{sessionId}
/// çağrılarından gelen detaylarla dolduracaksın.
class LeaderSessionReportScreen extends StatelessWidget {
  final int sessionId;
  final String topicTitle;
  final String eventName;
  final DateTime startedAt;
  final int totalRounds;
  final int completedRounds;
  final int totalIdeas;
  final bool isCompleted;

  const LeaderSessionReportScreen({
    super.key,
    required this.sessionId,
    required this.topicTitle,
    required this.eventName,
    required this.startedAt,
    required this.totalRounds,
    required this.completedRounds,
    required this.totalIdeas,
    required this.isCompleted,
  });

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusColor = isCompleted ? Colors.green[700] : theme.colorScheme.primary;
    final statusLabel = isCompleted ? 'Completed' : 'In progress';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kart – basit özet
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic + status pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            topicTitle,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
                      eventName,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(startedAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _ReportChip(
                          icon: Icons.all_inclusive,
                          label: '$completedRounds / $totalRounds rounds',
                        ),
                        _ReportChip(
                          icon: Icons.lightbulb_outline,
                          label: '$totalIdeas ideas collected',
                        ),
                        _ReportChip(
                          icon: Icons.tag,
                          label: 'Session ID #$sessionId',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'AI summary & key insights',
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
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Later this section will show:\n'
                  '- AI-generated summary of the session\n'
                  '- Clustered themes / ideas\n'
                  '- Suggested next steps\n\n'
                  'Phase 3: GET /reports/sessions/{sessionId} sonucunu burada render edeceksin.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReportChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
