import 'package:flutter/material.dart';

/// ----------------------------------------------
/// UI MODELLERİ
/// ----------------------------------------------

class UiEventReportSummary {
  final int eventId;
  final String eventName;
  final DateTime startDate;
  final DateTime endDate;
  final int topicsCount;
  final int teamsCount;
  final int sessionsCount;
  final int completedSessions;
  final int liveSessions;
  final int cancelledSessions;
  final int ideasCount;
  final int aiSummariesReady;
  final DateTime lastActivityAt;

  const UiEventReportSummary({
    required this.eventId,
    required this.eventName,
    required this.startDate,
    required this.endDate,
    required this.topicsCount,
    required this.teamsCount,
    required this.sessionsCount,
    required this.completedSessions,
    required this.liveSessions,
    required this.cancelledSessions,
    required this.ideasCount,
    required this.aiSummariesReady,
    required this.lastActivityAt,
  });
}

enum ReportTimeRange { allTime, last7Days, last30Days }

/// Şimdilik backend yerine kullanılan dummy data.
 List<UiEventReportSummary> kDummyEventReports = [
  UiEventReportSummary(
    eventId: 1,
    eventName: 'Q3 Innovation Ideathon',
    startDate: DateTime(2025, 7, 1),
    endDate: DateTime(2025, 7, 7),
    topicsCount: 3,
    teamsCount: 6,
    sessionsCount: 8,
    completedSessions: 6,
    liveSessions: 1,
    cancelledSessions: 1,
    ideasCount: 220,
    aiSummariesReady: 4,
    lastActivityAt: DateTime(2025, 7, 7, 17, 45),
  ),
  UiEventReportSummary(
    eventId: 2,
    eventName: 'Customer Centricity Sprint',
    startDate: DateTime(2025, 6, 20),
    endDate: DateTime(2025, 6, 24),
    topicsCount: 2,
    teamsCount: 4,
    sessionsCount: 5,
    completedSessions: 4,
    liveSessions: 0,
    cancelledSessions: 1,
    ideasCount: 140,
    aiSummariesReady: 3,
    lastActivityAt: DateTime(2025, 6, 24, 16, 10),
  ),
  UiEventReportSummary(
    eventId: 3,
    eventName: 'UX Redesign 2.0 Workshop',
    startDate: DateTime(2025, 5, 10),
    endDate: DateTime(2025, 5, 11),
    topicsCount: 1,
    teamsCount: 3,
    sessionsCount: 3,
    completedSessions: 3,
    liveSessions: 0,
    cancelledSessions: 0,
    ideasCount: 75,
    aiSummariesReady: 2,
    lastActivityAt: DateTime(2025, 5, 11, 14, 30),
  ),
];

/// ----------------------------------------------
/// REPORTS SCREEN – EVENT MANAGER
/// ----------------------------------------------

class ReportsScreen extends StatefulWidget {
  /// Örneğin Sessions ekranından "View in Reports" ile
  /// belirli bir event için filtreleyerek açmak istersen kullan.
  final int? initialEventId;

  const ReportsScreen({
    super.key,
    this.initialEventId,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<UiEventReportSummary> _reports = [];

  bool _isLoading = true;
  String? _loadError;

  String _searchQuery = '';
  int? _eventFilterId; // null -> All events
  ReportTimeRange _timeRange = ReportTimeRange.allTime;
  String _sortKey = 'Ideas (most first)';

  @override
  void initState() {
    super.initState();
    _eventFilterId = widget.initialEventId;
    _loadReportsFromBackend();
  }

  /// Buraya gerçek backend çağrısı gelecek.
  Future<List<UiEventReportSummary>> _fetchReportsFromBackend() async {
    // Örnek: REST API / GraphQL / Supabase:
    // final response = await http.get(...);
    // parse -> List<UiEventReportSummary>
    await Future.delayed(const Duration(milliseconds: 400));
    return kDummyEventReports;
  }

  Future<void> _loadReportsFromBackend() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await _fetchReportsFromBackend();
      setState(() {
        _reports = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load reports.';
        _isLoading = false;
      });
    }
  }

  List<UiEventReportSummary> get _filteredReports {
    var list = List<UiEventReportSummary>.from(_reports);

    // Event filter
    if (_eventFilterId != null) {
      list = list.where((r) => r.eventId == _eventFilterId).toList();
    }

    // Search (event name)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((r) => r.eventName.toLowerCase().contains(q))
          .toList();
    }

