import 'package:flutter/material.dart';

import 'event_teams_screen.dart';
import 'event_topics_screen.dart';
import 'event_sessions_screen.dart';

/// ---- UI MODEL (şimdilik sadece frontend için) ----
enum EventStatus { planned, live, completed, archived }

class UiEventSummary {
  final int id;
  final String name;
  final String description;
  final String ownerName;
  final DateTime startDate;
  final DateTime endDate;
  final EventStatus status;
  final int topicsCount;
  final int teamsCount;
  final int sessionsCount;
  final int totalIdeas;

  const UiEventSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.topicsCount,
    required this.teamsCount,
    required this.sessionsCount,
    required this.totalIdeas,
  });

  // 🔹 BUNU EKLE
  UiEventSummary copyWith({
    String? name,
    String? description,
    String? ownerName,
    DateTime? startDate,
    DateTime? endDate,
    EventStatus? status,
    int? topicsCount,
    int? teamsCount,
    int? sessionsCount,
    int? totalIdeas,
  }) {
    return UiEventSummary(
      id: id, // id değişmiyor
      name: name ?? this.name,
      description: description ?? this.description,
      ownerName: ownerName ?? this.ownerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      topicsCount: topicsCount ?? this.topicsCount,
      teamsCount: teamsCount ?? this.teamsCount,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      totalIdeas: totalIdeas ?? this.totalIdeas,
    );
  }
}


/// ---- DUMMY DATA (initial) ----
final List<UiEventSummary> _dummyEvents = [
  UiEventSummary(
    id: 1,
    name: 'Q3 Innovation Ideathon',
    description:
        'Company-wide ideathon to generate ideas for Q3 product and growth initiatives.',
    ownerName: 'Alex Morgan',
    startDate: DateTime(2025, 7, 10),
    endDate: DateTime(2025, 7, 12),
    status: EventStatus.live,
    topicsCount: 6,
    teamsCount: 8,
    sessionsCount: 12,
    totalIdeas: 320,
  ),
  UiEventSummary(
    id: 2,
    name: 'UX Redesign 2.0 Workshop',
    description:
        'Cross-functional workshop focused on improving onboarding and mobile UX.',
    ownerName: 'Sarah Lee',
    startDate: DateTime(2025, 6, 20),
    endDate: DateTime(2025, 6, 20),
    status: EventStatus.completed,
    topicsCount: 4,
    teamsCount: 5,
    sessionsCount: 7,
    totalIdeas: 185,
  ),
  UiEventSummary(
    id: 3,
    name: 'Customer Centricity Sprint',
    description:
        'Two-day sprint to rethink support flows and retention strategies.',
    ownerName: 'Michael Chen',
    startDate: DateTime(2025, 8, 5),
    endDate: DateTime(2025, 8, 6),
    status: EventStatus.planned,
    topicsCount: 3,
    teamsCount: 4,
    sessionsCount: 0,
    totalIdeas: 0,
  ),
  UiEventSummary(
    id: 4,
    name: 'Internal Hackathon 2024 Review',
    description:
        'Review and follow-up for last year’s hackathon projects and learnings.',
    ownerName: 'HR & Ops',
    startDate: DateTime(2024, 11, 1),
    endDate: DateTime(2024, 11, 2),
    status: EventStatus.archived,
    topicsCount: 5,
    teamsCount: 10,
    sessionsCount: 15,
    totalIdeas: 420,
  ),
];

/// ---- EKRAN ----
/// Bu ekran Event Manager için tüm ideathon / workshop event’lerini listeleyen ana ekran.
class EventsOverviewScreen extends StatefulWidget {
  const EventsOverviewScreen({super.key});

  @override
  State<EventsOverviewScreen> createState() => _EventsOverviewScreenState();
}

class _EventsOverviewScreenState extends State<EventsOverviewScreen> {
  // Artık filtreler bu liste üzerinden çalışıyor
  late List<UiEventSummary> _allEvents;

  String _searchQuery = '';
  EventStatus? _statusFilter; // null -> All
  String _sortKey = 'Date (newest first)';

  @override
  void initState() {
    super.initState();
    _allEvents = List<UiEventSummary>.from(_dummyEvents);
  }

  int get _nextEventId {
    var maxId = 0;
    for (final e in _allEvents) {
      if (e.id > maxId) maxId = e.id;
    }
    return maxId + 1;
  }

