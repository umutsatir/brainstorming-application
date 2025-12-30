import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repository/event_manager_repository.dart';

class EventTopicsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventName;
  final int initialTopicsCount; // Events overview’dan gelen sayı

  const EventTopicsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.initialTopicsCount,
  });

  @override
  ConsumerState<EventTopicsScreen> createState() =>
      _EventTopicsScreenState();
}

class _EventTopicsScreenState extends ConsumerState<EventTopicsScreen> {
  String _searchQuery = '';
  TopicStatus? _statusFilter; // null -> All
  String _sortKey = 'Relevance';

  bool _isLoading = false;
  String? _errorMessage;

  List<UiTopicSummary> _allTopics = [];
  Set<int> _assignedIds = <int>{};

  int get _assignedCount => _assignedIds.length;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(eventManagerRepositoryProvider);
      final allTopics = await repo.getAllTopics();
      final assignedIds =
          await repo.getAssignedTopicIds(widget.eventId);

      setState(() {
        _allTopics = allTopics;
        _assignedIds = assignedIds;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Arama + filtre + sort sonrası tüm topicler
  List<UiTopicSummary> get _filteredAll {
    var list = List<UiTopicSummary>.from(_allTopics);

    // Arama
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.ownerName.toLowerCase().contains(q))
          .toList();
    }

    // Status filtresi
    if (_statusFilter != null) {
      list = list.where((t) => t.status == _statusFilter).toList();
    }

    // Sıralama
    switch (_sortKey) {
      case 'Title (A-Z)':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Most ideas':
        list.sort((b, a) => a.ideasCount.compareTo(b.ideasCount));
        break;
      case 'Relevance':
      default:
        // Basit relevance: assigned olanlar üstte
        list.sort((b, a) {
          final aAssigned = _assignedIds.contains(a.id);
          final bAssigned = _assignedIds.contains(b.id);
          if (aAssigned == bAssigned) {
            return a.createdAt.compareTo(b.createdAt);
          }
          return aAssigned ? -1 : 1;
        });
        break;
    }

    return list;
  }

  /// Filtrelenmiş listeden assigned / unassigned ayrımı
  List<UiTopicSummary> get _assignedTopics =>
      _filteredAll.where((t) => _assignedIds.contains(t.id)).toList();

  List<UiTopicSummary> get _availableTopics =>
      _filteredAll.where((t) => !_assignedIds.contains(t.id)).toList();

  String _statusLabel(TopicStatus status) {
    switch (status) {
      case TopicStatus.open:
        return 'Open';
      case TopicStatus.inProgress:
        return 'In progress';
      case TopicStatus.closed:
        return 'Closed';
      case TopicStatus.archived:
        return 'Archived';
    }
  }

