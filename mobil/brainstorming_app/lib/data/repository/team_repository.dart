import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

/// ------------------------------------------------------------
/// TEAM REPOSITORY + MODEL
/// ------------------------------------------------------------

/// Backend'ten gelen member status'ünü UI'de kullanacağımız enum'a çeviriyoruz.
enum TeamMemberStatus { ready, invited, offline }

class UiTeamMemberSummary {
  final int id;
  final String name;
  final String email;
  final TeamMemberStatus status;

  const UiTeamMemberSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
  });

  UiTeamMemberSummary copyWith({
    int? id,
    String? name,
    String? email,
    TeamMemberStatus? status,
  }) {
    return UiTeamMemberSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
    );
  }

  /// Backend JSON → UI modeli
  ///
  /// OOD dokümanına göre alanlar:
  /// - "id" veya "memberId"
  /// - "fullName" veya "name"
  /// - "email"
  /// - "status" veya "memberStatus"
  factory UiTeamMemberSummary.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] ?? json['memberStatus'];
    return UiTeamMemberSummary(
      id: int.parse(
        (json['id'] ?? json['memberId']).toString(),
      ),
      name: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      status: _parseStatus(rawStatus),
    );
  }

  static TeamMemberStatus _parseStatus(dynamic value) {
    final v = value?.toString().toLowerCase() ?? '';
    if (v.contains('ready') || v.contains('active') || v.contains('joined')) {
      return TeamMemberStatus.ready;
    }
    if (v.contains('invite') || v.contains('pending')) {
      return TeamMemberStatus.invited;
    }
    return TeamMemberStatus.offline;
  }
}

/// ------------------------------------------------------------
/// TEAM REPOSITORY
/// ------------------------------------------------------------

class TeamRepository {
  final ApiClient _apiClient;

  TeamRepository(this._apiClient);

  /// GET /api/teams/{teamId}/members
  ///
  /// Backend cevabı:
  /// - direkt List olabilir
  /// - veya { "members": [...] } / { "data": [...] } şeklinde olabilir
  Future<List<UiTeamMemberSummary>> getTeamMembers(int teamId) async {
    final response = await _apiClient.get('/api/teams/$teamId/members');

    if (response.statusCode == 200) {
      final data = response.data;

      List membersJson;
      if (data is List) {
        membersJson = data;
      } else if (data is Map<String, dynamic>) {
        membersJson =
            (data['members'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        membersJson = [];
      }

      return membersJson
          .map((e) => UiTeamMemberSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      'Failed to load team members (${response.statusCode}).',
    );
  }

  /// POST /api/teams/{teamId}/invitations
  ///
  /// Şimdilik email opsiyonel. İleride formdan email alıp buraya verebilirsin.
  Future<void> inviteMember(int teamId, {String? email}) async {
    final response = await _apiClient.post(
      '/api/teams/$teamId/invitations',
      data: email != null && email.isNotEmpty
          ? {
              'email': email,
            }
          : null,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw Exception(
        'Failed to invite member (${response.statusCode}).',
      );
    }
  }

  /// POST /api/teams/{teamId}/members/{memberId}/resend-invite
  Future<void> resendInvite(int teamId, int memberId) async {
    final response = await _apiClient.post(
      '/api/teams/$teamId/members/$memberId/resend-invite',
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to resend invite (${response.statusCode}).',
      );
    }
  }

  /// DELETE /api/teams/{teamId}/members/{memberId}
  Future<void> removeMember(int teamId, int memberId) async {
    final response = await _apiClient.delete(
      '/api/teams/$teamId/members/$memberId',
    );

    if (response.statusCode != 200 &&
        response.statusCode != 202 &&
        response.statusCode != 204) {
      throw Exception(
        'Failed to remove member (${response.statusCode}).',
      );
    }
  }
}

/// Riverpod provider
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TeamRepository(apiClient);
});
