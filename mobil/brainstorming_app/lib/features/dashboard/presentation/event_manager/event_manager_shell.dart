import 'package:brainstorming_app/features/settings/prestentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/login_screen.dart';
import '../../../auth/controller/auth_controller.dart';

import '../../../../core/models/user.dart';
import '../../../../core/enums/user_role.dart';

import '../../../events/presentation/events_overview_screen.dart';
import '../../../teams/presentation/team_management_screen.dart';
import '../../../participants/presentation/participants_screen.dart';
import '../../../reports/presentation/reports_screen.dart';

import 'event_manager_overview_screen.dart';

/// Event Manager için hamburger menülü ana shell.
/// Menüden: Overview, Events, Topics, Teams, Participants, Reports & Settings sayfalarına geçiyoruz.
class EventManagerShell extends StatefulWidget {
  final AppUser user;

  EventManagerShell({super.key, required this.user})
      : assert(user.role == UserRole.eventManager);

  @override
  State<EventManagerShell> createState() => _EventManagerShellState();
}

class _EventManagerShellState extends State<EventManagerShell> {
  int _selectedIndex = 0;

  String get _title {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'Events';
      // // case 2:
      // //   return 'Topics';
      // case 2:
      //   return 'Teams';
      case 3:
        return 'Participants';
      case 4:
        return 'Reports & AI Summaries';
      case 5:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.of(context).pop(); // drawer'ı kapat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Drawer olduğu için otomatik hamburger ikonunu gösteriyor
        title: Text(_title),
      ),
      drawer: _EventManagerDrawer(
        user: widget.user,
        selectedIndex: _selectedIndex,
        onSelect: _onSelect,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 0 - Overview
          EventManagerOverviewScreen(user: widget.user),

          // 1 - Events list
          const EventsOverviewScreen(),

          // 2 - Global Topics list (event bağımsız master topics)
          // const TopicsManagementScreen(),

          // 3 - Global Teams management
          // const TeamManagementScreen(),

          // 4 - Participants
          const ParticipantsScreen(),

          // 5 - Reports & AI Summaries
          const ReportsScreen(),

          // 6 - Settings (event manager account + logout)
          SettingsScreen(user: widget.user),
        ],
      ),
    );
  }
}

class _EventManagerDrawer extends StatelessWidget {
  final AppUser user;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _EventManagerDrawer({
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
            // Kullanıcı bilgisi
            UserAccountsDrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'E',
                ),
              ),
              accountName: Text(user.name),
              accountEmail: Text(user.email ?? ''),
            ),

            // Menü
            Expanded(
              child: ListView(
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard,
                    title: 'Overview',
                    isSelected: selectedIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _DrawerItem(
                    icon: Icons.event,
                    title: 'Events',
                    isSelected: selectedIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  // _DrawerItem(
                  //   icon: Icons.lightbulb_outline,
                  //   title: 'Topics',
                  //   isSelected: selectedIndex == 2,
                  //   onTap: () => onSelect(2),
                  // ),
                  // _DrawerItem(
                  //   icon: Icons.groups_2_outlined,
                  //   title: 'Teams',
                  //   isSelected: selectedIndex == 2,
                  //   onTap: () => onSelect(2),
                  // ),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    title: 'Participants',
                    isSelected: selectedIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                  _DrawerItem(
                    icon: Icons.analytics,
                    title: 'Reports & AI Summaries',
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
