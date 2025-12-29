import 'package:flutter/material.dart';

/// ---- UI MODEL ----

enum ParticipantRole { eventManager, teamLeader, member }

class UiParticipantSummary {
  final int id;
  final String name;
  final String email;
  final ParticipantRole role;
  final bool isActive;

  const UiParticipantSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });
}

/// ---- DUMMY DATA (şimdilik backend yerine) ----
/// NOT: Gerçekte bunlar API/DB'den gelecek.
const List<UiParticipantSummary> kDummyParticipants = [
  UiParticipantSummary(
    id: 1,
    name: 'Alex Morgan',
    email: 'alex.morgan@example.com',
    role: ParticipantRole.eventManager,
    isActive: true,
  ),
  UiParticipantSummary(
    id: 2,
    name: 'Alice Smith',
    email: 'alice.smith@example.com',
    role: ParticipantRole.teamLeader,
    isActive: true,
  ),
  UiParticipantSummary(
    id: 3,
    name: 'Bob Jones',
    email: 'bob.jones@example.com',
    role: ParticipantRole.member,
    isActive: true,
  ),
  UiParticipantSummary(
    id: 4,
    name: 'Elena Koshka',
    email: 'elena.koshka@example.com',
    role: ParticipantRole.member,
    isActive: false,
  ),
  UiParticipantSummary(
    id: 5,
    name: 'Michael Chen',
    email: 'michael.chen@example.com',
    role: ParticipantRole.teamLeader,
    isActive: true,
  ),
  UiParticipantSummary(
    id: 6,
    name: 'Sarah Jenkins',
    email: 'sarah.jenkins@example.com',
    role: ParticipantRole.member,
    isActive: true,
  ),
];

