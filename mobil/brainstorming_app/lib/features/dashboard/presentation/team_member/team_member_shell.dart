import 'package:flutter/material.dart';

import '../../../../core/models/user.dart';
import '../../../../core/enums/user_role.dart';

// Global Settings
import '../../../settings/prestentation/settings_screen.dart';
// Member UI ekranları
import 'member_overview_screen.dart';
import 'member_session_history_screen.dart';
import 'member_live_session_screen.dart';

/// ------------------------------------------------------------
/// TEAM MEMBER SHELL
/// ------------------------------------------------------------

class TeamMemberShell extends StatefulWidget {
  final AppUser user;

   TeamMemberShell({super.key, required this.user})
      : assert(user.role == UserRole.teamMember);

  @override
  State<TeamMemberShell> createState() => _TeamMemberShellState();
}

class _TeamMemberShellState extends State<TeamMemberShell> {
  int _selectedIndex = 0;

  // Şimdilik dummy – Phase 3’te backend’den gelecek
  // "aktif" / "upcoming" session bilgisi MemberOverview + Live ekranında kullanılacak.
  // Burada sadece live screen için basit bir flag ve title tutuyoruz.
  bool get _hasActiveSession => true; // dummy: her zaman aktif varsayalım

  String get _title {
    switch (_selectedIndex) {
      case 0:
        return 'Member Overview';
      case 1:
        return 'Live Session';
      case 2:
        return 'My Sessions';
      case 3:
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      drawer: _TeamMemberDrawer(
        user: widget.user,
        selectedIndex: _selectedIndex,
        onSelect: _onSelectFromDrawer,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0 - Overview (member giriş ekranı)
          MemberOverviewScreen(
            user: widget.user,
            hasActiveSession: _hasActiveSession,
            // Current session’a git
            onGoToLiveSession: () => _goToTab(1),
            // History ekranına git
            onOpenHistory: () => _goToTab(2),
            // Settings’e git
            onOpenSettings: () => _goToTab(3),
          ),

          // 1 - Live Session (member canlı ekranı – şu an placeholder)
          const MemberLiveSessionScreen(),

          // 2 - My Sessions (member session history)
          const MemberSessionHistoryScreen(),

          // 3 - Settings (global)
          SettingsScreen(user: widget.user),
        ],
      ),
    );
  }
}

class _TeamMemberDrawer extends StatelessWidget {
  final AppUser user;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TeamMemberDrawer({
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
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'M',
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
                    title: 'Live Session',
                    isSelected: selectedIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  _DrawerItem(
                    icon: Icons.history,
                    title: 'My Sessions',
                    isSelected: selectedIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  const Divider(),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    isSelected: selectedIndex == 3,
                    onTap: () => onSelect(3),
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
