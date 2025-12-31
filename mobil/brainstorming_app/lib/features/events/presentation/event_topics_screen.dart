import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repository/event_manager_repository.dart';

/// Bu ekran, belirli bir event için topic CRUD yapar:
/// - Listeleme (GET /events/{eventId}/topics)
/// - Create (POST /events/{eventId}/topics)
/// - Edit / Archive (PATCH /topics/{topicId})
/// - Delete (DELETE /topics/{topicId})

class EventTopicsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventName;
  final int initialTopicsCount; // Event overview’dan gelen sayı

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
  List<UiTopicSummary> _allTopics = [];

  bool _isLoading = false;
  Object? _error;

  String _searchQuery = '';
  TopicStatus? _statusFilter; // null -> All
  String _sortKey = 'Created (newest first)';

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  int get _topicsCount => _allTopics.length;

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      final topics = await repo.getTopicsForEvent(widget.eventId);
      setState(() {
        _allTopics = topics;
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

  List<UiTopicSummary> get _filteredTopics {
    var list = List<UiTopicSummary>.from(_allTopics);

    // Arama
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q) ||
                t.ownerName.toLowerCase().contains(q),
          )
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
      case 'Ideas (most first)':
        list.sort((b, a) => a.ideasCount.compareTo(b.ideasCount));
        break;
      case 'Created (newest first)':
      default:
        list.sort((b, a) => a.createdAt.compareTo(b.createdAt));
        break;
    }

    return list;
  }

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
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year.toString();
    return '$month $day, $year';
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _returnAndPop() {
    Navigator.of(context).pop(_topicsCount);
  }

  // ----------------------- CREATE -----------------------

  Future<void> _openCreateTopicSheet() async {
    final theme = Theme.of(context);

    final titleController = TextEditingController();
    final descController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New topic for ${widget.eventName}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) {
                          _showSnack('Title cannot be empty.');
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final repo = ref.read(eventManagerRepositoryProvider);
    try {
      await repo.createTopicForEvent(
        eventId: widget.eventId,
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
      );
      _showSnack('Topic created.');
      await _loadTopics();
    } catch (e) {
      _showSnack('Failed to create topic: $e');
    }
  }

  // ----------------------- EDIT -----------------------

  Future<void> _openEditSheet(UiTopicSummary topic) async {
    final theme = Theme.of(context);

    final titleController = TextEditingController(text: topic.title);
    final descController = TextEditingController(text: topic.description);
    TopicStatus currentStatus = topic.status;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit topic',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: StatefulBuilder(
                      builder: (context, setInnerState) {
                        return DropdownButton<TopicStatus>(
                          value: currentStatus,
                          isExpanded: true,
                          items: TopicStatus.values.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(_statusLabel(s)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setInnerState(() {
                              currentStatus = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) {
                          _showSnack('Title cannot be empty.');
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final repo = ref.read(eventManagerRepositoryProvider);
    try {
      await repo.updateTopic(
        topicId: topic.id,
        title: titleController.text.trim(),
        description: descController.text.trim(),
        status: currentStatus,
      );
      _showSnack('Topic updated.');
      await _loadTopics();
    } catch (e) {
      _showSnack('Failed to update topic: $e');
    }
  }

  // ----------------------- ARCHIVE -----------------------

  Future<void> _handleArchiveTopic(UiTopicSummary topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive topic'),
        content: Text(
          'Are you sure you want to archive "${topic.title}"?\n'
          'It will no longer appear as active in new sessions.',
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
      await repo.archiveTopic(topic.id);
      _showSnack('Topic archived.');
      await _loadTopics();
    } catch (e) {
      _showSnack('Failed to archive topic: $e');
    }
  }

  // ----------------------- DELETE -----------------------

  Future<void> _handleDeleteTopic(UiTopicSummary topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete topic'),
        content: Text(
          'This will permanently delete "${topic.title}".\nAre you sure?',
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
      await repo.deleteTopic(topic.id);
      _showSnack('Topic deleted.');
      await _loadTopics();
    } catch (e) {
      _showSnack('Failed to delete topic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = _filteredTopics;
    final theme = Theme.of(context);

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
          title: Text('Topics – ${widget.eventName}'),
          actions: [
            TextButton.icon(
              onPressed: _openCreateTopicSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New topic'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
            IconButton(
              onPressed: _loadTopics,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // ---- Search + filter + sort ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configure topics for this event.',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search by title, description or owner',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${topics.length} topics found',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
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
                                        'Filter topics by status',
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
                            'Created (newest first)',
                            'Title (A-Z)',
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

            // ---- Topic list / loading / error ----
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
                              'Failed to load topics.',
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
                              onPressed: _loadTopics,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (topics.isEmpty) {
                    return const Center(
                      child: Text(
                        'No topics for this event yet.\nCreate one to get started.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: topics.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return _TopicCard(
                        topic: topic,
                        statusLabel: _statusLabel(topic.status),
                        statusChipColor:
                            _statusChipColor(topic.status, context),
                        statusTextColor:
                            _statusTextColor(topic.status, context),
                        formattedDate: _formatDate(topic.createdAt),
                        onEdit: () => _openEditSheet(topic),
                        onArchive: () => _handleArchiveTopic(topic),
                        onDelete: () => _handleDeleteTopic(topic),
                      );
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

class _TopicCard extends StatelessWidget {
  final UiTopicSummary topic;
  final String statusLabel;
  final Color statusChipColor;
  final Color statusTextColor;
  final String formattedDate;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _TopicCard({
    required this.topic,
    required this.statusLabel,
    required this.statusChipColor,
    required this.statusTextColor,
    required this.formattedDate,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
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
            // Title + status
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
              ],
            ),
            const SizedBox(height: 4),
            Text(
              topic.description,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Created date
            Row(
              children: [
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
                _TopicMetricChip(
                  icon: Icons.groups_outlined,
                  label: '${topic.teamsCount} teams used',
                ),
                _TopicMetricChip(
                  icon: Icons.lightbulb_outline,
                  label: '${topic.ideasCount} ideas',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text(
                      'Archive',
                      style: TextStyle(fontSize: 10),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 36),
                      foregroundColor: Colors.red,
                    ),
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

class _TopicMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TopicMetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
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