    // Time range filter (lastActivityAt üzerinden)
    if (_timeRange != ReportTimeRange.allTime) {
      final now = DateTime.now();
      Duration delta;
      if (_timeRange == ReportTimeRange.last7Days) {
        delta = const Duration(days: 7);
      } else {
        delta = const Duration(days: 30);
      }
      final threshold = now.subtract(delta);
      list = list.where((r) => r.lastActivityAt.isAfter(threshold)).toList();
    }

    // Sort
    switch (_sortKey) {
      case 'Sessions (most first)':
        list.sort((b, a) => a.sessionsCount.compareTo(b.sessionsCount));
        break;
      case 'Event (A-Z)':
        list.sort((a, b) => a.eventName.compareTo(b.eventName));
        break;
      case 'Ideas (most first)':
      default:
        list.sort((b, a) => a.ideasCount.compareTo(b.ideasCount));
        break;
    }

    return list;
  }

  int get _totalEvents => _reports.length;

  int get _totalSessions =>
      _reports.fold<int>(0, (sum, r) => sum + r.sessionsCount);

  int get _totalIdeas =>
      _reports.fold<int>(0, (sum, r) => sum + r.ideasCount);

  int get _totalTeams =>
      _reports.fold<int>(0, (sum, r) => sum + r.teamsCount);

  List<String> get _allEventNames {
    final names = <String, int>{};
    for (final r in _reports) {
      names[r.eventName] = r.eventId;
    }
    final list = names.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return list.map((e) => e.key).toList();
  }

  int? _eventIdForName(String name) {
    if (_reports.isEmpty) return null;
    final matches =
        _reports.where((r) => r.eventName == name).toList();
    if (matches.isEmpty) return null;
    return matches.first.eventId;
  }

  String _formatDateRange(DateTime start, DateTime end) {
    String two(int v) => v.toString().padLeft(2, '0');
    final startStr =
        '${two(start.day)}.${two(start.month)}.${start.year}';
    final endStr = '${two(end.day)}.${two(end.month)}.${end.year}';
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return startStr;
    }
    return '$startStr – $endStr';
  }

  String _formatLastActivity(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openEventFilterSheet() async {
    final eventNames = _allEventNames;

    final result = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final currentId = _eventFilterId;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Filter by event',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: currentId == null
                    ? const Icon(Icons.check)
                    : const SizedBox(width: 24),
                title: const Text('All events'),
                onTap: () => Navigator.of(context).pop(null),
              ),
              const Divider(height: 1),
              for (final name in eventNames)
                ListTile(
                  leading: (_eventIdForName(name) == currentId)
                      ? const Icon(Icons.check)
                      : const SizedBox(width: 24),
                  title: Text(name),
                  onTap: () => Navigator.of(context).pop(name),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (result == null) {
      setState(() => _eventFilterId = null);
    } else {
      final id = _eventIdForName(result);
      if (id != null && id != _eventFilterId) {
        setState(() => _eventFilterId = id);
      }
    }
  }

  Future<void> _openTimeRangeSheet() async {
    final result = await showModalBottomSheet<ReportTimeRange>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final current = _timeRange;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Time range',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              RadioListTile<ReportTimeRange>(
                title: const Text('All time'),
                value: ReportTimeRange.allTime,
                groupValue: current,
                onChanged: (v) =>
                    Navigator.of(context).pop(v ?? current),
              ),
              RadioListTile<ReportTimeRange>(
                title: const Text('Last 7 days'),
                value: ReportTimeRange.last7Days,
                groupValue: current,
                onChanged: (v) =>
                    Navigator.of(context).pop(v ?? current),
              ),
              RadioListTile<ReportTimeRange>(
                title: const Text('Last 30 days'),
                value: ReportTimeRange.last30Days,
                groupValue: current,
                onChanged: (v) =>
                    Navigator.of(context).pop(v ?? current),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (result != null && result != _timeRange) {
      setState(() => _timeRange = result);
    }
  }

  Future<void> _openSortSheet() async {
    final options = [
      'Ideas (most first)',
      'Sessions (most first)',
      'Event (A-Z)',
    ];

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
                  'Sort reports',
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

  String _timeRangeLabel(ReportTimeRange range) {
    switch (range) {
      case ReportTimeRange.allTime:
        return 'All time';
      case ReportTimeRange.last7Days:
        return 'Last 7 days';
      case ReportTimeRange.last30Days:
        return 'Last 30 days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadReportsFromBackend,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final reports = _filteredReports;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Column(
        children: [
          // ---- ÜST ARAMA + FİLTRELER ----
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: 'Search by event name',
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
                    OutlinedButton.icon(
                      icon: const Icon(Icons.event),
                      label: Text(
                        _eventFilterId == null
                            ? 'All events'
                            : _reports
                                .firstWhere(
                                  (r) => r.eventId == _eventFilterId,
                                  orElse: () => _reports.first,
                                )
                                .eventName,
                      ),
                      onPressed: _openEventFilterSheet,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(_timeRangeLabel(_timeRange)),
                      onPressed: _openTimeRangeSheet,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.sort),
                      label: Text(_sortKey),
                      onPressed: _openSortSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ---- OVERVIEW SUMMARY CARD ----
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
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _OverviewPill(
                            icon: Icons.event_note,
                            value: '$_totalEvents',
                            label: 'Events',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _OverviewPill(
                            icon: Icons.list_alt,
                            value: '$_totalSessions',
                            label: 'Sessions',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _OverviewPill(
                            icon: Icons.lightbulb_outline,
                            value: '$_totalIdeas',
                            label: 'Ideas',
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _OverviewPill(
                            icon: Icons.groups_outlined,
                            value: '$_totalTeams',
                            label: 'Teams',
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

          // ---- LİSTE ----
          Expanded(
            child: reports.isEmpty
                ? const Center(
                    child: Text(
                      'No reports for the selected filters.\n'
                      'Try changing event or time range.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      return _EventReportCard(
                        report: r,
                        dateRange: _formatDateRange(
                          r.startDate,
                          r.endDate,
                        ),
                        lastActivity: _formatLastActivity(r.lastActivityAt),
                        onViewBreakdown: () {
                          _showSnack(
                            'Open detailed breakdown for "${r.eventName}" (dummy).',
                          );
                        },
                        onViewAiSummary: r.aiSummariesReady > 0
                            ? () {
                                _showSnack(
                                  'Open AI summaries for "${r.eventName}" (dummy).',
                                );
                              }
                            : null,
                        onExportIdeas: () {
                          _showSnack(
                            'Export ideas for "${r.eventName}" (dummy export).',
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------
/// YARDIMCI WIDGET’LAR
/// ----------------------------------------------

class _OverviewPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _OverviewPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
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

class _EventReportCard extends StatelessWidget {
  final UiEventReportSummary report;
  final String dateRange;
  final String lastActivity;
  final VoidCallback onViewBreakdown;
  final VoidCallback? onViewAiSummary;
  final VoidCallback onExportIdeas;

  const _EventReportCard({
    required this.report,
    required this.dateRange,
    required this.lastActivity,
    required this.onViewBreakdown,
    required this.onViewAiSummary,
    required this.onExportIdeas,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAi = report.aiSummariesReady > 0;

    return Card(
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
            // Başlık + AI pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.eventName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasAi)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${report.aiSummariesReady} AI summaries',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateRange,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 8),

            // Metrikler
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _MetricChip(
                  icon: Icons.list_alt,
                  label: '${report.sessionsCount} sessions',
                ),
                _MetricChip(
                  icon: Icons.check_circle_outline,
                  label: '${report.completedSessions} completed',
                ),
                _MetricChip(
                  icon: Icons.live_tv,
                  label: '${report.liveSessions} live',
                ),
                _MetricChip(
                  icon: Icons.lightbulb_outline,
                  label: '${report.ideasCount} ideas',
                ),
                _MetricChip(
                  icon: Icons.groups_outlined,
                  label: '${report.teamsCount} teams',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Last activity: $lastActivity',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewBreakdown,
                  icon: const Icon(Icons.table_view),
                  label: const Text('View breakdown'),
                ),
                if (hasAi)
                  OutlinedButton.icon(
                    onPressed: onViewAiSummary,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('View AI summary'),
                  ),
                OutlinedButton.icon(
                  onPressed: onExportIdeas,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export ideas'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
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
