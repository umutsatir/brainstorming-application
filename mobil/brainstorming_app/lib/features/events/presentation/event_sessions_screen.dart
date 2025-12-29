import 'package:flutter/material.dart';
import '../../reports/presentation/reports_screen.dart';
/// ---- UI MODELLERİ ----

enum SessionStatus { scheduled, live, completed, cancelled }

class UiEventSession {
  final int id;
  final int eventId;
  final String eventName;
  final String teamName;
  final String topicTitle;
  final String teamLeaderName;
  final int participantsCount;
  final SessionStatus status;
  final int totalRounds;
  final int completedRounds;
  final int ideasCount;
  final Duration roundDuration;
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool aiSummaryReady;

  const UiEventSession({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.teamName,
    required this.topicTitle,
    required this.teamLeaderName,
    required this.participantsCount,
    required this.status,
    required this.totalRounds,
    required this.completedRounds,
    required this.ideasCount,
    required this.roundDuration,
    this.scheduledFor,
    this.startedAt,
    this.endedAt,
    this.aiSummaryReady = false,
  });
}

/// ---- DUMMY DATA (global) ----

final List<UiEventSession> _dummySessions = [
  UiEventSession(
    id: 1,
    eventId: 1,
    eventName: 'Q3 Innovation Ideathon',
    teamName: 'Team Aurora',
    topicTitle: 'New Growth Channels for Q3',
    teamLeaderName: 'Alex Morgan',
    participantsCount: 6,
    status: SessionStatus.completed,
    totalRounds: 6,
    completedRounds: 6,
    ideasCount: 108,
    roundDuration: const Duration(minutes: 5),
    scheduledFor: DateTime(2025, 7, 1, 10, 0),
    startedAt: DateTime(2025, 7, 1, 10, 5),
    endedAt: DateTime(2025, 7, 1, 10, 35),
    aiSummaryReady: true,
  ),
  UiEventSession(
    id: 2,
    eventId: 1,
    eventName: 'Q3 Innovation Ideathon',
    teamName: 'Customer Heroes',
    topicTitle: 'Lower Churn in First 30 Days',
    teamLeaderName: 'Sarah Lee',
    participantsCount: 6,
    status: SessionStatus.live,
    totalRounds: 6,
    completedRounds: 3,
    ideasCount: 54,
    roundDuration: const Duration(minutes: 5),
    scheduledFor: DateTime(2025, 7, 2, 14, 0),
    startedAt: DateTime(2025, 7, 2, 14, 5),
    endedAt: null,
    aiSummaryReady: false,
  ),
  UiEventSession(
    id: 3,
    eventId: 1,
    eventName: 'Q3 Innovation Ideathon',
    teamName: 'Team Pixel',
    topicTitle: 'Onboarding Flow Improvements',
    teamLeaderName: 'Mert Certel',
    participantsCount: 5,
    status: SessionStatus.scheduled,
    totalRounds: 6,
    completedRounds: 0,
    ideasCount: 0,
    roundDuration: const Duration(minutes: 5),
    scheduledFor: DateTime(2025, 7, 3, 9, 30),
    startedAt: null,
    endedAt: null,
    aiSummaryReady: false,
  ),
  UiEventSession(
    id: 4,
    eventId: 2,
    eventName: 'Customer Centricity Sprint',
    teamName: 'CX Ninjas',
    topicTitle: 'VIP Retention Experiments',
    teamLeaderName: 'Michael Chen',
    participantsCount: 6,
    status: SessionStatus.cancelled,
    totalRounds: 6,
    completedRounds: 1,
    ideasCount: 12,
    roundDuration: const Duration(minutes: 5),
    scheduledFor: DateTime(2025, 6, 25, 15, 0),
    startedAt: DateTime(2025, 6, 25, 15, 5),
    endedAt: DateTime(2025, 6, 25, 15, 10),
    aiSummaryReady: false,
  ),
];

/// ---- EKRAN ----
/// Belirli bir event için tüm 6-3-5 oturumlarını Event Manager gözünden gösterir.

class EventSessionsScreen extends StatefulWidget {
  final int eventId;
  final String eventName;

  const EventSessionsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<EventSessionsScreen> createState() => _EventSessionsScreenState();
}

class _EventSessionsScreenState extends State<EventSessionsScreen> {
  String _searchQuery = '';
  SessionStatus? _statusFilter; // null => All
  String _sortKey = 'Start time (newest first)';

