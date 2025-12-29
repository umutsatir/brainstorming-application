import 'package:flutter/material.dart';

class UiTeam {
  final int id;
  final String name;
  final String description;
  final String department; // örn: Product, Marketing
  final int memberCount;
  final String status; // Active, On Hold, Archived
  final List<UiTeamMember> members;

  UiTeam({
    required this.id,
    required this.name,
    required this.description,
    required this.department,
    required this.memberCount,
    required this.status,
    required this.members,
  });
}

class UiTeamMember {
  final String name;
  final String role; // Team Leader, Member vs.
  final bool isLeader;

  UiTeamMember({
    required this.name,
    required this.role,
    this.isLeader = false,
  });
}

/// Dummy takımlar – şimdilik backend yerine bunları gösteriyoruz.
final List<UiTeam> dummyTeams = [
  UiTeam(
    id: 1,
    name: 'Growth Squad',
    description: 'Focuses on acquisition funnels and activation experiments.',
    department: 'Product',
    memberCount: 6,
    status: 'Active',
    members: [
      UiTeamMember(name: 'Alice Johnson', role: 'Team Leader', isLeader: true),
      UiTeamMember(name: 'Mert Certel', role: 'Product Designer'),
      UiTeamMember(name: 'John Doe', role: 'Backend Engineer'),
      UiTeamMember(name: 'Sarah Lee', role: 'Frontend Engineer'),
      UiTeamMember(name: 'Emma Brown', role: 'Data Analyst'),
      UiTeamMember(name: 'Tom Parker', role: 'Marketing Specialist'),
    ],
  ),
  UiTeam(
    id: 2,
    name: 'Onboarding Experience',
    description: 'Improves first-time user journey and tutorials.',
    department: 'UX',
    memberCount: 4,
    status: 'Active',
    members: [
      UiTeamMember(name: 'David Kim', role: 'Team Leader', isLeader: true),
      UiTeamMember(name: 'Julia White', role: 'UX Researcher'),
      UiTeamMember(name: 'Chris Evans', role: 'Mobile Engineer'),
      UiTeamMember(name: 'Nina Roberts', role: 'Content Designer'),
    ],
  ),
  UiTeam(
    id: 3,
    name: 'Internal Tools',
    description: 'Maintains admin dashboards and analytics tooling.',
    department: 'Engineering',
    memberCount: 5,
    status: 'On Hold',
    members: [
      UiTeamMember(name: 'Mark Green', role: 'Team Leader', isLeader: true),
      UiTeamMember(name: 'Liam Scott', role: 'Full-stack Engineer'),
      UiTeamMember(name: 'Olivia Hill', role: 'DevOps'),
      UiTeamMember(name: 'Isabella Clark', role: 'QA Engineer'),
      UiTeamMember(name: 'Noah Turner', role: 'Support Engineer'),
    ],
  ),
];

Color teamStatusChipColor(String status, BuildContext context) {
  final theme = Theme.of(context);
  switch (status.toLowerCase()) {
    case 'active':
      return Colors.green.withOpacity(0.15);
    case 'on hold':
      return Colors.orange.withOpacity(0.15);
    case 'archived':
      return theme.colorScheme.error.withOpacity(0.15);
    default:
      return theme.colorScheme.surfaceContainerHighest.withOpacity(0.7);
  }
}

Color teamStatusTextColor(String status, BuildContext context) {
  switch (status.toLowerCase()) {
    case 'active':
      return Colors.green;
    case 'on hold':
      return Colors.orange;
    case 'archived':
      return Theme.of(context).colorScheme.error;
    default:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
