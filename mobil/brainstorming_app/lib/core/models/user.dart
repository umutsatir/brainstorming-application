import '../enums/user_role.dart';

class AppUser {
  final String id;
  final String name; // fullName
  final String? email;
  final UserRole role;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      // Auth endpointlerinde fullName geçiyor
      name: json['fullName'] ??
          json['name'] ??
          json['username'] ??
          '',
      email: json['email'],
      role: _parseRole(json['role']),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'email': email,
      'role': role.name, // backend değerlerine göre gerekirse mapping
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static UserRole _parseRole(dynamic value) {
    final v = value?.toString().toUpperCase() ?? '';
    switch (v) {
      case 'EVENT_MANAGER':
        return UserRole.eventManager;
      case 'TEAM_LEADER':
        return UserRole.teamLeader;
      case 'TEAM_MEMBER':
      default:
        return UserRole.teamMember;
    }
  }
}