  List<UiEventSession> get _sessionsForEvent {
    var list = _dummySessions
        .where((s) => s.eventId == widget.eventId)
        .toList(growable: false);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        return s.teamName.toLowerCase().contains(q) ||
            s.topicTitle.toLowerCase().contains(q) ||
            s.teamLeaderName.toLowerCase().contains(q);
      }).toList();
    }

    if (_statusFilter != null) {
      list = list.where((s) => s.status == _statusFilter).toList();
    }

    switch (_sortKey) {
      case 'Team (A-Z)':
        list.sort((a, b) => a.teamName.compareTo(b.teamName));
        break;
      case 'Ideas (most first)':
        list.sort((b, a) => a.ideasCount.compareTo(b.ideasCount));
        break;
      case 'Start time (newest first)':
      default:
        list.sort((a, b) {
          final aTime = a.startedAt ?? a.scheduledFor ?? DateTime(1970);
          final bTime = b.startedAt ?? b.scheduledFor ?? DateTime(1970);
          // newest first
          return bTime.compareTo(aTime);
        });
        break;
    }

    return list;
  }

  int get _totalSessions => _sessionsForEvent.length;

  int get _liveSessions =>
      _sessionsForEvent.where((s) => s.status == SessionStatus.live).length;

  int get _completedSessions => _sessionsForEvent
      .where((s) => s.status == SessionStatus.completed)
      .length;

  int get _totalIdeas =>
      _sessionsForEvent.fold<int>(0, (sum, s) => sum + s.ideasCount);

  int get _totalTeams =>
      _sessionsForEvent.map((s) => s.teamName).toSet().length;

  String _statusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return 'Scheduled';
      case SessionStatus.live:
        return 'Live';
      case SessionStatus.completed:
        return 'Completed';
      case SessionStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusChipColor(SessionStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case SessionStatus.scheduled:
        return theme.colorScheme.secondary.withOpacity(0.12);
      case SessionStatus.live:
        return Colors.green.withOpacity(0.16);
      case SessionStatus.completed:
        return theme.colorScheme.primary.withOpacity(0.12);
      case SessionStatus.cancelled:
        return Colors.red.withOpacity(0.12);
    }
  }

  Color _statusTextColor(SessionStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case SessionStatus.scheduled:
        return theme.colorScheme.secondary;
      case SessionStatus.live:
        return Colors.green[800] ?? Colors.green;
      case SessionStatus.completed:
        return theme.colorScheme.primary;
      case SessionStatus.cancelled:
        return Colors.red[700] ?? Colors.red;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year} $h:$m';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    return '$m min/round';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openDetailsSheet(UiEventSession s) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final progress = s.totalRounds == 0
            ? 0.0
            : (s.completedRounds / s.totalRounds).clamp(0.0, 1.0);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.teamName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.topicTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: _statusChipColor(s.status, context),
                        ),
                        child: Text(
                          _statusLabel(s.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusTextColor(s.status, context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SummaryChip(
                        icon: Icons.groups,
                        label: 'Participants',
                        value: '${s.participantsCount}',
                      ),
                      const SizedBox(width: 8),
                      _SummaryChip(
                        icon: Icons.all_inclusive,
                        label: 'Rounds',
                        value: '${s.completedRounds}/${s.totalRounds}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Session details',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.person,
                          label: 'Team leader',
                          value: s.teamLeaderName,
                        ),
                        const SizedBox(height: 6),
                        _DetailRow(
                          icon: Icons.timer,
                          label: 'Round duration',
                          value: _formatDuration(s.roundDuration),
                        ),
                        const SizedBox(height: 6),
                        _DetailRow(
                          icon: Icons.event_available,
                          label: 'Scheduled for',
                          value: _formatDateTime(s.scheduledFor),
                        ),
                        const SizedBox(height: 6),
                        _DetailRow(
                          icon: Icons.play_arrow,
                          label: 'Started at',
                          value: _formatDateTime(s.startedAt),
                        ),
                        const SizedBox(height: 6),
                        _DetailRow(
                          icon: Icons.stop,
                          label: 'Ended at',
                          value: _formatDateTime(s.endedAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Progress & ideas',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rounds ${s.completedRounds}/${s.totalRounds}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SmallPill(
                        icon: Icons.lightbulb_outline,
                        label: '${s.ideasCount} ideas',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quick actions (Event Manager)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (s.status == SessionStatus.scheduled)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSnack(
                              'Start session #${s.id} now (EM override – dummy).',
                            );
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Start session now'),
                        ),
                      if (s.status == SessionStatus.live)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSnack(
                              'Pause live session #${s.id} (EM override – dummy).',
                            );
                          },
                          icon: const Icon(Icons.pause_circle_outline),
                          label: const Text('Pause session'),
                        ),
                      if (s.status == SessionStatus.live)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSnack(
                              'Open live monitor for "${s.teamName}" (dummy).',
                            );
                          },
                          icon: const Icon(Icons.monitor_heart),
                          label: const Text('Open live monitor'),
                        ),
                      if (s.aiSummaryReady)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSnack(
                              'Open AI summary for "${s.teamName}" (dummy – Reports tab).',
                            );
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('View AI summary'),
                        ),
                      if (!s.aiSummaryReady &&
                          s.status == SessionStatus.completed)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSnack(
                              'Request AI summary for session #${s.id} (dummy – will call ChatGPT).',
                            );
                          },
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('Request AI summary'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportsScreen(initialEventId: s.eventId),
                          ),
                        );
                        },
                        icon: const Icon(Icons.table_view),
                        label: const Text('View in Reports'),
                      ),
                      if (s.status == SessionStatus.live)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSnack(
                              'Force end live session #${s.id} (dummy).',
                            );
                          },
                          icon: Icon(
                            Icons.stop_circle,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            'End session (force)',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      if (s.status == SessionStatus.scheduled)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showSnack(
                              'Cancel scheduled session #${s.id} (dummy).',
                            );
                          },
                          icon: Icon(
                            Icons.cancel,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            'Cancel session',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _returnAndPop() {
    // parent String bekliyorsa null gitmesin diye
    Navigator.of(context).pop('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = _sessionsForEvent;

    return WillPopScope(
      onWillPop: () async {
        _returnAndPop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _returnAndPop,
          ),
          title: Text('Sessions – ${widget.eventName}'),
        ),
        body: Column(
          children: [
            // Üst filtre + özet
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arama
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search by team, topic or leader',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_totalSessions sessions • $_liveSessions live • '
                    '$_completedSessions completed • $_totalIdeas ideas',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Status filter
                      OutlinedButton.icon(
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: Text(
                          _statusFilter == null
                              ? 'All statuses'
                              : _statusLabel(_statusFilter!),
                        ),
                        onPressed: () async {
                          final result =
                              await showModalBottomSheet<SessionStatus?>(
                            context: context,
                            showDragHandle: true,
                            builder: (_) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const ListTile(
                                      title: Text(
                                        'Filter sessions by status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      leading: _statusFilter == null
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('All'),
                                      onTap: () =>
                                          Navigator.of(context).pop(null),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: _statusFilter ==
                                              SessionStatus.scheduled
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Scheduled'),
                                      onTap: () => Navigator.of(context)
                                          .pop(SessionStatus.scheduled),
                                    ),
                                    ListTile(
                                      leading: _statusFilter ==
                                              SessionStatus.live
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Live'),
                                      onTap: () => Navigator.of(context)
                                          .pop(SessionStatus.live),
                                    ),
                                    ListTile(
                                      leading: _statusFilter ==
                                              SessionStatus.completed
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Completed'),
                                      onTap: () => Navigator.of(context)
                                          .pop(SessionStatus.completed),
                                    ),
                                    ListTile(
                                      leading: _statusFilter ==
                                              SessionStatus.cancelled
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Cancelled'),
                                      onTap: () => Navigator.of(context)
                                          .pop(SessionStatus.cancelled),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              );
                            },
                          );

                          if (!mounted) return;
                          if (result != _statusFilter) {
                            setState(() => _statusFilter = result);
                          }
                        },
                      ),
                      // Sort
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sort),
                        label: Text(_sortKey),
                        onPressed: () async {
                          final options = [
                            'Start time (newest first)',
                            'Team (A-Z)',
                            'Ideas (most first)',
                          ];
                          final result =
                              await showModalBottomSheet<String>(
                            context: context,
                            showDragHandle: true,
                            builder: (_) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const ListTile(
                                      title: Text(
                                        'Sort sessions',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    for (final opt in options)
                                      ListTile(
                                        leading: _sortKey == opt
                                            ? const Icon(Icons.check)
                                            : const SizedBox(width: 24),
                                        title: Text(opt),
                                        onTap: () =>
                                            Navigator.of(context).pop(opt),
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
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Küçük summary chip card
                  Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(
      color: theme.colorScheme.outlineVariant,
    ),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 8, // biraz daralttık
      vertical: 8,
    ),
    child: Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _SummaryChip(
              icon: Icons.list_alt,
              label: 'Total sessions',
              value: '$_totalSessions',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _SummaryChip(
              icon: Icons.live_tv,
              label: 'Live now',
              value: '$_liveSessions',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _SummaryChip(
              icon: Icons.lightbulb_outline,
              label: 'Total ideas',
              value: '$_totalIdeas',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _SummaryChip(
              icon: Icons.groups,
              label: 'Teams',
              value: '$_totalTeams',
            ),
          ),
        ),
      ],
    ),
  ),
),

                ],
              ),
            ),
            const Divider(height: 1),
            // Liste
            Expanded(
              child: sessions.isEmpty
                  ? const Center(
                      child: Text(
                        'No sessions for this event yet.\n'
                        'Teams will appear here once they start 6-3-5.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final s = sessions[index];
                        return _SessionCard(
                          session: s,
                          statusLabel: _statusLabel(s.status),
                          statusChipColor:
                              _statusChipColor(s.status, context),
                          statusTextColor:
                              _statusTextColor(s.status, context),
                          formattedStart: _formatDateTime(
                            s.startedAt ?? s.scheduledFor,
                          ),
                          formattedEnd: _formatDateTime(s.endedAt),
                          onTap: () => _openDetailsSheet(s),
                          onActionSelected: (action) {
                            if (action == 'Open live monitor') {
                              _showSnack(
                                'Open live monitor for "${s.teamName}" (dummy).',
                              );
                            } else if (action ==
                                'End session (force)') {
                              _showSnack(
                                'Force end session #${s.id} (dummy).',
                              );
                            } else if (action == 'Cancel session') {
                              _showSnack(
                                'Cancel scheduled session #${s.id} (dummy).',
                              );
                            } else if (action == 'Delete record') {
                              _showSnack(
                                'Delete session record #${s.id} (dummy).',
                              );
                            } else if (action ==
                                'Start session now') {
                              _showSnack(
                                'Start session #${s.id} now (EM override – dummy).',
                              );
                            } else if (action ==
                                'Pause session') {
                              _showSnack(
                                'Pause live session #${s.id} (EM override – dummy).',
                              );
                            } else if (action ==
                                'View AI summary') {
                              _showSnack(
                                'Open AI summary for "${s.teamName}" (dummy – Reports tab).',
                              );
                            } else if (action ==
                                'Request AI summary') {
                              _showSnack(
                                'Request AI summary for session #${s.id} (dummy – will call ChatGPT).',
                              );
                            } else if (action ==
                                'View in Reports') {
                              _showSnack(
                                'Open Reports view for session #${s.id} (dummy).',
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---- Yardımcı widget’lar ----

class _SessionCard extends StatelessWidget {
  final UiEventSession session;
  final String statusLabel;
  final Color statusChipColor;
  final Color statusTextColor;
  final String formattedStart;
  final String formattedEnd;
  final VoidCallback onTap;
  final void Function(String action) onActionSelected;

  const _SessionCard({
    required this.session,
    required this.statusLabel,
    required this.statusChipColor,
    required this.statusTextColor,
    required this.formattedStart,
    required this.formattedEnd,
    required this.onTap,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = session.totalRounds == 0
        ? 0.0
        : (session.completedRounds / session.totalRounds)
            .clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Card(
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
              // Üst satır
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.teamName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.topic_outlined, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                session.topicTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Leader: ${session.teamLeaderName} • '
                                '${session.participantsCount} participants',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: statusChipColor,
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: onActionSelected,
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[];

                      // AI summary / reports
                      if (session.aiSummaryReady) {
                        items.add(
                          const PopupMenuItem(
                            value: 'View AI summary',
                            child: Text('View AI summary'),
                          ),
                        );
                      } else if (session.status ==
                          SessionStatus.completed) {
                        items.add(
                          const PopupMenuItem(
                            value: 'Request AI summary',
                            child: Text('Request AI summary'),
                          ),
                        );
                      }

                      items.add(
                        const PopupMenuItem(
                          value: 'View in Reports',
                          child: Text('View in Reports'),
                        ),
                      );

                      if (session.status == SessionStatus.scheduled) {
                        items.addAll([
                          const PopupMenuItem(
                            value: 'Start session now',
                            child: Text('Start session now'),
                          ),
                          const PopupMenuItem(
                            value: 'Cancel session',
                            child: Text('Cancel session'),
                          ),
                        ]);
                      }

                      if (session.status == SessionStatus.live) {
                        items.addAll([
                          const PopupMenuItem(
                            value: 'Open live monitor',
                            child: Text('Open live monitor'),
                          ),
                          const PopupMenuItem(
                            value: 'Pause session',
                            child: Text('Pause session'),
                          ),
                          const PopupMenuItem(
                            value: 'End session (force)',
                            child: Text('End session (force)'),
                          ),
                        ]);
                      }

                      items.add(
                        const PopupMenuItem(
                          value: 'Delete record',
                          child: Text(
                            'Delete record',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      );

                      return items;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress & ideas
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rounds ${session.completedRounds}/${session.totalRounds}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SmallPill(
                    icon: Icons.lightbulb_outline,
                    label: '${session.ideasCount} ideas',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Zaman bilgisi
              Row(
                children: [
                  const Icon(Icons.play_arrow, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    formattedStart,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.stop, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    formattedEnd,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
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

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
