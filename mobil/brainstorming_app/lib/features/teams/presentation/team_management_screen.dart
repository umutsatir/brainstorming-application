import 'package:flutter/material.dart';

/// ---- UI MODELLERİ (şimdilik sadece frontend için) ----

enum UiParticipantRole { leader, member }

class UiParticipant {
  final int id;
  final String name;
  final String email;
  final UiParticipantRole role;
  final bool isActive;

  const UiParticipant({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  UiParticipant copyWith({
    UiParticipantRole? role,
  }) {
    return UiParticipant(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      isActive: isActive,
    );
  }
}

class UiTeam {
  final int id;
  final String name;
  final String eventName;
  final String topicTitle;
  final int ideasCount;
  final int sessionsCount;
  final List<UiParticipant> members;

  const UiTeam({
    required this.id,
    required this.name,
    required this.eventName,
    required this.topicTitle,
    required this.ideasCount,
    required this.sessionsCount,
    required this.members,
  });

  UiTeam copyWith({
    String? name,
    String? eventName,
    String? topicTitle,
    int? ideasCount,
    int? sessionsCount,
    List<UiParticipant>? members,
  }) {
    return UiTeam(
      id: id,
      name: name ?? this.name,
      eventName: eventName ?? this.eventName,
      topicTitle: topicTitle ?? this.topicTitle,
      ideasCount: ideasCount ?? this.ideasCount,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      members: members ?? this.members,
    );
  }
}

/// ---- DUMMY DATA ----

const List<UiParticipant> _dummyParticipants = [
  UiParticipant(
    id: 1,
    name: 'Alex Morgan',
    email: 'alex@example.com',
    role: UiParticipantRole.leader,
  ),
  UiParticipant(
    id: 2,
    name: 'Mert Certel',
    email: 'mert@example.com',
    role: UiParticipantRole.member,
  ),
  UiParticipant(
    id: 3,
    name: 'Sarah Lee',
    email: 'sarah@example.com',
    role: UiParticipantRole.member,
  ),
  UiParticipant(
    id: 4,
    name: 'John Carter',
    email: 'john@example.com',
    role: UiParticipantRole.member,
  ),
  UiParticipant(
    id: 5,
    name: 'Emma Brown',
    email: 'emma@example.com',
    role: UiParticipantRole.member,
  ),
];

/// NOT: Burada global dummy team list’i mutable kullanıyoruz.
final List<UiTeam> _dummyTeams = [
  UiTeam(
    id: 1,
    name: 'Team Aurora',
    eventName: 'Q3 Innovation Ideathon',
    topicTitle: 'New Growth Channels for Q3',
    ideasCount: 64,
    sessionsCount: 3,
    members: [
      _dummyParticipants[0], // Alex - leader
      _dummyParticipants[1],
      _dummyParticipants[2],
    ],
  ),
  UiTeam(
    id: 2,
    name: 'Team Pixel',
    eventName: 'UX Redesign 2.0 Workshop',
    topicTitle: 'Onboarding Flow Improvements',
    ideasCount: 41,
    sessionsCount: 2,
    members: [
      _dummyParticipants[2],
      _dummyParticipants[3],
      _dummyParticipants[4],
    ],
  ),
  UiTeam(
    id: 3,
    name: 'Customer Heroes',
    eventName: 'Customer Centricity Sprint',
    topicTitle: 'Lower Churn in First 30 Days',
    ideasCount: 0,
    sessionsCount: 0,
    members: [
      _dummyParticipants[1],
      _dummyParticipants[4],
    ],
  ),
];

/// ---- EKRAN ----
/// Event Manager için global Team Management.
/// Events ekranındaki "Manage teams" butonu buraya yönlenecek.
class TeamManagementScreen extends StatefulWidget {
  /// Eğer Events ekranından geliyorsak ilgili event’i filtreleyebilmek için
  final String? initialEventName;

  const TeamManagementScreen({
    super.key,
    this.initialEventName,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  String _searchQuery = '';
  String _eventFilter = 'All events';

  List<String> get _allEventNames {
    final names = {
      for (final t in _dummyTeams) t.eventName,
    }.toList();
    names.sort();
    return names;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialEventName != null) {
      _eventFilter = widget.initialEventName!;
    }
  }

  List<UiTeam> get _filteredTeams {
    var list = List<UiTeam>.from(_dummyTeams);

    if (_eventFilter != 'All events') {
      list = list.where((t) => t.eventName == _eventFilter).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        final inTeamName = t.name.toLowerCase().contains(q);
        final inTopic = t.topicTitle.toLowerCase().contains(q);
        final inEvent = t.eventName.toLowerCase().contains(q);
        final inMembers = t.members.any(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              m.email.toLowerCase().contains(q),
        );
        return inTeamName || inTopic || inEvent || inMembers;
      }).toList();
    }

    return list;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEventFilterSheet() async {
    final all = _allEventNames;
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
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
                leading: _eventFilter == 'All events'
                    ? const Icon(Icons.check)
                    : const SizedBox(width: 24),
                title: const Text('All events'),
                onTap: () => Navigator.of(context).pop('All events'),
              ),
              const Divider(height: 1),
              for (final name in all)
                ListTile(
                  leading: _eventFilter == name
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
    if (result != null && result != _eventFilter) {
      setState(() => _eventFilter = result);
    }
  }

  /// --------- NEW TEAM SHEET (dummy create) -----------
  Future<void> _openCreateTeamSheet() async {
    final theme = Theme.of(context);

    final nameController = TextEditingController();
    final eventController = TextEditingController(
      text: _eventFilter == 'All events' ? '' : _eventFilter,
    );
    final topicController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create team',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Team name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: eventController,
                  decoration: const InputDecoration(
                    labelText: 'Event name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Topic / challenge',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(sheetContext)
                              .showSnackBar(const SnackBar(
                            content: Text('Team name cannot be empty.'),
                          ));
                          return;
                        }
                        Navigator.of(sheetContext).pop(true);
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

    // id üret
    int newId = 1;
    for (final t in _dummyTeams) {
      if (t.id >= newId) newId = t.id + 1;
    }

    final teamName = nameController.text.trim();
    final eventNameText =
        eventController.text.trim().isEmpty ? 'Untitled event' : eventController.text.trim();
    final topicText =
        topicController.text.trim().isEmpty ? 'Untitled topic' : topicController.text.trim();

    setState(() {
      _dummyTeams.add(
        UiTeam(
          id: newId,
          name: teamName,
          eventName: eventNameText,
          topicTitle: topicText,
          ideasCount: 0,
          sessionsCount: 0,
          members: const [],
        ),
      );
      // filtreyi yeni event’e çekmek istersen:
      if (_eventFilter == 'All events') {
        _eventFilter = eventNameText;
      }
    });

    _showSnack('Team "$teamName" created (dummy).');
  }

  /// --------- EDIT TEAM SHEET -----------
  Future<void> _openEditTeamSheet(UiTeam team) async {
    final theme = Theme.of(context);

    final nameController = TextEditingController(text: team.name);
    final eventController = TextEditingController(text: team.eventName);
    final topicController = TextEditingController(text: team.topicTitle);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit team',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Team name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: eventController,
                  decoration: const InputDecoration(
                    labelText: 'Event name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Topic / challenge',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(sheetContext)
                              .showSnackBar(const SnackBar(
                            content: Text('Team name cannot be empty.'),
                          ));
                          return;
                        }
                        Navigator.of(sheetContext).pop(true);
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
      final idx = _dummyTeams.indexWhere((t) => t.id == team.id);
      if (idx != -1) {
        _dummyTeams[idx] = _dummyTeams[idx].copyWith(
          name: nameController.text.trim(),
          eventName: eventController.text.trim().isEmpty
              ? team.eventName
              : eventController.text.trim(),
          topicTitle: topicController.text.trim().isEmpty
              ? team.topicTitle
              : topicController.text.trim(),
        );
      }
    });

    _showSnack('Team "${team.name}" updated.');
  }

