import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repository/event_manager_repository.dart';

/// Event içi team yönetimi:
/// - GET /events/{eventId}/teams
/// - POST /events/{eventId}/teams
/// - PATCH /teams/{teamId}
/// - DELETE /teams/{teamId}
///
/// Ayrıca:
/// - GET /participants?eventId=...
/// - POST /participants
///
/// Event details içinden "Manage teams" ile bu ekran açılır.

class EventTeamsScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventName;
  final int initialTeamsCount;

  const EventTeamsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
    required this.initialTeamsCount,
  });

  @override
  ConsumerState<EventTeamsScreen> createState() => _EventTeamsScreenState();
}

class _EventTeamsScreenState extends ConsumerState<EventTeamsScreen> {
  List<UiTeamSummary> _teams = [];
  List<UiParticipantSummary> _participants = [];

  /// Herhangi bir takıma ait olan event_participants.id set’i
  Set<int> _assignedParticipantIds = {};


  bool _isLoading = false;
  Object? _error;

  String _searchQuery = '';
  String _sortKey = 'Name (A-Z)';

  static const int _defaultMaxMembers = 6;

  @override
  void initState() {
    super.initState();
    _loadTeamsAndParticipants();
  }

  int get _teamsCount => _teams.length;

  Future<void> _loadTeamsAndParticipants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      final teams = await repo.getTeamsForEvent(widget.eventId);
      final participants =
          await repo.getParticipantsForEvent(widget.eventId);

      // yeni: bu event’te herhangi bir takıma atanmış participant id’leri
      final assignedIds =
          await repo.getParticipantIdsInAnyTeamForEvent(widget.eventId);

