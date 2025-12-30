import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/teams/team_repository.dart ';
/// ------------------------------------------------------------
/// MY TEAM – BACKEND ENTEGRE EKRAN (TeamRepository ile)
/// ------------------------------------------------------------

class TeamLeaderMyTeamScreen extends ConsumerStatefulWidget {
  const TeamLeaderMyTeamScreen({super.key});

  @override
  ConsumerState<TeamLeaderMyTeamScreen> createState() =>
      _TeamLeaderMyTeamScreenState();
}

class _TeamLeaderMyTeamScreenState
    extends ConsumerState<TeamLeaderMyTeamScreen> {
  String _searchQuery = '';
  TeamMemberStatus? _statusFilter; // null -> All

  /// Gerçek backend datası
  List<UiTeamMemberSummary> _members = [];

  bool _isLoading = false;
  String? _errorMessage;

  // TODO: Şimdilik sabit. İleride TeamLeaderShell’den parametre olarak al.
  final int _teamId = 1;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(teamRepositoryProvider);
      final members = await repo.getTeamMembers(_teamId);

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load team members: $e';
      });
    }
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

  /// Invite flow – şu anda sadece bilgi sheet’i.
  /// Backend entegrasyonu için TeamRepository.inviteMember kullanabilirsin.
  Future<void> _onInviteMember() async {
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
                  'In the real app, this will call the backend invitation '
                  'endpoint and send an email or generate a join link / team code.',
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

    // İleride:
    // final repo = ref.read(teamRepositoryProvider);
    // await repo.inviteMember(_teamId, email: '...');
    // sonra _fetchMembers() ile listeyi yenileyebilirsin.
  }

  /// Resend invite – backend’e POST atan versiyon
  Future<void> _onResendInvite(UiTeamMemberSummary member) async {
    try {
      final repo = ref.read(teamRepositoryProvider);
      await repo.resendInvite(_teamId, member.id);
      _showSnack('Resent invitation to ${member.email}.');
    } catch (e) {
      _showSnack('Failed to resend invite: $e');
    }
  }

  /// Remove member – backend delete
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

    if (result != true) return;

    try {
      final repo = ref.read(teamRepositoryProvider);
      await repo.removeMember(_teamId, member.id);

      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });

      _showSnack('${member.name} removed from team.');
    } catch (e) {
      _showSnack('Failed to remove member: $e');
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
        // Üst filtre + summary
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

              // Hata / loading göstergesi
              if (_isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(minHeight: 2),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchMembers,
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: members.isEmpty
              ? _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Center(
                      child: Text(
                        'No team members match your filters.\n'
                        'Try changing search or status.',
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