  /// --------- DELETE TEAM CONFIRM -----------
  Future<void> _confirmDeleteTeam(UiTeam team) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete team'),
          content: Text(
            'Are you sure you want to delete "${team.name}"?\n'
            'Members and dummy data will be removed from this list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    setState(() {
      _dummyTeams.removeWhere((t) => t.id == team.id);
    });

    _showSnack('Team "${team.name}" deleted (dummy).');
  }

  @override
  Widget build(BuildContext context) {
    final teams = _filteredTeams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams & Participants'),
        actions: [
          TextButton.icon(
            onPressed: _openCreateTeamSheet,
            icon: const Icon(Icons.group_add),
            label: const Text('New team'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search + event filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search by team, member or topic',
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
                        onPressed: _openEventFilterSheet,
                        icon: const Icon(Icons.event),
                        label: Text(_eventFilter),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: teams.isEmpty
                ? const Center(
                    child: Text(
                      'No teams match your filters.\nTry changing search or event filter.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return _TeamCard(
                        team: team,
                        onManageMembers: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ManageTeamMembersScreen(
                                teamId: team.id,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        onEditTeam: () => _openEditTeamSheet(team),
                        onDeleteTeam: () => _confirmDeleteTeam(team),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemCount: teams.length,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir takım kartı: event, topic, metrics ve üyeler
class _TeamCard extends StatelessWidget {
  final UiTeam team;
  final VoidCallback onManageMembers;
  final VoidCallback onEditTeam;
  final VoidCallback onDeleteTeam;

  const _TeamCard({
    required this.team,
    required this.onManageMembers,
    required this.onEditTeam,
    required this.onDeleteTeam,
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
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: takım adı + event
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              team.eventName,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Topic
            Row(
              children: [
                const Icon(Icons.topic_outlined, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    team.topicTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Metrikler
            Row(
              children: [
                _SmallPill(
                  icon: Icons.lightbulb_outline,
                  label: '${team.ideasCount} ideas',
                ),
                const SizedBox(width: 8),
                _SmallPill(
                  icon: Icons.timer_outlined,
                  label: '${team.sessionsCount} sessions',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Üyeler
            const Text(
              'Members',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final member in team.members)
                  _MemberChip(member: member),
              ],
            ),
            const SizedBox(height: 12),
            // Aksiyon butonları
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onManageMembers,
                  icon: const Icon(Icons.group),
                  label: const Text('Manage members'),
                ),
                OutlinedButton.icon(
                  onPressed: onEditTeam,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit team'),
                ),
                TextButton.icon(
                  onPressed: onDeleteTeam,
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Delete team',
                    style: TextStyle(
                      color: theme.colorScheme.error,
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

class _MemberChip extends StatelessWidget {
  final UiParticipant member;

  const _MemberChip({required this.member});

  String get _initials {
    final parts = member.name.split(' ');
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final roleLabel =
        member.role == UiParticipantRole.leader ? 'Leader' : 'Member';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Text(
              _initials,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                roleLabel,
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// MANAGE TEAM MEMBERS SCREEN
/// ------------------------------------------------------------

class ManageTeamMembersScreen extends StatefulWidget {
  final int teamId;

  const ManageTeamMembersScreen({
    super.key,
    required this.teamId,
  });

  @override
  State<ManageTeamMembersScreen> createState() =>
      _ManageTeamMembersScreenState();
}

class _ManageTeamMembersScreenState extends State<ManageTeamMembersScreen> {
  late UiTeam _team;

  @override
  void initState() {
    super.initState();
    _team = _dummyTeams.firstWhere((t) => t.id == widget.teamId);
  }

  List<UiParticipant> get _members => _team.members;

  List<UiParticipant> get _availableParticipants {
    final memberIds = _members.map((m) => m.id).toSet();
    return _dummyParticipants
        .where((p) => !memberIds.contains(p.id))
        .toList();
  }

  void _setLeader(UiParticipant member) {
    final updatedMembers = _members
        .map(
          (m) => m.id == member.id
              ? m.copyWith(role: UiParticipantRole.leader)
              : m.copyWith(role: UiParticipantRole.member),
        )
        .toList();

    setState(() {
      _team = _team.copyWith(members: updatedMembers);
      final index = _dummyTeams.indexWhere((t) => t.id == _team.id);
      if (index != -1) {
        _dummyTeams[index] = _team;
      }
    });
  }

  void _removeMember(UiParticipant member) {
    setState(() {
      final updatedMembers =
          _members.where((m) => m.id != member.id).toList();
      _team = _team.copyWith(members: updatedMembers);
      final index = _dummyTeams.indexWhere((t) => t.id == _team.id);
      if (index != -1) {
        _dummyTeams[index] = _team;
      }
    });
  }

  void _addMember(UiParticipant participant) {
    setState(() {
      final updated = List<UiParticipant>.from(_members)
        ..add(participant.copyWith(role: UiParticipantRole.member));
      _team = _team.copyWith(members: updated);
      final index = _dummyTeams.indexWhere((t) => t.id == _team.id);
      if (index != -1) {
        _dummyTeams[index] = _team;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = _members;
    final available = _availableParticipants;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage members – ${_team.name}'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildMembersCard(theme, members),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  flex: 1,
                  child: _buildAvailableCard(theme, available),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildMembersCard(theme, members),
                  const Divider(height: 1),
                  _buildAvailableCard(theme, available),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMembersCard(ThemeData theme, List<UiParticipant> members) {
    final leader =
        members.where((m) => m.role == UiParticipantRole.leader).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Team members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withOpacity(0.08),
                    ),
                    child: Text(
                      '${members.length} members',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '1 leader, diğerleri member rolünde. '
                'Buradan remove / make leader yapabilirsin.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'This team has no members yet.\nAdd from "Available participants".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final isLeader = m.role == UiParticipantRole.leader;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          m.name.isNotEmpty
                              ? m.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(
                        m.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${m.email} • ${isLeader ? 'Leader' : 'Member'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (!isLeader)
                            TextButton(
                              onPressed: () => _setLeader(m),
                              child: const Text(
                                'Make leader',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          TextButton(
                            onPressed: () => _removeMember(m),
                            child: const Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (leader.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Warning: multiple leaders detected (dummy data).',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableCard(
      ThemeData theme, List<UiParticipant> available) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Available participants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color:
                          theme.colorScheme.secondary.withOpacity(0.08),
                    ),
                    child: Text(
                      '${available.length} available',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Bu listede şu an bu takımda olmayan katılımcılar var. '
                'Üzerine tıklayarak takıma ekleyebilirsin.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 12),
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No available participants left for this team.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: available.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final p = available[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.secondary.withOpacity(0.15),
                        child: Text(
                          p.name.isNotEmpty
                              ? p.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        p.email,
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addMember(p),
                        tooltip: 'Add to team',
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
