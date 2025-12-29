import 'package:brainstorming_app/features/settings/prestentation/settings_screen.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';
import '../../../../core/enums/user_role.dart';

// 6-3-5 leader live session ekranı
import '../../../live_session/presentation/leader_session_screen.dart';

// Team leader UI ekranları
import 'team_leader_overview_screen.dart';
import 'team_leader_session_history_screen.dart';
import 'team_leader_my_team_screen.dart';

/// ------------------------------------------------------------
/// TEAM LEADER SHELL
/// ------------------------------------------------------------

class TeamLeaderShell extends StatefulWidget {
  final AppUser user;

  TeamLeaderShell({super.key, required this.user})
      : assert(user.role == UserRole.teamLeader);

  @override
  State<TeamLeaderShell> createState() => _TeamLeaderShellState();
}

class _TeamLeaderShellState extends State<TeamLeaderShell> {
  int _selectedIndex = 0;

  // Şimdilik dummy config – Phase 3’te backend’den gelecek
  late final UiLeaderLiveSessionConfig _dummySessionConfig;

  @override
  void initState() {
    super.initState();

    _dummySessionConfig = const UiLeaderLiveSessionConfig(
      sessionId: 1,
      teamId: 42,
      eventName: 'Q1 Growth Strategy 6-3-5',
      topicTitle: 'Increase user engagement for mobile app',
      teamName: 'Growth Squad Alpha',
      teamSize: 6,
      totalRounds: 5,
      roundDurationSeconds: 300, // 5 dk
    );
  }

  String get _title {
    switch (_selectedIndex) {
      case 0:
        return 'Team Leader Overview';
      case 1:
        return 'Current Session';
      case 2:
        return 'Session History';
      case 3:
        return 'My Team';
      case 4:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  void _goToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSelectFromDrawer(int index) {
    _goToTab(index);
    Navigator.of(context).pop(); // drawer'ı kapat
  }

  /// History’den “Go to live session” gelince çağrılacak
  void _openLiveSessionFromHistory(UiLeaderSessionHistoryItem item) {
    setState(() {
      _selectedIndex = 1; // Current Session tab
      // Phase 3’te: seçilen item.sessionId’yi state/providera yazıp,
      // LeaderSessionScreen config’ini dinamik yapacağız.
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Opening live session #${item.sessionId} (dummy – Current Session tab).',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Drawer olduğu için otomatik hamburger ikonunu gösteriyor
        title: Text(_title),
      ),
      drawer: _TeamLeaderDrawer(
        user: widget.user,
        selectedIndex: _selectedIndex,
        onSelect: _onSelectFromDrawer,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0 - Overview
          TeamLeaderOverviewScreen(
            user: widget.user,
            onOpenCurrentSession: () => _goToTab(1),
            onOpenHistory: () => _goToTab(2),
            onOpenMyTeam: () => _goToTab(3),
          ),

          // 1 - Current Session (Leader live session)
          LeaderSessionScreen(config: _dummySessionConfig),

          // 2 - Session History
          TeamLeaderSessionHistoryScreen(
            onOpenLiveSession: _openLiveSessionFromHistory,
          ),

          // 3 - My Team
          const TeamLeaderMyTeamScreen(),

          // 4 - Settings (logout’lu)
          SettingsScreen(user: widget.user),
        ],
      ),
    );
  }
}

class _TeamLeaderDrawer extends StatelessWidget {
  final AppUser user;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TeamLeaderDrawer({
    required this.user,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T',
                ),
              ),
              accountName: Text(user.name),
              accountEmail: Text(user.email ?? ''),
            ),
            Expanded(
              child: ListView(
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Overview',
                    isSelected: selectedIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _DrawerItem(
                    icon: Icons.play_circle_fill_outlined,
                    title: 'Current Session',
                    isSelected: selectedIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  _DrawerItem(
                    icon: Icons.history,
                    title: 'Session History',
                    isSelected: selectedIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _DrawerItem(
                    icon: Icons.group,
                    title: 'My Team',
                    isSelected: selectedIndex == 3,
                    onTap: () => onSelect(3),
                  ),
                  const Divider(),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isSelected: selectedIndex == 4,
                    onTap: () => onSelect(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.7);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
