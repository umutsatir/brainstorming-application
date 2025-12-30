import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repository/event_manager_repository.dart';
import 'event_teams_screen.dart';
import 'event_topics_screen.dart';
import 'event_sessions_screen.dart';

/// Bu ekran Event Manager için tüm ideathon / workshop event’lerini listeleyen ana ekran.
class EventsOverviewScreen extends ConsumerStatefulWidget {
  const EventsOverviewScreen({super.key});

  @override
  ConsumerState<EventsOverviewScreen> createState() =>
      _EventsOverviewScreenState();
}

class _EventsOverviewScreenState
    extends ConsumerState<EventsOverviewScreen> {
  /// Backend’ten gelen event’lerin local kopyası
  List<UiEventSummary> _allEvents = [];

  bool _isLoading = false;
  Object? _error;

  String _searchQuery = '';
  EventStatus? _statusFilter; // null -> All
  String _sortKey = 'Date (newest first)';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(eventManagerRepositoryProvider);
      final events = await repo.getAllEvents();
      setState(() {
        _allEvents = events;
      });
    } catch (e) {
      setState(() {
        _error = e;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  /// Create / Edit dialog – sadece form verisini döner,
  /// backend çağrısını dışarıda yapıyoruz.
  Future<Map<String, String>?> _showCreateOrEditDialog({
    UiEventSummary? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController =
        TextEditingController(text: existing?.description ?? '');
    final ownerController =
        TextEditingController(text: existing?.ownerName ?? '');

    final result = await showDialog<Map<String, String>>(
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
                  'Dates, status and metrics are currently controlled by the backend.\n'
                  'This dialog only edits basic info.',
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

                Navigator.of(context).pop(<String, String>{
                  'name': name,
                  'description': desc,
                  'ownerName': owner,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<void> _handleCreateEvent() async {
    final form = await _showCreateOrEditDialog();
    if (form == null) return;

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      await repo.createEvent(
        name: form['name']!,
        description: form['description']!,
      );
      _showSnack(context, 'Event created.');
      await _loadEvents();
    } catch (e) {
      _showSnack(context, 'Failed to create event: $e');
    }
  }

  Future<void> _handleEditEvent(UiEventSummary event) async {
    final form = await _showCreateOrEditDialog(existing: event);
    if (form == null) return;

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      await repo.updateEvent(
        eventId: event.id,
        name: form['name'],
        description: form['description'],
      );
      _showSnack(context, 'Event updated.');
      await _loadEvents();
    } catch (e) {
      _showSnack(context, 'Failed to update event: $e');
    }
  }

  Future<void> _handleArchiveEvent(UiEventSummary event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive event'),
        content: Text(
          'Are you sure you want to archive "${event.name}"?\n'
          'Participants will no longer be able to join new sessions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      await repo.archiveEvent(event.id);
      _showSnack(context, 'Event archived.');
      await _loadEvents();
    } catch (e) {
      _showSnack(context, 'Failed to archive event: $e');
    }
  }

  Future<void> _handleDeleteEvent(UiEventSummary event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event'),
        content: Text(
          'This will permanently delete "${event.name}" and its sessions.\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      await repo.deleteEvent(event.id);
      _showSnack(context, 'Event deleted.');
      await _loadEvents();
    } catch (e) {
      _showSnack(context, 'Failed to delete event: $e');
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
            onPressed: _handleCreateEvent,
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
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Failed to load events.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _loadEvents,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (events.isEmpty) {
                  return const Center(
                    child: Text(
                      'No events match your filters.\nTry changing search text or status.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _EventCard(
                      event: event,
                      dateRange:
                          _formatDateRange(event.startDate, event.endDate),
                      statusLabel: _statusLabel(event.status),
                      statusChipColor:
                          _statusChipColor(event.status, context),
                      statusTextColor:
                          _statusTextColor(event.status, context),
                      onActionSelected: (action) async {
                        // ---- Edit / Archive / Delete ----
                        if (action == 'Edit event') {
                          await _handleEditEvent(event);
                          return;
                        }
                        if (action == 'Archive event') {
                          await _handleArchiveEvent(event);
                          return;
                        }
                        if (action == 'Delete event') {
                          await _handleDeleteEvent(event);
                          return;
                        }

                        // ---- Manage topics ----
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
                              final idx = _allEvents
                                  .indexWhere((e) => e.id == event.id);
                              if (idx != -1) {
                                _allEvents[idx] = _allEvents[idx].copyWith(
                                  topicsCount: updatedTopicsCount,
                                );
                              }
                            });
                          }
                          return;
                        }

                        // ---- Manage teams ----
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
                              final idx = _allEvents
                                  .indexWhere((e) => e.id == event.id);
                              if (idx != -1) {
                                _allEvents[idx] = _allEvents[idx].copyWith(
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
                          return;
                        }

                        // Diğer aksiyonlar olursa
                        _showSnack(
                          context,
                          '"$action" for "${event.name}" (not implemented).',
                        );
                      },
                    );
                  },
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemCount: events.length,
                );
              },
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
                  onPressed: () => onActionSelected('View sessions'),
                  icon: const Icon(Icons.table_view),
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