  List<UiEventSummary> get _filteredEvents {
    var list = List<UiEventSummary>.from(_allEvents);

    // Arama
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.ownerName.toLowerCase().contains(q);
      }).toList();
    }

    // Status filtresi
    if (_statusFilter != null) {
      list = list.where((e) => e.status == _statusFilter).toList();
    }

    // Sıralama
    switch (_sortKey) {
      case 'Name (A-Z)':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Ideas (most first)':
        list.sort((b, a) => a.totalIdeas.compareTo(b.totalIdeas));
        break;
      case 'Date (newest first)':
      default:
        list.sort((b, a) => a.startDate.compareTo(b.startDate));
        break;
    }

    return list;
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final sDay = start.day.toString().padLeft(2, '0');
    final eDay = end.day.toString().padLeft(2, '0');
    final sMonth = months[start.month - 1];
    final eMonth = months[end.month - 1];
    final sYear = start.year.toString();
    final eYear = end.year.toString();

    if (sYear == eYear && sMonth == eMonth) {
      // Örn: Jul 10–12, 2025
      return '$sMonth $sDay–$eDay, $sYear';
    } else {
      return '$sMonth $sDay, $sYear – $eMonth $eDay, $eYear';
    }
  }

  String _statusLabel(EventStatus status) {
    switch (status) {
      case EventStatus.planned:
        return 'Planned';
      case EventStatus.live:
        return 'Live';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.archived:
        return 'Archived';
    }
  }

  Color _statusChipColor(EventStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case EventStatus.planned:
        return theme.colorScheme.primary.withOpacity(0.10);
      case EventStatus.live:
        return Colors.green.withOpacity(0.12);
      case EventStatus.completed:
        return Colors.blueGrey.withOpacity(0.12);
      case EventStatus.archived:
        return Colors.grey.withOpacity(0.18);
    }
  }

  Color _statusTextColor(EventStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case EventStatus.planned:
        return theme.colorScheme.primary;
      case EventStatus.live:
        return Colors.green[700] ?? Colors.green;
      case EventStatus.completed:
        return Colors.blueGrey[700] ?? Colors.blueGrey;
      case EventStatus.archived:
        return Colors.grey[800] ?? Colors.grey;
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showCreateOrEditDialog({UiEventSummary? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final ownerController =
        TextEditingController(text: existing?.ownerName ?? '');

    final result = await showDialog<UiEventSummary>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(existing == null ? 'Create event' : 'Edit event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Event name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Owner name',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dates, status and metrics are dummy for now and will be\n'
                  'connected to backend in a later phase.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim().isEmpty
                    ? 'Untitled event'
                    : nameController.text.trim();
                final desc = descController.text.trim().isEmpty
                    ? 'No description yet.'
                    : descController.text.trim();
                final owner = ownerController.text.trim().isEmpty
                    ? 'Unknown owner'
                    : ownerController.text.trim();

                if (existing == null) {
                  final now = DateTime.now();
                  Navigator.of(context).pop(
                    UiEventSummary(
                      id: _nextEventId,
                      name: name,
                      description: desc,
                      ownerName: owner,
                      startDate: now,
                      endDate: now.add(const Duration(days: 1)),
                      status: EventStatus.planned,
                      topicsCount: 0,
                      teamsCount: 0,
                      sessionsCount: 0,
                      totalIdeas: 0,
                    ),
                  );
                } else {
                  Navigator.of(context).pop(
                    existing.copyWith(
                      name: name,
                      description: desc,
                      ownerName: owner,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        if (existing == null) {
          _allEvents.add(result);
        } else {
          final idx =
              _allEvents.indexWhere((e) => e.id == existing.id);
          if (idx != -1) {
            _allEvents[idx] = result;
          }
        }
      });
      _showSnack(
        context,
        existing == null ? 'Event created (dummy).' : 'Event updated (dummy).',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final events = _filteredEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          TextButton.icon(
            onPressed: () => _showCreateOrEditDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create event'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search + filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search events by name or owner',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result =
                              await showModalBottomSheet<EventStatus?>(
                            context: context,
                            showDragHandle: true,
                            builder: (context) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const ListTile(
                                      title: Text(
                                        'Filter by status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    ListTile(
                                      leading: _statusFilter == null
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('All statuses'),
                                      onTap: () =>
                                          Navigator.of(context).pop(null),
                                    ),
                                    const Divider(height: 1),
                                    ListTile(
                                      leading: _statusFilter ==
                                              EventStatus.planned
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Planned'),
                                      onTap: () => Navigator.of(context)
                                          .pop(EventStatus.planned),
                                    ),
                                    ListTile(
                                      leading: _statusFilter ==
                                              EventStatus.live
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Live'),
                                      onTap: () => Navigator.of(context)
                                          .pop(EventStatus.live),
                                    ),
                                    ListTile(
                                      leading: _statusFilter ==
                                              EventStatus.completed
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Completed'),
                                      onTap: () => Navigator.of(context)
                                          .pop(EventStatus.completed),
                                    ),
                                    ListTile(
                                      leading: _statusFilter ==
                                              EventStatus.archived
                                          ? const Icon(Icons.check)
                                          : const SizedBox(width: 24),
                                      title: const Text('Archived'),
                                      onTap: () => Navigator.of(context)
                                          .pop(EventStatus.archived),
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
                        icon: const Icon(Icons.filter_list),
                        label: Text(
                          _statusFilter == null
                              ? 'All statuses'
                              : _statusLabel(_statusFilter!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final options = [
                            'Date (newest first)',
                            'Name (A-Z)',
                            'Ideas (most first)',
                          ];
                          final result =
                              await showModalBottomSheet<String>(
                            context: context,
                            showDragHandle: true,
                            builder: (context) {
                              return SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const ListTile(
                                      title: Text(
                                        'Sort events',
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
                        icon: const Icon(Icons.sort),
                        label: Text(_sortKey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Event list
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'No events match your filters.\nTry changing search text or status.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _EventCard(
                        event: event,
                        dateRange: _formatDateRange(event.startDate, event.endDate),
                        statusLabel: _statusLabel(event.status),
                        statusChipColor: _statusChipColor(event.status, context),
                        statusTextColor: _statusTextColor(event.status, context),
                        onActionSelected: (action) async {
                          // 🔹 Manage topics
                          if (action == 'Manage topics') {
                            final updatedTopicsCount =
                                await Navigator.of(context).push<int>(
                              MaterialPageRoute(
                                builder: (_) => EventTopicsScreen(
                                  eventId: event.id,
                                  eventName: event.name,
                                  initialTopicsCount: event.topicsCount,
                                ),
                              ),
                            );

                            if (updatedTopicsCount != null) {
                              setState(() {
                                final idx =
                                    _dummyEvents.indexWhere((e) => e.id == event.id);
                                if (idx != -1) {
                                  _dummyEvents[idx] = _dummyEvents[idx].copyWith(
                                    topicsCount: updatedTopicsCount,
                                  );
                                }
                              });
                            }
                            return;
                          }

                          // 🔹 Manage teams
                          if (action == 'Manage teams') {
                            final updatedTeamsCount =
                                await Navigator.of(context).push<int>(
                              MaterialPageRoute(
                                builder: (_) => EventTeamsScreen(
                                  eventId: event.id,
                                  eventName: event.name,
                                  initialTeamsCount: event.teamsCount,
                                ),
                              ),
                            );

                            if (updatedTeamsCount != null) {
                              setState(() {
                                final idx =
                                    _dummyEvents.indexWhere((e) => e.id == event.id);
                                if (idx != -1) {
                                  _dummyEvents[idx] = _dummyEvents[idx].copyWith(
                                    teamsCount: updatedTeamsCount,
                                  );
                                }
                              });
                            }
                            return;
                          }
                          if (action == 'View sessions') {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EventSessionsScreen(
                                  eventId: event.id,
                                  eventName: event.name,
                                ),
                              ),
                            );

                            // Geri döndüğünde istersen refresh yapabilirsin:
                            setState(() {}); // backend bağlandığında sessions sayısını güncellemek için kullanılabilir
                            return;
                          }


                          // 🔹 Diğer işlemler (Edit / Archive / Delete vs.)
                          _showSnack(
                            context,
                            '"$action" for "${event.name}" (dummy).',
                          );
                        },
                      );

                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemCount: events.length,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir event kartı
class _EventCard extends StatelessWidget {
  final UiEventSummary event;
  final String dateRange;
  final String statusLabel;
  final Color statusChipColor;
  final Color statusTextColor;
  final void Function(String action) onActionSelected;

  const _EventCard({
    required this.event,
    required this.dateRange,
    required this.statusLabel,
    required this.statusChipColor,
    required this.statusTextColor,
    required this.onActionSelected,
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
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: ad + status + menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusChipColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.status == EventStatus.live
                            ? Icons.circle
                            : Icons.circle_outlined,
                        size: 10,
                        color: statusTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: onActionSelected,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'Edit event',
                      child: Text('Edit event'),
                    ),
                    PopupMenuItem(
                      value: 'Archive event',
                      child: Text('Archive event'),
                    ),
                    PopupMenuItem(
                      value: 'Delete event',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              event.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Tarih + owner
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(
                  dateRange,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.person, size: 14),
                const SizedBox(width: 4),
                Text(
                  event.ownerName,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Küçük metrikler (topics / teams / sessions / ideas)
            // Küçük metrikler (topics / teams / sessions / ideas)
            // Row yerine Wrap kullanıyoruz ki dar ekranda alt satıra geçebilsin.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _MetricPill(
                  icon: Icons.topic_outlined,
                  label: '${event.topicsCount} topics',
                ),
                _MetricPill(
                  icon: Icons.group_outlined,
                  label: '${event.teamsCount} teams',
                ),
                _MetricPill(
                  icon: Icons.timer_outlined,
                  label: '${event.sessionsCount} sessions',
                ),
                _MetricPill(
                  icon: Icons.lightbulb_outline,
                  label: '${event.totalIdeas} ideas',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onActionSelected('Manage topics'),
                  icon: const Icon(Icons.topic),
                  label: const Text('Manage topics'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onActionSelected('Manage teams'),
                  icon: const Icon(Icons.group),
                  label: const Text('Manage teams'),
                ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventSessionsScreen(
                            eventId: event.id,
                            eventName: event.name,
                          ),
                        ),
                      );
                    },
                  label: const Text('View sessions'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
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