/// ---- EKRAN ----

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  // DB’den gelen tam liste
  List<UiParticipantSummary> _participants = [];

  bool _isLoading = true;
  String? _loadError;

  String _searchQuery = '';
  ParticipantRole? _roleFilter; // null -> all
  String? _statusFilter; // "Active" / "Inactive" / null
  String _sortKey = 'Name (A-Z)';

  @override
  void initState() {
    super.initState();
    _loadParticipantsFromBackend();
  }

  /// Buraya kendi API çağrını koyacaksın.
  Future<List<UiParticipantSummary>> _fetchParticipantsFromBackend() async {
    // TODO: REST / GraphQL / Supabase vs. ile gerçek veriyi çek
    // Örnek: final response = await http.get(...); parse JSON -> UiParticipantSummary
    await Future.delayed(const Duration(milliseconds: 400));
    return kDummyParticipants;
  }

  Future<void> _loadParticipantsFromBackend() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await _fetchParticipantsFromBackend();
      setState(() {
        _participants = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Failed to load participants.';
        _isLoading = false;
      });
    }
  }

  List<UiParticipantSummary> get _filteredParticipants {
    var list = List<UiParticipantSummary>.from(_participants);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.email.toLowerCase().contains(q))
          .toList();
    }

    if (_roleFilter != null) {
      list = list.where((p) => p.role == _roleFilter).toList();
    }

    if (_statusFilter != null) {
      final active = _statusFilter == 'Active';
      list = list.where((p) => p.isActive == active).toList();
    }

    switch (_sortKey) {
      case 'Name (Z-A)':
        list.sort((b, a) => a.name.compareTo(b.name));
        break;
      case 'Role':
        list.sort((a, b) => _roleLabel(a.role).compareTo(_roleLabel(b.role)));
        break;
      case 'Name (A-Z)':
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return list;
  }

  int get _totalParticipants => _participants.length;
  int get _totalActive =>
      _participants.where((p) => p.isActive).length;
  int get _totalLeaders => _participants
      .where((p) => p.role == ParticipantRole.teamLeader)
      .length;

  String _roleLabel(ParticipantRole role) {
    switch (role) {
      case ParticipantRole.eventManager:
        return 'Event Manager';
      case ParticipantRole.teamLeader:
        return 'Team Leader';
      case ParticipantRole.member:
        return 'Member';
    }
  }

  Color _roleChipColor(ParticipantRole role, BuildContext context) {
    final theme = Theme.of(context);
    switch (role) {
      case ParticipantRole.eventManager:
        return theme.colorScheme.primary.withOpacity(0.12);
      case ParticipantRole.teamLeader:
        return Colors.blue.withOpacity(0.12);
      case ParticipantRole.member:
        return Colors.deepPurple.withOpacity(0.10);
    }
  }

  Color _roleTextColor(ParticipantRole role, BuildContext context) {
    final theme = Theme.of(context);
    switch (role) {
      case ParticipantRole.eventManager:
        return theme.colorScheme.primary;
      case ParticipantRole.teamLeader:
        return Colors.blue[700] ?? Colors.blue;
      case ParticipantRole.member:
        return Colors.deepPurple[700] ?? Colors.deepPurple;
    }
  }

  /// ---------- FILTERS SHEET ----------
  Future<void> _openFiltersSheet() async {
    final role = _roleFilter;
    final status = _statusFilter;
    final sortKey = _sortKey;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        ParticipantRole? tempRole = role;
        String? tempStatus = status;
        String tempSort = sortKey;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return SafeArea(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ---- ROLE ----
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Role',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: tempRole == null,
                              onSelected: (_) =>
                                  setModalState(() => tempRole = null),
                            ),
                            ChoiceChip(
                              label: const Text('Event Manager'),
                              selected:
                                  tempRole == ParticipantRole.eventManager,
                              onSelected: (_) => setModalState(
                                () =>
                                    tempRole = ParticipantRole.eventManager,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Team Leader'),
                              selected:
                                  tempRole == ParticipantRole.teamLeader,
                              onSelected: (_) => setModalState(
                                () =>
                                    tempRole = ParticipantRole.teamLeader,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Member'),
                              selected: tempRole == ParticipantRole.member,
                              onSelected: (_) => setModalState(
                                () => tempRole = ParticipantRole.member,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ---- STATUS ----
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: tempStatus == null,
                              onSelected: (_) =>
                                  setModalState(() => tempStatus = null),
                            ),
                            ChoiceChip(
                              label: const Text('Active'),
                              selected: tempStatus == 'Active',
                              onSelected: (_) =>
                                  setModalState(() => tempStatus = 'Active'),
                            ),
                            ChoiceChip(
                              label: const Text('Inactive'),
                              selected: tempStatus == 'Inactive',
                              onSelected: (_) =>
                                  setModalState(() => tempStatus = 'Inactive'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ---- SORT ----
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Sort by',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Column(
                          children: [
                            RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Name (A-Z)'),
                              value: 'Name (A-Z)',
                              groupValue: tempSort,
                              onChanged: (v) => setModalState(
                                  () => tempSort = v ?? tempSort),
                            ),
                            RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Name (Z-A)'),
                              value: 'Name (Z-A)',
                              groupValue: tempSort,
                              onChanged: (v) => setModalState(
                                  () => tempSort = v ?? tempSort),
                            ),
                            RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Role'),
                              value: 'Role',
                              groupValue: tempSort,
                              onChanged: (v) => setModalState(
                                  () => tempSort = v ?? tempSort),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempRole = null;
                                  tempStatus = null;
                                  tempSort = 'Name (A-Z)';
                                });
                              },
                              child: const Text('Reset'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _roleFilter = tempRole;
                                  _statusFilter = tempStatus;
                                  _sortKey = tempSort;
                                });
                                Navigator.of(context).pop();
                              },
                              child: const Text('Apply'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return  Scaffold(
        appBar: AppBar(
          title: Text('Participants'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Participants'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadParticipantsFromBackend,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final participants = _filteredParticipants;

    return Scaffold(
      appBar:  AppBar(
        title: Text('Participants'),
      ),
      body: Column(
        children: [
          // HEADER: compact summary + search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Column(
              children: [
                // Top stats tek satır
                Row(
                  children: [
                    Text(
                      '$_totalParticipants participants',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_totalActive active',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_totalLeaders leaders',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Search + filters ikon
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search, size: 20),
                          hintText: 'Search by name or email',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _openFiltersSheet,
                      tooltip: 'Filters & sort',
                      icon: const Icon(Icons.tune),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // LİSTE
          Expanded(
            child: participants.isEmpty
                ? const Center(
                    child: Text(
                      'No participants match your filters.\n'
                      'Try changing search or filters.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: participants.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      return _ParticipantCard(
                        participant: p,
                        roleLabel: _roleLabel(p.role),
                        roleChipColor: _roleChipColor(p.role, context),
                        roleTextColor: _roleTextColor(p.role, context),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// ---- KART (sadece görüntü, event manager editleyemez) ----

class _ParticipantCard extends StatelessWidget {
  final UiParticipantSummary participant;
  final String roleLabel;
  final Color roleChipColor;
  final Color roleTextColor;

  const _ParticipantCard({
    required this.participant,
    required this.roleLabel,
    required this.roleChipColor,
    required this.roleTextColor,
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(
                participant.name.isNotEmpty
                    ? participant.name[0].toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    participant.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleChipColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: roleTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (participant.isActive
                                  ? Colors.green
                                  : Colors.grey)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: participant.isActive
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              participant.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: participant.isActive
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // İstersen buraya ileride "View profile" gibi sadece read-only
            // bir action ekleyebilirsin; şimdilik boş.
          ],
        ),
      ),
    );
  }
}
