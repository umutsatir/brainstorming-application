import '../enums/user_role.dart';

class AppUser {
  final int id;
  final String name;        // fullName backend'den geliyor, biz name'e mapliyoruz
  final String email;
  final String? phone;
  final UserRole role;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: userRoleFromApi(json['role'] as String),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,               // dikkat: field name -> fullName
      'email': email,
      'phone': phone,
      'role': userRoleToApi(role),    // 'TEAM_MEMBER' vs
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
