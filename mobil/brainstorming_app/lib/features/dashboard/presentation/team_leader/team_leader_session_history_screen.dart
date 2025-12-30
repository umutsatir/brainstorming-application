import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repository/session_repository.dart';
import 'team_leader_session_report_screen.dart';

/// ------------------------------------------------------------
/// SESSION HISTORY – BACKEND ENTEGRE EKRAN (SessionRepository ile)
/// ------------------------------------------------------------

enum LeaderHistoryStatusFilter { all, completed, inProgress }

class TeamLeaderSessionHistoryScreen extends ConsumerStatefulWidget {
  /// In progress bir oturum için “Go to live session” dendiğinde
  /// shell'e haber vermek için callback
  final void Function(UiLeaderSessionHistoryItem) onOpenLiveSession;

  const TeamLeaderSessionHistoryScreen({
    super.key,
    required this.onOpenLiveSession,
  });

  @override
  ConsumerState<TeamLeaderSessionHistoryScreen> createState() =>
      _TeamLeaderSessionHistoryScreenState();
}

class _TeamLeaderSessionHistoryScreenState
    extends ConsumerState<TeamLeaderSessionHistoryScreen> {
  String _searchQuery = '';
  LeaderHistoryStatusFilter _statusFilter = LeaderHistoryStatusFilter.all;
  String _sortKey = 'Newest first';

  // backend verisi
  List<UiLeaderSessionHistoryItem> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // TODO: Şimdilik sabit; ileride TL shell'den gerçek teamId geçeriz.
  final int _teamId = 1;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  /// GET /api/sessions  (+ client-side teamId filtresi)
  Future<void> _fetchSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(sessionRepositoryProvider);
      final sessions = await repo.getTeamSessions(_teamId);

      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load sessions: $e';
      });
    }
  }

  List<UiLeaderSessionHistoryItem> get _filtered {
    var list = List<UiLeaderSessionHistoryItem>.from(_sessions);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((s) =>
              s.topicTitle.toLowerCase().contains(q) ||
              s.eventName.toLowerCase().contains(q))
          .toList();
    }

    if (_statusFilter != LeaderHistoryStatusFilter.all) {
      final wantCompleted =
          _statusFilter == LeaderHistoryStatusFilter.completed;
      list = list.where((s) => s.isCompleted == wantCompleted).toList();
    }

    switch (_sortKey) {
      case 'Ideas (most first)':
        list.sort((b, a) => a.totalIdeas.compareTo(b.totalIdeas));
        break;
      case 'Oldest first':
        list.sort((a, b) => a.startedAt.compareTo(b.startedAt));
        break;
      case 'Newest first':
      default:
        list.sort((b, a) => a.startedAt.compareTo(b.startedAt));
        break;
    }

    return list;
  }

  String _formatDateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}  '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _openSortSheet() async {
    final options = ['Newest first', 'Oldest first', 'Ideas (most first)'];

    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final current = _sortKey;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Sort sessions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              for (final opt in options)
                ListTile(
                  leading: current == opt
                      ? const Icon(Icons.check)
                      : const SizedBox(width: 24),
                  title: Text(opt),
                  onTap: () => Navigator.of(context).pop(opt),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (result != null && result != _sortKey) {
      setState(() => _sortKey = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: 'Search by topic or event name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _statusFilter == LeaderHistoryStatusFilter.all,
                    onSelected: (_) {
                      setState(
                        () => _statusFilter = LeaderHistoryStatusFilter.all,
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Completed'),
                    selected:
                        _statusFilter == LeaderHistoryStatusFilter.completed,
                    onSelected: (_) {
                      setState(
                        () =>
                            _statusFilter = LeaderHistoryStatusFilter.completed,
                      );
                    },
                  ),
                  ChoiceChip(
                    label: const Text('In progress'),
                    selected:
                        _statusFilter == LeaderHistoryStatusFilter.inProgress,
                    onSelected: (_) {
                      setState(
                        () =>
                            _statusFilter = LeaderHistoryStatusFilter.inProgress,
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sort),
                    label: Text(_sortKey),
                    onPressed: _openSortSheet,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoading) const LinearProgressIndicator(minHeight: 2),
              if (_errorMessage != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchSessions,
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${items.length} session(s) found',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? (_isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(
                      child: Text(
                        'No sessions match your filters.\n'
                        'Try changing status or search text.',
                        textAlign: TextAlign.center,
                      ),
                    ))
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
                            // Topic + status pill
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _HistoryMetricChip(
                                  icon: Icons.all_inclusive,
                                  label:
                                      '${s.completedRounds}/${s.totalRounds} rounds',
                                ),
                                _HistoryMetricChip(
                                  icon: Icons.lightbulb_outline,
                                  label: '${s.totalIdeas} ideas',
                                ),
                                _HistoryMetricChip(
                                  icon: Icons.tag,
                                  label: 'Session ID #${s.sessionId}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Actions
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // OPEN REPORT
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            LeaderSessionReportScreen(
                                          sessionId: s.sessionId,
                                          topicTitle: s.topicTitle,
                                          eventName: s.eventName,
                                          startedAt: s.startedAt,
                                          totalRounds: s.totalRounds,
                                          completedRounds: s.completedRounds,
                                          totalIdeas: s.totalIdeas,
                                          isCompleted: s.isCompleted,
                                        ),
                                      ),
                                    );
                                  },
                                  icon:
                                      const Icon(Icons.analytics_outlined),
                                  label: const Text('Open report'),
                                ),

                                // GO TO LIVE SESSION (sadece in-progress)
                                OutlinedButton.icon(
                                  onPressed: s.isCompleted
                                      ? null
                                      : () {
                                          // Shell'e haber ver → Current Session tab'ine geçecek
                                          widget.onOpenLiveSession(s);
                                        },
                                  icon: const Icon(
                                      Icons.play_circle_outline),
                                  label: Text(
                                    s.isCompleted
                                        ? 'Session completed'
                                        : 'Go to live session',
                                  ),
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

class _HistoryMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HistoryMetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.80),
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
