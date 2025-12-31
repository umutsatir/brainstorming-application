import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/login_screen.dart'; // yolu projene göre düzelt
import '../../auth/controller/auth_controller.dart'; // yolu projene göre düzelt
import '../../../core/models/user.dart';
import '../../../core/enums/user_role.dart';

// import 'settings_change_name_screen.dart';
// import 'settings_change_password_screen.dart';

class SettingsScreen extends ConsumerWidget {
  final AppUser user;

  const SettingsScreen({super.key, required this.user});

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.eventManager:
        return 'Event Manager';
      case UserRole.teamLeader:
        return 'Team Leader';
      case UserRole.teamMember:
        return 'Team Member';
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text(
            'Are you sure you want to log out of the Brainstorming Application?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Log out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // 1) Auth state'i sıfırla
      await ref.read(authControllerProvider.notifier).logout();

      // 2) Tüm navigation stack'i temizleyip LoginScreen'e dön
      // (global davranış)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- ACCOUNT INFO ---
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (user.email != null && user.email!.isNotEmpty)
                          Text(
                            user.email!,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.75),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _roleLabel(user.role),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- ACCOUNT SETTINGS (NAME + PASSWORD) ---
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                // ListTile(
                //   leading: const Icon(Icons.person_outline),
                //   title: const Text('Change display name'),
                //   subtitle: const Text('Update how your name is shown'),
                //   onTap: () {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (_) => SettingsChangeNameScreen(
                //           currentName: user.name,
                //         ),
                //       ),
                //     );
                //   },
                // ),
                const Divider(height: 1),
                /*ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  subtitle: const Text('Update your account password'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsChangePasswordScreen(),
                      ),
                    );
                  },
                ),*/
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- LOGOUT (Danger zone) ---
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.error.withOpacity(0.30),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Log out from this account',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmLogout(context, ref),
                    child: Text(
                      'Log out',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
