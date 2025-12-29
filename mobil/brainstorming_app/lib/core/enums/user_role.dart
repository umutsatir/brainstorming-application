enum UserRole {
  eventManager,
  teamLeader,
  teamMember,
}

UserRole userRoleFromApi(String value) {
  switch (value) {
    case 'EVENT_MANAGER':
      return UserRole.eventManager;
    case 'TEAM_LEADER':
      return UserRole.teamLeader;
    case 'TEAM_MEMBER':
      return UserRole.teamMember;
    default:
      // default olarak member gibi davran
      return UserRole.teamMember;
  }
}

String userRoleToApi(UserRole role) {
  switch (role) {
    case UserRole.eventManager:
      return 'EVENT_MANAGER';
    case UserRole.teamLeader:
      return 'TEAM_LEADER';
    case UserRole.teamMember:
      return 'TEAM_MEMBER';
  }
}
