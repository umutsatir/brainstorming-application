import 'package:flutter/material.dart';

/// Şimdilik sadece UI için kullanılan basit idea modeli.
/// Phase 3'te backend'deki gerçek Idea modeline bağlarız.
class UiIdea {
  final int id;
  final String eventTitle;
  final String sessionName;
  final String topic;
  final String content;
  final int roundNumber;
  final DateTime createdAt;
  final String status; // 'Selected', 'In Review', 'Discarded', 'Pending'

  UiIdea({
    required this.id,
    required this.eventTitle,
    required this.sessionName,
    required this.topic,
    required this.content,
    required this.roundNumber,
    required this.createdAt,
    required this.status,
  });
}

/// Dummy veriler – şimdilik backend yerine bunları gösteriyoruz.
final List<UiIdea> _dummyIdeas = [
  UiIdea(
    id: 1,
    eventTitle: 'New Product Launch 6-3-5',
    sessionName: 'Round-based Brainstorm – January',
    topic: 'How can we increase product adoption in the first 30 days?',
    content:
        'Create an interactive onboarding wizard that adapts to user goals and shows quick wins in the first login.',
    roundNumber: 1,
    createdAt: DateTime(2025, 1, 10, 14, 35),
    status: 'Selected',
  ),
  UiIdea(
    id: 2,
    eventTitle: 'New Product Launch 6-3-5',
    sessionName: 'Round-based Brainstorm – January',
    topic: 'How can we increase product adoption in the first 30 days?',
    content:
        'Offer a “Starter Pack” with templates and sample data so users can see realistic usage immediately.',
    roundNumber: 2,
    createdAt: DateTime(2025, 1, 10, 14, 42),
    status: 'In Review',
  ),
  UiIdea(
    id: 3,
    eventTitle: 'UX Improvement Session',
    sessionName: 'Onboarding Flow Redesign',
    topic: 'Reduce drop-off during signup and first setup steps.',
    content:
        'Combine signup and first setup into a single progressive screen with clear step indicators.',
    roundNumber: 3,
    createdAt: DateTime(2025, 1, 12, 10, 12),
    status: 'Pending',
  ),
  UiIdea(
    id: 4,
    eventTitle: 'UX Improvement Session',
    sessionName: 'Onboarding Flow Redesign',
    topic: 'Reduce drop-off during signup and first setup steps.',
    content:
        'Add a “Skip for now” option but send a reminder email with a 1-minute video explaining why setup matters.',
    roundNumber: 4,
    createdAt: DateTime(2025, 1, 12, 10, 19),
    status: 'Discarded',
  ),
  UiIdea(
    id: 5,
    eventTitle: 'Quarterly Strategy Workshop',
    sessionName: 'Q1 Growth Initiatives',
    topic: 'Which channels should we prioritize for the next quarter?',
    content:
        'Run small A/B tests on 3 channels (LinkedIn, YouTube, developer communities) before committing the full budget.',
    roundNumber: 2,
    createdAt: DateTime(2025, 1, 15, 16, 18),
    status: 'In Review',
  ),
];

class MyIdeasScreen extends StatefulWidget {
  const MyIdeasScreen({super.key});

  @override
  State<MyIdeasScreen> createState() => _MyIdeasScreenState();
}

class _MyIdeasScreenState extends State<MyIdeasScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Selected, In Review, Pending, Discarded
  String _eventFilter = 'All'; // All + event adları

  late final List<String> _availableEvents;

  @override
  void initState() {
    super.initState();
    _availableEvents = [
      'All',
      ...{
        for (final idea in _dummyIdeas) idea.eventTitle,
      }.toList(),
    ];
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$year-$month-$day  $hour:$minute';
  }

  Color _statusColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'selected':
        return Colors.green.withOpacity(0.15);
      case 'in review':
        return theme.colorScheme.primary.withOpacity(0.15);
      case 'pending':
        return Colors.orange.withOpacity(0.15);
      case 'discarded':
        return Colors.red.withOpacity(0.12);
      default:
        return theme.colorScheme.surfaceVariant.withOpacity(0.5);
    }
  }

  Color _statusTextColor(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'selected':
        return Colors.green;
      case 'in review':
        return Theme.of(context).colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'discarded':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  List<UiIdea> get _filteredIdeas {
    return _dummyIdeas.where((idea) {
      final query = _searchQuery.trim().toLowerCase();

      final matchesQuery = query.isEmpty
          ? true
          : idea.content.toLowerCase().contains(query) ||
              idea.topic.toLowerCase().contains(query) ||
              idea.eventTitle.toLowerCase().contains(query) ||
              idea.sessionName.toLowerCase().contains(query);

      final matchesStatus = _statusFilter == 'All'
          ? true
          : idea.status.toLowerCase() == _statusFilter.toLowerCase();

      final matchesEvent = _eventFilter == 'All'
          ? true
          : idea.eventTitle.toLowerCase() == _eventFilter.toLowerCase();

      return matchesQuery && matchesStatus && matchesEvent;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _showIdeaDetail(UiIdea idea) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.eventTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  idea.sessionName,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.topic, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        idea.topic,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
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
                        color: _statusColor(idea.status, context),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        idea.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusTextColor(idea.status, context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.repeat, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Round ${idea.roundNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(idea.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Idea',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  idea.content,
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Note: This is only a dummy view. In the real app, you could edit your idea, see AI suggestions, or view comments from the Event Manager.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ideas = _filteredIdeas;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ideas'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search by event, topic or idea text',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filters: status + event
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Status',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'All',
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: 'Selected',
                        child: Text('Selected'),
                      ),
                      DropdownMenuItem(
                        value: 'In Review',
                        child: Text('In Review'),
                      ),
                      DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'Discarded',
                        child: Text('Discarded'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _statusFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _eventFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Event',
                      isDense: true,
                    ),
                    items: _availableEvents
                        .map(
                          (title) => DropdownMenuItem<String>(
                            value: title,
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _eventFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Ideas list
          Expanded(
            child: ideas.isEmpty
                ? const Center(
                    child: Text(
                      'You don\'t have any ideas matching these filters yet.\nTry changing status or event.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: ideas.length,
                    itemBuilder: (context, index) {
                      final idea = ideas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showIdeaDetail(idea),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Üst satır: event title + status chip
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            idea.eventTitle,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            idea.sessionName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                            idea.status, context),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        idea.status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _statusTextColor(
                                            idea.status,
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Topic
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.topic, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        idea.topic,
                                        style: const TextStyle(
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Idea content (kısaltılmış)
                                Text(
                                  idea.content,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),

                                // Alt satır: round + createdAt
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme
                                            .surfaceVariant
                                            .withOpacity(0.8),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.repeat, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Round ${idea.roundNumber}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDateTime(idea.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
