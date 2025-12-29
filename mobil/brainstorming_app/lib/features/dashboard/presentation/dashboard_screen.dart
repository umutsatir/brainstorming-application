
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/enums/user_role.dart';

import 'event_manager/event_manager_shell.dart';
import 'team_leader/team_leader_shell.dart';
import 'team_member/team_member_shell.dart';

class DashboardScreen extends ConsumerWidget {
  final AppUser user;

  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // EVENT MANAGER İÇİN YENİ SHELL
    if (user.role == UserRole.eventManager) {
      return EventManagerShell(user: user);
    }
    else if (user.role == UserRole.teamLeader) {
    return TeamLeaderShell(user: user); 
}
  else if (user.role == UserRole.teamMember) {
      return TeamMemberShell(user: user);
    }
    else {
      return const Scaffold(
        body: Center(
          child: Text('Unknown user role.'),
        ),
      );
    }  
  }
}