      setState(() {
        _teams = teams;
        _participants = participants;
        _assignedParticipantIds = assignedIds;
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


  // ---------------------------------------------------------------------------
  // Yardımcılar
  // ---------------------------------------------------------------------------

  /// Tüm takımlardaki tüm participant id’leri (bir event’te sadece 1 takımda olabilirler)
  /// Herhangi bir takımda olan event_participants.id set'i
  Set<int> get _participantIdsInAnyTeam {
    final result = <int>{};
    for (final team in _teams) {
      for (final member in team.members) {
        result.add(member.participantId);
      }
    }
    return result;
  }





  bool _isParticipantInAnyTeam(int participantId) {
    return _participantIdsInAnyTeam.contains(participantId);
  }


  /// Hiçbir takıma ait olmayan katılımcılar
  List<UiParticipantSummary> get _availableParticipantsForNewTeam {
    return _participants
        .where((p) => !_assignedParticipantIds.contains(p.id))
        .toList();
  }


  /// Edit ekranında kullanılacak participant listesi:
  /// - Bu takımdaki üyeler (her durumda görünecek)
  /// - Hiçbir takıma bağlı olmayan diğer participant’lar
List<UiParticipantSummary> _participantsForEditTeam(UiTeamSummary team) {
  final inThisTeamIds = team.members.map((m) => m.participantId).toSet();

  return _participants.where((p) {
    final inThisTeam = inThisTeamIds.contains(p.id);
    final inAnotherTeam = _isParticipantInAnotherTeam(p.id, team.id);
    if (inThisTeam) return true;
    return !inAnotherTeam;
  }).toList();
}

bool _isParticipantInAnotherTeam(int participantId, int teamId) {
  for (final t in _teams) {
    if (t.id == teamId) continue;
    for (final m in t.members) {
      if (m.participantId == participantId) return true;
    }
  }
  return false;
}


  UiParticipantSummary? _findParticipant(int userId) {
    try {
      return _participants.firstWhere((p) => p.id == userId);
    } catch (_) {
      return null;
    }
  }

  List<UiTeamSummary> get _filteredTeams {
    var list = List<UiTeamSummary>.from(_teams);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (t) =>
                t.name.toLowerCase().contains(q) ||
                t.focus.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (_sortKey) {
      case 'Members (most first)':
        list.sort((b, a) => a.memberCount.compareTo(b.memberCount));
        break;
      case 'Name (A-Z)':
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return list;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _returnAndPop() {
    Navigator.of(context).pop(_teamsCount);
  }

  // ---------------------------------------------------------------------------
  // PARTICIPANT CREATE SHEET
  // ---------------------------------------------------------------------------

  Future<void> _openCreateParticipantSheet() async {
    final theme = Theme.of(context);

    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    const String role = 'TEAM_MEMBER'; // UI’de göstermiyoruz, backend için.

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add participant to "${widget.eventName}"',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Participants must belong to this event before they can be assigned to a team.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'e.g. Alex Johnson',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'e.g. alex@example.com',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'An invitation may be sent by email.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            if (fullNameController.text.trim().isEmpty) {
                              _showSnack('Full name cannot be empty.');
                              return;
                            }
                            if (emailController.text.trim().isEmpty) {
                              _showSnack('Email cannot be empty.');
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
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      await repo.createParticipantForEvent(
        eventId: widget.eventId,
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        role: role,
      );

      _showSnack('Participant created.');
      await _loadTeamsAndParticipants();
    } catch (e) {
      _showSnack('Failed to create participant: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE TEAM
  // ---------------------------------------------------------------------------

   // ------------------------ CREATE ------------------------

  Future<void> _openCreateTeamSheet() async {
    final availableParticipants = _availableParticipantsForNewTeam;

    if (availableParticipants.isEmpty) {
      _showSnack(
        'All participants in this event already belong to a team. '
        'Please add a new participant first.',
      );
      await _openCreateParticipantSheet();
      return;
    }

    final theme = Theme.of(context);

    final nameController = TextEditingController();

    // Varsayılan leader: takımı olmayan ilk participant
    UiParticipantSummary? selectedLeader = availableParticipants.first;

    // Başlangıçta lider seçili member listesinde olsun
    final selectedMemberIds = <int>{
      if (selectedLeader != null) selectedLeader.id,
    };

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
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
                      'New team – ${widget.eventName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only participants who are not yet in any team are listed below.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                    // Leader dropdown
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Team leader',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UiParticipantSummary>(
                          value: selectedLeader,
                          isExpanded: true,
                          items: availableParticipants.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.fullName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setInnerState(() {
                              selectedLeader = value;
                              selectedMemberIds.add(value.id);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Members (max 6 including leader)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        itemCount: availableParticipants.length,
                        itemBuilder: (context, index) {
                          final p = availableParticipants[index];
                          final isChecked = selectedMemberIds.contains(p.id);
                          final isLeader =
                              selectedLeader != null &&
                              p.id == selectedLeader!.id;

                          return CheckboxListTile(
                            dense: true,
                            value: isChecked,
                            title: Text(p.fullName),
                            subtitle: isLeader ? const Text('Leader') : null,
                            onChanged: (value) {
                              setInnerState(() {
                                if (value == true) {
                                  if (selectedMemberIds.length >= 6) {
                                    _showSnack(
                                      'A team can have maximum 6 members.',
                                    );
                                    return;
                                  }
                                  selectedMemberIds.add(p.id);
                                } else {
                                  if (isLeader) return;
                                  selectedMemberIds.remove(p.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedMemberIds.length} selected',
                          style: theme.textTheme.bodySmall,
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  _showSnack('Team name cannot be empty.');
                                  return;
                                }
                                if (selectedLeader == null) {
                                  _showSnack('Select a team leader.');
                                  return;
                                }
                                if (selectedMemberIds.isEmpty) {
                                  _showSnack('Select at least one member.');
                                  return;
                                }
                                if (selectedMemberIds.length > 6) {
                                  _showSnack(
                                    'A team can have maximum 6 members.',
                                  );
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      final leaderId = selectedLeader!.id;
      final memberIds = <int>{...selectedMemberIds, leaderId}.toList();

      await repo.createTeamForEvent(
        eventId: widget.eventId,
        name: nameController.text.trim(),
        leaderId: leaderId,
        memberIds: memberIds,
      );

      _showSnack('Team created.');
      await _loadTeamsAndParticipants();
    } catch (e) {
      _showSnack('Failed to create team: $e');
    }
  }


  // ---------------------------------------------------------------------------
  // EDIT TEAM (isim + leader + üyeler)
  // ---------------------------------------------------------------------------

  Future<void> _openEditTeamSheet(UiTeamSummary team) async {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: team.name);

    final candidates = _participantsForEditTeam(team);

    UiParticipantSummary? leader;
    try {
      leader =
          candidates.firstWhere((p) => p.id == team.leaderId);
    } catch (_) {
      if (candidates.isNotEmpty) {
        leader = candidates.first;
      }
    }

    final originalMemberIds =
        team.members.map((m) => m.participantId).toSet();
    final currentMemberIds = <int>{...originalMemberIds};

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            final maxMembers =
                team.maxMembers > 0 ? team.maxMembers : _defaultMaxMembers;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Edit team',
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Change team name, leader and members. Participants can only be in one team per event.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.7),
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
                    // Leader
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Team leader',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<UiParticipantSummary>(
                          value: leader,
                          isExpanded: true,
                          items: candidates.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.fullName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setInnerState(() {
                              leader = value;
                              currentMemberIds.add(value.id);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Members (max $maxMembers including leader)',
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${currentMemberIds.length} selected',
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: SizedBox(
                        height: 230,
                        child: ListView.builder(
                          itemCount: candidates.length,
                          itemBuilder: (context, index) {
                            final p = candidates[index];
                            final isChecked =
                                currentMemberIds.contains(p.id);
                            final isLeader = leader != null &&
                                p.id == leader!.id;

                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              title: Text(p.fullName),
                              subtitle: isLeader
                                  ? const Text('Leader')
                                  : null,
                              onChanged: (value) {
                                setInnerState(() {
                                  if (value == true) {
                                    if (currentMemberIds.length >=
                                        maxMembers) {
                                      _showSnack(
                                        'A team can have maximum $maxMembers members.',
                                      );
                                      return;
                                    }
                                    currentMemberIds.add(p.id);
                                  } else {
                                    if (isLeader) return;
                                    currentMemberIds.remove(p.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final name =
                                nameController.text.trim();
                            if (name.isEmpty) {
                              _showSnack(
                                  'Team name cannot be empty.');
                              return;
                            }
                            if (leader == null) {
                              _showSnack('Select a team leader.');
                              return;
                            }
                            if (currentMemberIds.isEmpty) {
                              _showSnack(
                                  'Select at least one team member.');
                              return;
                            }
                            if (currentMemberIds.length >
                                maxMembers) {
                              _showSnack(
                                'A team can have maximum $maxMembers members.',
                              );
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
      },
    );

    if (result != true) return;

    final repo = ref.read(eventManagerRepositoryProvider);

    try {
      final leaderId = leader!.id;
      final newIds = <int>{...currentMemberIds, leaderId};

      final add =
          newIds.difference(originalMemberIds).toList();
      final remove =
          originalMemberIds.difference(newIds).toList();

      await repo.updateTeam(
        teamId: team.id,
        name: nameController.text.trim(),
        leaderId: leaderId,
        addMemberIds: add.isEmpty ? null : add,
        removeMemberIds: remove.isEmpty ? null : remove,
      );

      _showSnack('Team updated.');
      await _loadTeamsAndParticipants();
    } catch (e) {
      _showSnack('Failed to update team: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE TEAM
  // ---------------------------------------------------------------------------

  Future<void> _handleDeleteTeam(UiTeamSummary team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team'),
        content: Text(
          'This will permanently delete "${team.name}". '
          'Participants will be removed from this team and become available again.\n\nAre you sure?',
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
      await repo.deleteTeam(team.id);
      _showSnack('Team deleted.');
      await _loadTeamsAndParticipants();
    } catch (e) {
      _showSnack('Failed to delete team: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final teams = _filteredTeams;
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
          title: Text('Teams – ${widget.eventName}'),
          actions: [
            IconButton(
              onPressed: _openCreateParticipantSheet,
              icon: const Icon(Icons.person_add_alt_1),
              tooltip: 'Add participant',
            ),
            TextButton.icon(
              onPressed: _openCreateTeamSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New team'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
            IconButton(
              onPressed: _loadTeamsAndParticipants,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create and manage teams for this event.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search by team name or focus',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${teams.length} teams found',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sort),
                    label: Text(_sortKey),
                    onPressed: () async {
                      final options = [
                        'Name (A-Z)',
                        'Members (most first)',
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
                                    'Sort teams',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),
                                for (final opt in options)
                                  ListTile(
                                    leading: _sortKey == opt
                                        ? const Icon(
                                            Icons.check,
                                          )
                                        : const SizedBox(
                                            width: 24),
                                    title: Text(opt),
                                    onTap: () =>
                                        Navigator.of(context)
                                            .pop(opt),
                                  ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          );
                        },
                      );

                      if (!mounted) return;
                      if (result != null &&
                          result != _sortKey) {
                        setState(() => _sortKey = result);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                              'Failed to load teams.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed:
                                  _loadTeamsAndParticipants,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (teams.isEmpty) {
                    return const Center(
                      child: Text(
                        'No teams for this event yet.\nCreate one to get started.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: teams.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return _TeamCard(
                        team: team,
                        onEdit: () =>
                            _openEditTeamSheet(team),
                        onDelete: () =>
                            _handleDeleteTeam(team),
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

// ---------------------------------------------------------------------------
// Team Card
// ---------------------------------------------------------------------------

class _TeamCard extends StatelessWidget {
  final UiTeamSummary team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeamCard({
    required this.team,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final maxMembers =
        team.maxMembers > 0 ? team.maxMembers : _EventTeamsScreenState._defaultMaxMembers;

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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    team.name,
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
                    borderRadius:
                        BorderRadius.circular(999),
                    color: theme.colorScheme.primary
                        .withOpacity(0.10),
                  ),
                  child: Text(
                    '${team.memberCount}/$maxMembers members',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (team.focus.isNotEmpty)
              Text(
                team.focus,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface
                      .withOpacity(0.8),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _SmallStatPill(
                  icon: Icons.groups_outlined,
                  label: '${team.memberCount} members',
                ),
                _SmallStatPill(
                  icon: Icons.lightbulb_outline,
                  label: '${team.ideasCount} ideas',
                ),
                _SmallStatPill(
                  icon: Icons.meeting_room_outlined,
                  label: '${team.sessionsCount} sessions',
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
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                    ),
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

class _SmallStatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallStatPill({
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
        color: theme.colorScheme.surfaceVariant
            .withOpacity(0.8),
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
