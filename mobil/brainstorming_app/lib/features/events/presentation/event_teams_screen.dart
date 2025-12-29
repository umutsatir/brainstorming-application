import 'package:flutter/material.dart';

/// ---- UI MODELLERİ (global teams) ----

class UiTeamSummary {
  final int id;
  final String name;
  final String focus;
  final int memberCount;
  final int maxMembers;
  final int ideasCount;
  final int sessionsCount;

  const UiTeamSummary({
    required this.id,
    required this.name,
    required this.focus,
    required this.memberCount,
    required this.maxMembers,
    required this.ideasCount,
    required this.sessionsCount,
  });
}

/// ---- GLOBAL DUMMY TEAM KATALOĞU ----
final List<UiTeamSummary> _allDummyTeams = [
  UiTeamSummary(
    id: 1,
    name: 'Cross-Functional Squad A',
    focus: 'Q3 Growth Strategy 6-3-5',
    memberCount: 6,
    maxMembers: 6,
    ideasCount: 324,
    sessionsCount: 3,
  ),
  UiTeamSummary(
    id: 2,
    name: 'Team Beta',
    focus: 'Customer Retention Experiments',
    memberCount: 4,
    maxMembers: 6,
    ideasCount: 120,
    sessionsCount: 1,
  ),
  UiTeamSummary(
    id: 3,
    name: 'Design Guild',
    focus: 'Onboarding UX Redesign',
    memberCount: 5,
    maxMembers: 6,
    ideasCount: 210,
    sessionsCount: 4,
  ),
  UiTeamSummary(
    id: 4,
    name: 'Ops Task Force',
    focus: 'Internal tools cleanup sprint',
    memberCount: 3,
    maxMembers: 5,
    ideasCount: 45,
    sessionsCount: 2,
  ),
];

/// ---- EVENT → TEAM ASSIGNMENT HARİTASI ----
/// eventId -> teamId set’i
final Map<int, Set<int>> _eventTeamAssignments = {};

/// ---- EKRAN ----
/// Sadece mevcut takımları bu event’e assign / unassign eder.
/// Takım create / edit yok; onlar global Teams ekranında.
class EventTeamsScreen extends StatefulWidget {
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
  State<EventTeamsScreen> createState() => _EventTeamsScreenState();
}

class _EventTeamsScreenState extends State<EventTeamsScreen> {
  String _searchQuery = '';

  Set<int> get _assignedIds {
    return _eventTeamAssignments[widget.eventId] ?? <int>{};
  }

  int get _assignedCount => _assignedIds.length;

  /// Arama sonrası tüm takımlar
  List<UiTeamSummary> get _filteredAll {
    var list = List<UiTeamSummary>.from(_allDummyTeams);

    // arama
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.focus.toLowerCase().contains(q))
          .toList();
    }

    // Assigned olanları üstte göstersin diye sort
    list.sort((b, a) {
      final aAssigned = _assignedIds.contains(a.id);
      final bAssigned = _assignedIds.contains(b.id);
      if (aAssigned == bAssigned) {
        return a.name.compareTo(b.name);
      }
      return aAssigned ? -1 : 1;
    });

    return list;
  }

  List<UiTeamSummary> get _assignedTeams =>
      _filteredAll.where((t) => _assignedIds.contains(t.id)).toList();

  List<UiTeamSummary> get _availableTeams =>
      _filteredAll.where((t) => !_assignedIds.contains(t.id)).toList();

  void _toggleAssign(UiTeamSummary team) {
    setState(() {
      final set =
          _eventTeamAssignments.putIfAbsent(widget.eventId, () => <int>{});
      if (set.contains(team.id)) {
        set.remove(team.id); // UNASSIGN
      } else {
        set.add(team.id); // ASSIGN
      }
    });
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
    final assigned = _assignedTeams;
    final available = _availableTeams;

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
          title: Text('Assign teams – ${widget.eventName}'),
        ),
        body: Column(
          children: [
            // ---- Üst: arama + summary ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // summary
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pick which existing teams will participate in this event.',
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
                      labelText: 'Search teams by name or focus',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ---- Gövde: assigned card + available list ----
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Assigned teams card
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
                            'Assigned teams',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (assigned.isEmpty)
                            Text(
                              'No teams are assigned to this event yet.',
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
                                for (final team in assigned)
                                  _AssignedTeamChip(
                                    team: team,
                                    onUnassign: () {
                                      _toggleAssign(team);
                                      _showSnack(
                                        'Removed "${team.name}" from this event.',
                                      );
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Available header
                  const Text(
                    'Available teams',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (available.isEmpty)
                    const Text(
                      'No more teams available with current search.',
                      style: TextStyle(fontSize: 12),
                    )
                  else
                    ...[
                      const SizedBox(height: 4),
                      for (final team in available) ...[
                        _AvailableTeamCard(
                          team: team,
                          onAssign: () {
                            _toggleAssign(team);
                            _showSnack(
                              'Assigned "${team.name}" to this event.',
                            );
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

/// ---- Assigned team chip ----
class _AssignedTeamChip extends StatelessWidget {
  final UiTeamSummary team;
  final VoidCallback onUnassign;

  const _AssignedTeamChip({
    required this.team,
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
          const Icon(Icons.group_outlined, size: 14),
          const SizedBox(width: 6),
          Text(
            team.name,
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

/// ---- Available team card ----
class _AvailableTeamCard extends StatelessWidget {
  final UiTeamSummary team;
  final VoidCallback onAssign;

  const _AvailableTeamCard({
    required this.team,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capacity =
        team.maxMembers == 0 ? 0.0 : team.memberCount / team.maxMembers;

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
            // üst satır: isim + assign butonu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              team.focus,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${team.memberCount}/${team.maxMembers} members',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: capacity.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: theme.colorScheme.outlineVariant
                          .withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  capacity >= 1.0 ? 'Full' : 'Open',
                  style: TextStyle(
                    fontSize: 11,
                    color: capacity >= 1.0
                        ? Colors.red
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${team.sessionsCount} sessions • ${team.ideasCount} ideas',
              style: TextStyle(
                fontSize: 11,
                color:
                    theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