  Color _statusChipColor(TopicStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case TopicStatus.open:
        return theme.colorScheme.primary.withOpacity(0.10);
      case TopicStatus.inProgress:
        return Colors.blue.withOpacity(0.12);
      case TopicStatus.closed:
        return Colors.green.withOpacity(0.12);
      case TopicStatus.archived:
        return Colors.grey.withOpacity(0.18);
    }
  }

  Color _statusTextColor(TopicStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case TopicStatus.open:
        return theme.colorScheme.primary;
      case TopicStatus.inProgress:
        return Colors.blue[700] ?? Colors.blue;
      case TopicStatus.closed:
        return Colors.green[700] ?? Colors.green;
      case TopicStatus.archived:
        return Colors.grey[800] ?? Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year.toString();
    return '$month $day, $year';
  }

  Future<void> _toggleAssign(UiTopicSummary topic) async {
    final repo = ref.read(eventManagerRepositoryProvider);
    final isAssigned = _assignedIds.contains(topic.id);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (isAssigned) {
        await repo.unassignTopicFromEvent(
          eventId: widget.eventId,
          topicId: topic.id,
        );
        setState(() {
          _assignedIds.remove(topic.id);
        });
        _showSnack('Removed "${topic.title}" from this event.');
      } else {
        await repo.assignTopicToEvent(
          eventId: widget.eventId,
          topicId: topic.id,
        );
        setState(() {
          _assignedIds.add(topic.id);
        });
        _showSnack('Assigned "${topic.title}" to this event.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnack('Failed to update topics: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _returnAndPop() {
    Navigator.of(context).pop(_assignedCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assigned = _assignedTopics;
    final available = _availableTopics;

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
          title: Text('Assign topics – ${widget.eventName}'),
          actions: [
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // ---- Üst: arama + filtreler ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // summary row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select which topics will be used in this event.',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: theme.colorScheme.primary.withOpacity(0.08),
                        ),
                        child: Text(
                          '$_assignedCount assigned',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search topics by title or owner',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Failed to load topics: $_errorMessage',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.error,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadTopics,
                          child: const Text(
                            'Retry',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: Text(
                          _statusFilter == null
                              ? 'All statuses'
                              : _statusLabel(_statusFilter!),
                        ),
                        onPressed: () async {
                          final result =
                              await showModalBottomSheet<TopicStatus?>(
                            context: context,
                            showDragHandle: true,
                            builder: (_) {
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
                                      title: const Text('All'),
                                      onTap: () =>
                                          Navigator.of(context).pop(null),
                                    ),
                                    const Divider(height: 1),
                                    for (final s in TopicStatus.values)
                                      ListTile(
                                        leading: _statusFilter == s
                                            ? const Icon(Icons.check)
                                            : const SizedBox(width: 24),
                                        title: Text(_statusLabel(s)),
                                        onTap: () =>
                                            Navigator.of(context).pop(s),
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
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sort),
                        label: Text(_sortKey),
                        onPressed: () async {
                          final options = [
                            'Relevance',
                            'Title (A-Z)',
                            'Most ideas',
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
                                        'Sort topics',
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
                ],
              ),
            ),
            const Divider(height: 1),
            // ---- Gövde: assigned card + available list ----
            Expanded(
              child: _isLoading && _allTopics.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Assigned topics card
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
                                const Text(
                                  'Assigned topics',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (assigned.isEmpty)
                                  Text(
                                    'No topics are assigned to this event yet.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final topic in assigned)
                                        _AssignedTopicChip(
                                          topic: topic,
                                          onUnassign: () {
                                            _toggleAssign(topic);
                                          },
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Available topics header
                        const Text(
                          'Available topics',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (available.isEmpty)
                          const Text(
                            'No more topics available with current filters.',
                            style: TextStyle(fontSize: 12),
                          )
                        else ...[
                          const SizedBox(height: 4),
                          for (final topic in available) ...[
                            _AssignTopicCard(
                              topic: topic,
                              statusLabel: _statusLabel(topic.status),
                              statusChipColor:
                                  _statusChipColor(topic.status, context),
                              statusTextColor:
                                  _statusTextColor(topic.status, context),
                              formattedDate:
                                  _formatDate(topic.createdAt),
                              onAssign: () {
                                _toggleAssign(topic);
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---- Assigned chip ----
class _AssignedTopicChip extends StatelessWidget {
  final UiTopicSummary topic;
  final VoidCallback onUnassign;

  const _AssignedTopicChip({
    required this.topic,
    required this.onUnassign,
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
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.topic_outlined, size: 14),
          const SizedBox(width: 6),
          Text(
            topic.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onUnassign,
            child: const Icon(Icons.close, size: 14),
          ),
        ],
      ),
    );
  }
}

/// ---- Available topic kartı ----
class _AssignTopicCard extends StatelessWidget {
  final UiTopicSummary topic;
  final String statusLabel;
  final Color statusChipColor;
  final Color statusTextColor;
  final String formattedDate;
  final VoidCallback onAssign;

  const _AssignTopicCard({
    required this.topic,
    required this.statusLabel,
    required this.statusChipColor,
    required this.statusTextColor,
    required this.formattedDate,
    required this.onAssign,
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
            // başlık + status + assign butonu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: const TextStyle(
                      fontSize: 16,
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
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Assign',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              topic.description,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 14),
                const SizedBox(width: 4),
                Text(
                  topic.ownerName,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Created: $formattedDate',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _SmallPill(
                  icon: Icons.groups_outlined,
                  label: '${topic.teamsCount} teams used',
                ),
                _SmallPill(
                  icon: Icons.lightbulb_outline,
                  label: '${topic.ideasCount} ideas',
                ),
              ],
            ),
          ],
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
        color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
