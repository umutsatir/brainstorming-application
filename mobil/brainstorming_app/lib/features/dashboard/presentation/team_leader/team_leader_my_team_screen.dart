import 'package:flutter/material.dart';

/// ------------------------------------------------------------
/// MY TEAM – UX’Lİ LİSTE
/// ------------------------------------------------------------

enum TeamMemberStatus { ready, invited, offline }

class UiTeamMemberSummary {
  final int id;
  final String name;
  final String email;
  final TeamMemberStatus status;

  const UiTeamMemberSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  UiTeamMemberSummary copyWith({
    int? id,
    String? name,
    String? email,
    TeamMemberStatus? status,
  }) {
    return UiTeamMemberSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }
}

// Dummy takım – Phase 3’te backend /teams/{id}/members’dan gelecek
const List<UiTeamMemberSummary> _dummyTeamMembers = [
  UiTeamMemberSummary(
    id: 1,
    name: 'Alex Morgan',
    email: 'alex.morgan@example.com',
    status: TeamMemberStatus.ready,
  ),
  UiTeamMemberSummary(
    id: 2,
    name: 'Mia Johnson',
    email: 'mia.johnson@example.com',
    status: TeamMemberStatus.ready,
  ),
  UiTeamMemberSummary(
    id: 3,
    name: 'Oliver Smith',
    email: 'oliver.smith@example.com',
    status: TeamMemberStatus.invited,
  ),
  UiTeamMemberSummary(
    id: 4,
    name: 'Lucas White',
    email: 'lucas.white@example.com',
    status: TeamMemberStatus.offline,
  ),
  UiTeamMemberSummary(
    id: 5,
    name: 'Emma Brown',
    email: 'emma.brown@example.com',
    status: TeamMemberStatus.ready,
  ),
];

class TeamLeaderMyTeamScreen extends StatefulWidget {
  const TeamLeaderMyTeamScreen({super.key});

  @override
  State<TeamLeaderMyTeamScreen> createState() =>
      _TeamLeaderMyTeamScreenState();
}

class _TeamLeaderMyTeamScreenState extends State<TeamLeaderMyTeamScreen> {
  String _searchQuery = '';
  TeamMemberStatus? _statusFilter; // null -> All

  /// Gerçek hayatta: GET /teams/{teamId}/members cevabı
  late List<UiTeamMemberSummary> _members;

  @override
  void initState() {
    super.initState();
    // Dummy data’yı mutable listeye kopyala
    _members = List<UiTeamMemberSummary>.from(_dummyTeamMembers);
  }

  List<UiTeamMemberSummary> get _filtered {
    var list = List<UiTeamMemberSummary>.from(_members);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((m) =>
              m.name.toLowerCase().contains(q) ||
              m.email.toLowerCase().contains(q))
          .toList();
    }

    if (_statusFilter != null) {
      list = list.where((m) => m.status == _statusFilter).toList();
    }

    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  String _statusLabel(TeamMemberStatus status) {
    switch (status) {
      case TeamMemberStatus.ready:
        return 'Ready';
      case TeamMemberStatus.invited:
        return 'Invited';
      case TeamMemberStatus.offline:
        return 'Offline';
    }
  }

  Color _statusColor(TeamMemberStatus status, BuildContext context) {
    switch (status) {
      case TeamMemberStatus.ready:
        return Colors.green;
      case TeamMemberStatus.invited:
        return Colors.orange;
      case TeamMemberStatus.offline:
        return Colors.grey;
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onInviteMember() async {
    // Gerçekte:
    // - POST /teams/{teamId}/invitations
    // - Backend join link / code üretir
    // - Burada share sheet veya copy to clipboard açarsın
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite a new team member',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'In the real app, this will send an email invitation or '
                  'generate a join link / team code using the backend.',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.link),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dummy join code: TEAM-XYZ-123',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onResendInvite(UiTeamMemberSummary member) async {
    // TODO: backend
    // POST /teams/{teamId}/members/{memberId}/resend-invite
    _showSnack('Resent invitation to ${member.email} (dummy).');
  }

  Future<void> _onRemoveMember(UiTeamMemberSummary member) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove member'),
          content: Text(
            'Are you sure you want to remove ${member.name} from this team?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // TODO: backend
      // DELETE /teams/{teamId}/members/{member.id}
      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });
      _showSnack('${member.name} removed from team (dummy).');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final members = _filtered;

    final total = _members.length;
    final readyCount =
        _members.where((m) => m.status == TeamMemberStatus.ready).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary line + Invite button
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          '$total members',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$readyCount ready',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _onInviteMember,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text(
                      'Invite member',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, size: 20),
                        hintText: 'Search by name or email',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (_) {
                      setState(() => _statusFilter = null);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Ready'),
                    selected: _statusFilter == TeamMemberStatus.ready,
                    onSelected: (_) {
                      setState(() => _statusFilter = TeamMemberStatus.ready);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Invited'),
                    selected: _statusFilter == TeamMemberStatus.invited,
                    onSelected: (_) {
                      setState(() => _statusFilter = TeamMemberStatus.invited);
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Offline'),
                    selected: _statusFilter == TeamMemberStatus.offline,
                    onSelected: (_) {
                      setState(() => _statusFilter = TeamMemberStatus.offline);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: members.isEmpty
              ? const Center(
                  child: Text(
                    'No team members match your filters.\nTry changing search or status.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final color = _statusColor(m.status, context);

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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  child: Text(
                                    m.name.isNotEmpty
                                        ? m.name[0].toUpperCase()
                                        : '?',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme.onSurface
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 8,
                                              color: color,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _statusLabel(m.status),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Resend invite sadece invited olanlar için aktif
                                OutlinedButton.icon(
                                  onPressed: m.status ==
                                          TeamMemberStatus.invited
                                      ? () => _onResendInvite(m)
                                      : null,
                                  icon: const Icon(Icons.mail_outline, size: 18),
                                  label: const Text(
                                    'Resend invite',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _onRemoveMember(m),
                                  icon: const Icon(
                                    Icons.person_remove_alt_1_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Remove from team',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
