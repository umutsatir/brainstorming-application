import 'package:flutter/material.dart';

/// ---- UI MODELLERİ ----

enum TopicStatus { open, inProgress, closed, archived }

class UiTopicSummary {
  final int id;
  final String title;
  final String description;
  final String ownerName;
  final DateTime createdAt;
  final TopicStatus status;
  final int teamsCount;
  final int ideasCount;

  const UiTopicSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerName,
    required this.createdAt,
    required this.status,
    required this.teamsCount,
    required this.ideasCount,
  });

  UiTopicSummary copyWith({
    int? id,
    String? title,
    String? description,
    String? ownerName,
    DateTime? createdAt,
    TopicStatus? status,
    int? teamsCount,
    int? ideasCount,
  }) {
    return UiTopicSummary(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      teamsCount: teamsCount ?? this.teamsCount,
      ideasCount: ideasCount ?? this.ideasCount,
    );
  }
}

/// ---- GLOBAL DUMMY TOPIC LİSTESİ ----
List<UiTopicSummary> _allDummyTopics = [
  UiTopicSummary(
    id: 1,
    title: 'Q3 Marketing Strategy',
    description:
        'Ideas for the upcoming Q3 campaign across digital, offline and partnerships.',
    ownerName: 'Alex Morgan',
    createdAt: DateTime(2025, 7, 1),
    status: TopicStatus.open,
    teamsCount: 4,
    ideasCount: 96,
  ),
  UiTopicSummary(
    id: 2,
    title: 'Onboarding UX 2.0',
    description:
        'Redesign the first-time user experience for the mobile app.',
    ownerName: 'Sarah Lee',
    createdAt: DateTime(2025, 6, 28),
    status: TopicStatus.inProgress,
    teamsCount: 3,
    ideasCount: 54,
  ),
  UiTopicSummary(
    id: 3,
    title: 'Customer Retention Experiments',
    description:
        'Brainstorm retention experiments for high-value customers.',
    ownerName: 'Michael Chen',
    createdAt: DateTime(2025, 6, 20),
    status: TopicStatus.closed,
    teamsCount: 2,
    ideasCount: 40,
  ),
  UiTopicSummary(
    id: 4,
    title: 'Internal Tools Cleanup',
    description: 'Identify redundant internal tools and propose migration.',
    ownerName: 'Ops Team',
    createdAt: DateTime(2025, 5, 10),
    status: TopicStatus.archived,
    teamsCount: 1,
    ideasCount: 18,
  ),
];

/// ---- GLOBAL TOPICS MANAGEMENT SCREEN ----
class TopicsManagementScreen extends StatefulWidget {
  const TopicsManagementScreen({super.key});

  @override
  State<TopicsManagementScreen> createState() =>
      _TopicsManagementScreenState();
}

class _TopicsManagementScreenState extends State<TopicsManagementScreen> {
  String _searchQuery = '';
  TopicStatus? _statusFilter; // null -> All
  String _sortKey = 'Created (newest first)';

  List<UiTopicSummary> get _filteredTopics {
    var list = List<UiTopicSummary>.from(_allDummyTopics);

    // Search
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.ownerName.toLowerCase().contains(q))
          .toList();
    }

    // Status filter
    if (_statusFilter != null) {
      list = list.where((t) => t.status == _statusFilter).toList();
    }

    // Sort
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

  /// ---- NEW TOPIC FORM ----
  Future<void> _openCreateTopicSheet() async {
    final theme = Theme.of(context);

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final ownerController = TextEditingController();
    TopicStatus currentStatus = TopicStatus.open;

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
                  'New topic',
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
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Owner (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
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
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
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

    setState(() {
      int newId = 1;
      for (final t in _allDummyTopics) {
        if (t.id >= newId) newId = t.id + 1;
      }

      _allDummyTopics = [
        ..._allDummyTopics,
        UiTopicSummary(
          id: newId,
          title: titleController.text.trim(),
          description: descController.text.trim(),
          ownerName: ownerController.text.trim().isEmpty
              ? 'Event Manager'
              : ownerController.text.trim(),
          createdAt: DateTime.now(),
          status: currentStatus,
          teamsCount: 0,
          ideasCount: 0,
        ),
      ];
    });

    _showSnack('Topic created.');
  }

  Future<void> _openEditSheet(UiTopicSummary topic) async {
    final theme = Theme.of(context);

    final titleController = TextEditingController(text: topic.title);
    final descController = TextEditingController(text: topic.description);
    final ownerController = TextEditingController(text: topic.ownerName);
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
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                    isDense: true,
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
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
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

    setState(() {
      _allDummyTopics = _allDummyTopics.map((t) {
        if (t.id != topic.id) return t;
        return t.copyWith(
          title: titleController.text.trim(),
          description: descController.text.trim(),
          ownerName: ownerController.text.trim().isEmpty
              ? t.ownerName
              : ownerController.text.trim(),
          status: currentStatus,
        );
      }).toList();
    });

    _showSnack('Topic updated.');
  }

  void _duplicateTopic(UiTopicSummary topic) {
    setState(() {
      int newId = 1;
      for (final t in _allDummyTopics) {
        if (t.id >= newId) newId = t.id + 1;
      }

      _allDummyTopics = [
        ..._allDummyTopics,
        topic.copyWith(
          id: newId,
          title: '${topic.title} (copy)',
          createdAt: DateTime.now(),
        ),
      ];
    });
    _showSnack('Topic duplicated.');
  }

  void _changeStatus(UiTopicSummary topic, TopicStatus newStatus) {
    setState(() {
      _allDummyTopics = _allDummyTopics.map((t) {
        if (t.id != topic.id) return t;
        return t.copyWith(status: newStatus);
      }).toList();
    });
    _showSnack('Status set to ${_statusLabel(newStatus)}.');
  }

  void _deleteTopic(UiTopicSummary topic) {
    setState(() {
      _allDummyTopics =
          _allDummyTopics.where((t) => t.id != topic.id).toList();
    });
    _showSnack('Topic deleted (dummy).');
  }

  @override
  Widget build(BuildContext context) {
    final topics = _filteredTopics;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topics'),
        actions: [
          TextButton.icon(
            onPressed: _openCreateTopicSheet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New topic'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
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
          // ---- Topic list ----
          Expanded(
            child: topics.isEmpty
                ? const Center(
                    child: Text(
                      'No topics match your filters.\n'
                      'Try changing search text or status.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
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
                        onDuplicate: () => _duplicateTopic(topic),
                        onArchive: () =>
                            _changeStatus(topic, TopicStatus.archived),
                        onDelete: () => _deleteTopic(topic),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// ---- Topic kartı ----
class _TopicCard extends StatelessWidget {
  final UiTopicSummary topic;
  final String statusLabel;
  final Color statusChipColor;
  final Color statusTextColor;
  final String formattedDate;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _TopicCard({
    required this.topic,
    required this.statusLabel,
    required this.statusChipColor,
    required this.statusTextColor,
    required this.formattedDate,
    required this.onEdit,
    required this.onDuplicate,
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
            // Owner + created date
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
            // ---- Aksiyon butonları: tek satır ----
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
                    onPressed: onDuplicate,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text(
                      'Copy',
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
