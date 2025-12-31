import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

/// ------------------------------------------------------------
/// TOPICS
/// ------------------------------------------------------------

enum TopicStatus { open, inProgress, closed, archived }

TopicStatus _parseTopicStatus(dynamic raw) {
  final s = raw?.toString().toLowerCase() ?? '';
  if (s.contains('inprogress') || s.contains('in_progress')) {
    return TopicStatus.inProgress;
  }
  if (s.contains('closed') || s.contains('done') || s.contains('finished')) {
    return TopicStatus.closed;
  }
  if (s.contains('archived')) {
    return TopicStatus.archived;
  }
  return TopicStatus.open;
}

String _topicStatusToApi(TopicStatus status) {
  switch (status) {
    case TopicStatus.inProgress:
      return 'IN_PROGRESS';
    case TopicStatus.closed:
      return 'CLOSED';
    case TopicStatus.archived:
      return 'ARCHIVED';
    case TopicStatus.open:
    default:
      return 'OPEN';
  }
}

class UiTopicSummary {
  final int id;
  final String title;
  final String description;
  final String ownerName;
  final DateTime createdAt;
  final TopicStatus status;
  final int teamsCount;
  final int ideasCount;

  const UiTopicSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerName,
    required this.createdAt,
    required this.status,
    required this.teamsCount,
    required this.ideasCount,
  });

  factory UiTopicSummary.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['id'] ?? json['topicId'];
    final int id =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final title =
        (json['title'] ?? json['name'] ?? json['topicTitle'] ?? '').toString();

    final description =
        (json['description'] ?? json['summary'] ?? '').toString();

    final ownerName = (json['ownerName'] ??
            json['owner'] ??
            json['createdBy'] ??
            json['creatorName'] ??
            '')
        .toString();

    DateTime parseCreated(dynamic raw) {
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final createdAt =
        parseCreated(json['createdAt'] ?? json['created_at'] ?? json['created']);

    final status = _parseTopicStatus(
      json['status'] ?? json['topicStatus'] ?? json['state'],
    );

    final dynamic teamsRaw =
        json['teamsCount'] ?? json['teamCount'] ?? json['teams_used'] ?? 0;
    final int teamsCount =
        teamsRaw is int ? teamsRaw : int.tryParse(teamsRaw.toString()) ?? 0;

    final dynamic ideasRaw =
        json['ideasCount'] ?? json['ideaCount'] ?? json['totalIdeas'] ?? 0;
    final int ideasCount =
        ideasRaw is int ? ideasRaw : int.tryParse(ideasRaw.toString()) ?? 0;

    return UiTopicSummary(
      id: id,
      title: title,
      description: description,
      ownerName: ownerName,
      createdAt: createdAt,
      status: status,
      teamsCount: teamsCount,
      ideasCount: ideasCount,
    );
  }
}

/// ------------------------------------------------------------
/// EVENTS
/// ------------------------------------------------------------

enum EventStatus { planned, live, completed }

EventStatus _parseEventStatus(dynamic raw) {
  final s = raw?.toString().toLowerCase() ?? '';
  if (s.contains('live') || s.contains('running')) {
    return EventStatus.live;
  }
  if (s.contains('completed') || s.contains('done') || s.contains('finished')) {
    return EventStatus.completed;
  }
  // if (s.contains('archived')) {
  //   return EventStatus.archived;
  // }
  return EventStatus.planned;
}

class UiEventSummary {
  final int id;
  final String name;
  final String description;
  final String ownerName;
  final DateTime startDate;
  final DateTime endDate;
  final EventStatus status;
  final int topicsCount;
  final int teamsCount;
  final int sessionsCount;
  final int totalIdeas;

  const UiEventSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.topicsCount,
    required this.teamsCount,
    required this.sessionsCount,
    required this.totalIdeas,
  });

  factory UiEventSummary.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['id'] ?? json['eventId'];
    final int id =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final name =
        (json['name'] ?? json['title'] ?? json['eventName'] ?? '').toString();

    final description =
        (json['description'] ?? json['summary'] ?? '').toString();

    String extractOwnerName(dynamic raw) {
      if (raw is Map<String, dynamic>) {
        return (raw['fullName'] ??
                raw['name'] ??
                raw['displayName'] ??
                raw['email'] ??
                '')
            .toString();
      }
      return raw?.toString() ?? '';
    }

    final ownerName = extractOwnerName(
      json['ownerName'] ?? json['owner'] ?? json['organizer'],
    );

    DateTime parseDt(dynamic raw) {
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    final startDate =
        parseDt(json['startDate'] ?? json['start'] ?? json['starts_at']);
    final endDate = parseDt(json['endDate'] ?? json['end'] ?? json['ends_at']);

    final status = _parseEventStatus(
      json['status'] ?? json['eventStatus'] ?? json['state'],
    );

    final dynamic topicsRaw = json['topicsCount'] ?? json['topicCount'] ?? 0;
    final int topicsCount =
        topicsRaw is int ? topicsRaw : int.tryParse(topicsRaw.toString()) ?? 0;

    final dynamic teamsRaw = json['teamsCount'] ?? json['teamCount'] ?? 0;
    final int teamsCount =
        teamsRaw is int ? teamsRaw : int.tryParse(teamsRaw.toString()) ?? 0;

    final dynamic sessionsRaw =
        json['sessionsCount'] ?? json['sessionCount'] ?? 0;
    final int sessionsCount = sessionsRaw is int
        ? sessionsRaw
        : int.tryParse(sessionsRaw.toString()) ?? 0;

    final dynamic ideasRaw =
        json['totalIdeas'] ?? json['ideasCount'] ?? json['ideaCount'] ?? 0;
    final int totalIdeas =
        ideasRaw is int ? ideasRaw : int.tryParse(ideasRaw.toString()) ?? 0;

    return UiEventSummary(
      id: id,
      name: name,
      description: description,
      ownerName: ownerName,
      startDate: startDate,
      endDate: endDate,
      status: status,
      topicsCount: topicsCount,
      teamsCount: teamsCount,
      sessionsCount: sessionsCount,
      totalIdeas: totalIdeas,
    );
  }

  UiEventSummary copyWith({
    String? name,
    String? description,
    String? ownerName,
    DateTime? startDate,
    DateTime? endDate,
    EventStatus? status,
    int? topicsCount,
    int? teamsCount,
    int? sessionsCount,
    int? totalIdeas,
  }) {
    return UiEventSummary(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerName: ownerName ?? this.ownerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      topicsCount: topicsCount ?? this.topicsCount,
      teamsCount: teamsCount ?? this.teamsCount,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      totalIdeas: totalIdeas ?? this.totalIdeas,
    );
  }
}

/// ------------------------------------------------------------
/// SESSIONS + TEAMS MODELLER (senin önceki halinle aynı)
/// ------------------------------------------------------------

enum SessionStatus { scheduled, live, completed, cancelled }

SessionStatus _parseSessionStatus(dynamic raw) {
  final s = raw?.toString().toLowerCase() ?? '';
  if (s.contains('live') || s.contains('running')) {
    return SessionStatus.live;
  }
  if (s.contains('complete') || s.contains('finished') || s.contains('ended')) {
    return SessionStatus.completed;
  }
  if (s.contains('cancel')) {
    return SessionStatus.cancelled;
  }
  return SessionStatus.scheduled;
}

class UiEventSession {
  final int id;
  final int eventId;
  final String eventName;
  final String teamName;
  final String topicTitle;
  final String teamLeaderName;
  final int participantsCount;
  final SessionStatus status;
  final int totalRounds;
  final int completedRounds;
  final int ideasCount;
  final Duration roundDuration;
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool aiSummaryReady;

  const UiEventSession({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.teamName,
    required this.topicTitle,
    required this.teamLeaderName,
    required this.participantsCount,
    required this.status,
    required this.totalRounds,
    required this.completedRounds,
    required this.ideasCount,
    required this.roundDuration,
    this.scheduledFor,
    this.startedAt,
    this.endedAt,
    this.aiSummaryReady = false,
  });

  factory UiEventSession.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['id'] ?? json['sessionId'];
    final int id =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final dynamic eventIdRaw = json['eventId'] ?? json['event_id'];
    final int eventId = eventIdRaw is int
        ? eventIdRaw
        : int.tryParse(eventIdRaw?.toString() ?? '') ?? 0;

    final eventName =
        (json['eventName'] ?? json['event_title'] ?? json['event'] ?? '')
            .toString();

    final teamName =
        (json['teamName'] ?? json['team_name'] ?? json['team'] ?? '')
            .toString();

    final topicTitle = (json['topicTitle'] ??
            json['topic'] ??
            json['sessionTopic'] ??
            json['name'] ??
            '')
        .toString();

    final teamLeaderName = (json['teamLeaderName'] ??
            json['leaderName'] ??
            json['leader'] ??
            json['ownerName'] ??
            '')
        .toString();

    final dynamic participantsRaw = json['participantsCount'] ??
        json['memberCount'] ??
        json['participants'] ??
        0;
    final int participantsCount = participantsRaw is int
        ? participantsRaw
        : int.tryParse(participantsRaw.toString()) ?? 0;

    final status = _parseSessionStatus(
      json['status'] ?? json['sessionStatus'] ?? json['state'],
    );

    final dynamic totalRoundsRaw =
        json['roundCount'] ?? json['totalRounds'] ?? json['roundsPlanned'] ?? 0;
    final int totalRounds = totalRoundsRaw is int
        ? totalRoundsRaw
        : int.tryParse(totalRoundsRaw.toString()) ?? 0;

    final dynamic completedRoundsRaw = json['completedRounds'] ??
        json['roundsCompleted'] ??
        json['finishedRoundCount'] ??
        0;
    final int completedRounds = completedRoundsRaw is int
        ? completedRoundsRaw
        : int.tryParse(completedRoundsRaw.toString()) ?? 0;

    final dynamic ideasRaw =
        json['ideasCount'] ?? json['ideaCount'] ?? json['totalIdeas'] ?? 0;
    final int ideasCount =
        ideasRaw is int ? ideasRaw : int.tryParse(ideasRaw.toString()) ?? 0;

    final dynamic durRaw = json['roundDurationSeconds'] ??
        json['roundDurationSec'] ??
        json['round_duration_seconds'] ??
        300;
    final int durSeconds = durRaw is int
        ? durRaw
        : int.tryParse(durRaw.toString()) ?? 300;

    DateTime? parseDt(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    final scheduledFor =
        parseDt(json['scheduledFor'] ?? json['scheduled_at'] ?? json['scheduledAt']);
    final startedAt =
        parseDt(json['startedAt'] ?? json['started_at'] ?? json['sessionStart']);
    final endedAt = parseDt(json['endedAt'] ??
        json['ended_at'] ??
        json['completedAt'] ??
        json['sessionEnd']);

    final dynamic aiRaw = json['aiSummaryReady'] ??
        json['hasAiSummary'] ??
        json['ai_summary_ready'] ??
        false;
    final bool aiSummaryReady;
    if (aiRaw is bool) {
      aiSummaryReady = aiRaw;
    } else {
      aiSummaryReady = aiRaw.toString().toLowerCase() == 'true';
    }

    return UiEventSession(
      id: id,
      eventId: eventId,
      eventName: eventName,
      teamName: teamName,
      topicTitle: topicTitle,
      teamLeaderName: teamLeaderName,
      participantsCount: participantsCount,
      status: status,
      totalRounds: totalRounds,
      completedRounds: completedRounds,
      ideasCount: ideasCount,
      roundDuration: Duration(seconds: durSeconds),
      scheduledFor: scheduledFor,
      startedAt: startedAt,
      endedAt: endedAt,
      aiSummaryReady: aiSummaryReady,
    );
  }
}




/// ------------------------------------------------------------
/// PARTICIPANTS MODEL
/// ------------------------------------------------------------

enum ParticipantRole { eventManager, teamLeader, teamMember }

ParticipantRole _parseParticipantRole(dynamic raw) {
  final s = raw?.toString().toUpperCase() ?? '';
  if (s.contains('EVENT_MANAGER')) return ParticipantRole.eventManager;
  if (s.contains('TEAM_LEADER')) return ParticipantRole.teamLeader;
  return ParticipantRole.teamMember;
}

String _participantRoleToApi(ParticipantRole role) {
  switch (role) {
    case ParticipantRole.eventManager:
      return 'EVENT_MANAGER';
    case ParticipantRole.teamLeader:
      return 'TEAM_LEADER';
    case ParticipantRole.teamMember:
    default:
      return 'TEAM_MEMBER';
  }
}

enum ParticipantStatus { active, inactive, invited }

ParticipantStatus _parseParticipantStatus(dynamic raw) {
  final s = raw?.toString().toUpperCase() ?? '';
  if (s.contains('INACTIVE')) return ParticipantStatus.inactive;
  if (s.contains('INVITED')) return ParticipantStatus.invited;
  return ParticipantStatus.active;
}

String _participantStatusToApi(ParticipantStatus status) {
  switch (status) {
    case ParticipantStatus.inactive:
      return 'INACTIVE';
    case ParticipantStatus.invited:
      return 'INVITED';
    case ParticipantStatus.active:
    default:
      return 'ACTIVE';
  }
}



// --- MODEL ---


/// =======================================================
/// PARTICIPANT
/// =======================================================

class UiParticipantSummary {
  /// event_participants.id  (takıma eklerken kullanacağımız ID)
  final int id; // participantId
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? status;

  const UiParticipantSummary({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.status,
  });

  factory UiParticipantSummary.fromJson(Map<String, dynamic> json) {
    // event_participants.id
    final dynamic participantIdRaw = json['id'] ?? json['participantId'];
    final int participantId = participantIdRaw is int
        ? participantIdRaw
        : int.tryParse(participantIdRaw?.toString() ?? '') ?? 0;

    // users.id
    final dynamic userIdRaw = json['user_id'] ?? json['userId'];
    final int userId =
        userIdRaw is int ? userIdRaw : int.tryParse(userIdRaw?.toString() ?? '') ?? 0;

    final fullName = (json['fullName'] ??
            json['user_name'] ??
            json['name'] ??
            '')
        .toString();

    final email = (json['email'] ?? json['user_email'] ?? '').toString();
    final phone = (json['phone'] ?? json['phoneNumber'])?.toString();

    final role = (json['role_override'] ?? json['role'] ?? 'TEAM_MEMBER')
        .toString();

    final status = json['status']?.toString();

    return UiParticipantSummary(
      id: participantId,
      userId: userId,
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      status: status,
    );
  }
}

/// =======================================================
/// TEAM MEMBER (team içindeki satır)
/// =======================================================

class UiTeamMember {
  /// event_participants.id
  final int participantId;
  final int userId;
  final String fullName;
  final String email;

  const UiTeamMember({
    required this.participantId,
    required this.userId,
    required this.fullName,
    required this.email,
  });

  factory UiTeamMember.fromJson(Map<String, dynamic> json) {
    final dynamic pidRaw = json['id'] ?? json['participantId'];
    final int participantId = pidRaw is int
        ? pidRaw
        : int.tryParse(pidRaw?.toString() ?? '') ?? 0;

    final dynamic uidRaw = json['user_id'] ?? json['userId'];
    final int userId =
        uidRaw is int ? uidRaw : int.tryParse(uidRaw?.toString() ?? '') ?? 0;

    final fullName = (json['fullName'] ?? json['user_name'] ?? '').toString();
    final email = (json['email'] ?? json['user_email'] ?? '').toString();

    return UiTeamMember(
      participantId: participantId,
      userId: userId,
      fullName: fullName,
      email: email,
    );
  }
}

/// =======================================================
/// TEAM SUMMARY
/// =======================================================

class UiTeamSummary {
  final int id;
  final String name;
  final String focus;
  final int memberCount;
  final int maxMembers;
  final int ideasCount;
  final int sessionsCount;

  /// Team leader için event_participants.id
  final int leaderId;

  /// Bu team’in tüm üyeleri
  final List<UiTeamMember> members;

  const UiTeamSummary({
    required this.id,
    required this.name,
    required this.focus,
    required this.memberCount,
    required this.maxMembers,
    required this.ideasCount,
    required this.sessionsCount,
    required this.leaderId,
    required this.members,
  });

  factory UiTeamSummary.fromJson(Map<String, dynamic> json) {
    // ---- id, name, focus ----
    final dynamic idRaw = json['id'] ?? json['teamId'];
    final int id =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final name =
        (json['name'] ?? json['teamName'] ?? json['title'] ?? '').toString();

    final focus =
        (json['focus'] ?? json['description'] ?? json['topic'] ?? '')
            .toString();

    // ---- members ----
    List<UiTeamMember> members = [];
    final dynamic membersRaw =
        json['members'] ?? json['teamMembers'] ?? json['participants'];

    if (membersRaw is List) {
      members = membersRaw
          .whereType<Map<String, dynamic>>()
          .map(UiTeamMember.fromJson)
          .toList();
    } else if (membersRaw is Map<String, dynamic>) {
      final list = (membersRaw['members'] as List?) ??
          (membersRaw['participants'] as List?) ??
          const [];
      members = list
          .whereType<Map<String, dynamic>>()
          .map(UiTeamMember.fromJson)
          .toList();
    }

    // ---- memberCount ----
    final dynamic memberCountRaw = json['memberCount'] ?? json['members'];
    int memberCount;
    if (memberCountRaw is int) {
      memberCount = memberCountRaw;
    } else if (members.isNotEmpty) {
      memberCount = members.length;
    } else {
      memberCount =
          int.tryParse(memberCountRaw?.toString() ?? '') ?? members.length;
    }

    // ---- maxMembers ----
    final dynamic maxMembersRaw = json['maxMembers'] ?? json['capacity'] ?? 0;
    final int maxMembers = maxMembersRaw is int
        ? maxMembersRaw
        : int.tryParse(maxMembersRaw.toString()) ?? 0;

    // ---- ideasCount ----
    final dynamic ideasRaw =
        json['ideasCount'] ?? json['ideaCount'] ?? json['totalIdeas'] ?? 0;
    final int ideasCount =
        ideasRaw is int ? ideasRaw : int.tryParse(ideasRaw.toString()) ?? 0;

    // ---- sessionsCount ----
    final dynamic sessionsRaw =
        json['sessionsCount'] ?? json['sessionCount'] ?? 0;
    final int sessionsCount = sessionsRaw is int
        ? sessionsRaw
        : int.tryParse(sessionsRaw.toString()) ?? 0;

    // ---- leaderId (participantId veya userId’den birini gönderiyorsan burayla eşleştir) ----
    final dynamic leaderRaw =
        json['leaderParticipantId'] ?? json['leader_participant_id'] ??
            json['leader_id'] ?? json['leaderId'];
    final int leaderId =
        leaderRaw is int ? leaderRaw : int.tryParse(leaderRaw?.toString() ?? '') ?? 0;

    return UiTeamSummary(
      id: id,
      name: name,
      focus: focus,
      memberCount: memberCount,
      maxMembers: maxMembers,
      ideasCount: ideasCount,
      sessionsCount: sessionsCount,
      leaderId: leaderId,
      members: members,
    );
  }
}



/// ------------------------------------------------------------
/// REPOSITORY
/// ------------------------------------------------------------

class EventManagerRepository {
  final ApiClient _apiClient;

  EventManagerRepository(this._apiClient);

  // ---------------------------- SESSION EM ACTIONS ----------------------------

  Future<void> startSessionNow(int sessionId) async {
    final response = await _apiClient.post(
      '/event-manager/sessions/$sessionId/start',
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to start session $sessionId ($code).');
    }
  }

  Future<void> pauseSession(int sessionId) async {
    final response = await _apiClient.post(
      '/event-manager/sessions/$sessionId/pause',
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to pause session $sessionId ($code).');
    }
  }

  Future<void> forceEndSession(int sessionId) async {
    final response = await _apiClient.post(
      '/event-manager/sessions/$sessionId/force-end',
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to force-end session $sessionId ($code).');
    }
  }

  Future<void> cancelSession(int sessionId) async {
    final response = await _apiClient.post(
      '/event-manager/sessions/$sessionId/cancel',
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to cancel session $sessionId ($code).');
    }
  }

  Future<void> requestAiSummaryForSession(int sessionId) async {
    final response = await _apiClient.post(
      '/event-manager/sessions/$sessionId/request-ai-summary',
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to request AI summary for session $sessionId ($code).',
      );
    }
  }

  Future<void> deleteSessionRecord(int sessionId) async {
    final response = await _apiClient.delete(
      '/event-manager/sessions/$sessionId',
    );
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to delete session $sessionId ($code).');
    }
  }

  // ---------------------------- SESSIONS ----------------------------

  Future<List<UiEventSession>> getEventSessionsForEvent(int eventId) async {
    final response = await _apiClient.get(
      '/sessions',
      queryParameters: {'eventId': eventId},
    );

    if (response.statusCode == 200) {
      final data = response.data;
      List sessionsJson;
      if (data is List) {
        sessionsJson = data;
      } else if (data is Map<String, dynamic>) {
        sessionsJson =
            (data['sessions'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        sessionsJson = [];
      }

      sessionsJson = sessionsJson.where((raw) {
        if (raw is! Map<String, dynamic>) return true;
        final dynamic eRaw = raw['eventId'] ?? raw['event_id'];
        if (eRaw == null) return true;
        final parsed =
            eRaw is int ? eRaw : int.tryParse(eRaw.toString()) ?? -1;
        return parsed == eventId;
      }).toList();

      return sessionsJson
          .whereType<Map<String, dynamic>>()
          .map(UiEventSession.fromJson)
          .toList();
    }

    throw Exception(
      'Failed to load sessions for event $eventId (${response.statusCode}).',
    );
  }

  // ---------------------------- TEAMS (ESKİ GLOBAL) ----------------------------

  // Future<List<UiTeamSummary>> getAllTeams() async {
  //   final response = await _apiClient.get('/teams');

  //   if (response.statusCode == 200) {
  //     final data = response.data;

  //     List teamsJson;
  //     if (data is List) {
  //       teamsJson = data;
  //     } else if (data is Map<String, dynamic>) {
  //       teamsJson =
  //           (data['teams'] as List?) ?? (data['data'] as List?) ?? [];
  //     } else {
  //       teamsJson = [];
  //     }

  //     return teamsJson
  //         .whereType<Map<String, dynamic>>()
  //         .map(UiTeamSummary.fromJson)
  //         .toList();
  //   }

  //   throw Exception('Failed to load teams (${response.statusCode}).');
  // }

  // Future<Set<int>> getAssignedTeamIds(int eventId) async {
  //   final response = await _apiClient.get('/events/$eventId/teams');

  //   if (response.statusCode == 200) {
  //     final data = response.data;

  //     List teamsJson;
  //     if (data is List) {
  //       teamsJson = data;
  //     } else if (data is Map<String, dynamic>) {
  //       teamsJson =
  //           (data['teams'] as List?) ?? (data['data'] as List?) ?? [];
  //     } else {
  //       teamsJson = [];
  //     }

  //     final ids = <int>{};
  //     for (final raw in teamsJson) {
  //       if (raw is! Map<String, dynamic>) continue;
  //       final dynamic idRaw = raw['id'] ?? raw['teamId'];
  //       final int id =
  //           idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
  //       if (id > 0) ids.add(id);
  //     }
  //     return ids;
  //   }

  //   throw Exception(
  //     'Failed to load assigned teams for event $eventId (${response.statusCode}).',
  //   );
  // }

  // Future<void> assignTeamToEvent({
  //   required int eventId,
  //   required int teamId,
  // }) async {
  //   final response = await _apiClient.post(
  //     '/events/$eventId/teams',
  //     data: {'teamId': teamId},
  //   );

  //   final code = response.statusCode ?? 0;
  //   if (code != 200 && code != 201 && code != 204) {
  //     throw Exception(
  //       'Failed to assign team $teamId to event $eventId ($code).',
  //     );
  //   }
  // }

  // Future<void> unassignTeamFromEvent({
  //   required int eventId,
  //   required int teamId,
  // }) async {
  //   final response = await _apiClient.delete('/events/$eventId/teams/$teamId');

  //   final code = response.statusCode ?? 0;
  //   if (code < 200 || code >= 300) {
  //     throw Exception(
  //       'Failed to unassign team $teamId from event $eventId ($code).',
  //     );
  //   }
  // }

  // ---------------------------- PARTICIPANTS ----------------------------

// --- GET /participants?eventId=... ---
  /// EVENT-BAZLI PARTICIPANTS
  ///
  /// GET /participants?eventId=...
  Future<List<UiParticipantSummary>> getParticipantsForEvent(int eventId) async {
    final response = await _apiClient.get(
      '/participants',
      queryParameters: {'eventId': eventId},
    );

    if (response.statusCode == 200) {
      final data = response.data;

      List participantsJson;
      if (data is List) {
        participantsJson = data;
      } else if (data is Map<String, dynamic>) {
        participantsJson =
            (data['participants'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        participantsJson = [];
      }

      return participantsJson
          .whereType<Map<String, dynamic>>()
          .map(UiParticipantSummary.fromJson)
          .toList();
    }

    throw Exception(
      'Failed to load participants for event $eventId (${response.statusCode}).',
    );
  }

  /// GET /participants?eventId=..&teamId=..
  /// Bu event’te herhangi bir TAKIMA atanmış participant id’lerini döner.
  Future<Set<int>> getParticipantIdsInAnyTeamForEvent(int eventId) async {
    // 1) Önce tüm takımları al
    final teams = await getTeamsForEvent(eventId);
    final assignedIds = <int>{};

    for (final team in teams) {
      final resp = await _apiClient.get(
        '/participants',
        queryParameters: {
          'eventId': eventId,
          'teamId': team.id,
        },
      );

      if (resp.statusCode != 200) continue;

      final data = resp.data;
      List participantsJson;
      if (data is List) {
        participantsJson = data;
      } else if (data is Map<String, dynamic>) {
        participantsJson =
            (data['participants'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        participantsJson = [];
      }

      for (final raw in participantsJson) {
        if (raw is! Map<String, dynamic>) continue;
        final dynamic idRaw = raw['id'] ?? raw['participantId'];
        final pid =
            idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
        if (pid > 0) {
          assignedIds.add(pid);
        }
      }
    }

    return assignedIds;
  }


// --- POST /participants ---
  Future<UiParticipantSummary> createParticipantForEvent({
    required int eventId,
    required String fullName,
    required String email,
    String? phone,
    String role = 'TEAM_MEMBER', // default
  }) async {
    final body = <String, dynamic>{
      // camelCase versiyonlar (dokümandaki)
      'fullName': fullName,
      'email': email,
      'role': role,
      'eventId': eventId,
      // snake_case alias’lar (muhtemel backend DTO’su)
      'full_name': fullName,
      'event_id': eventId,
      // status çoğu tabloda zorunlu, default ACTIVE olsun
      'status': 'ACTIVE',
    };

    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
      body['phoneNumber'] = phone; // varsa böyle bir alan için
    }

    final response = await _apiClient.post(
      '/participants',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code == 200 || code == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UiParticipantSummary.fromJson(
          (data['participant'] as Map<String, dynamic>?) ?? data,
        );
      }
    }

    throw Exception('Failed to create participant for event $eventId ($code).');
  }


  /// PATCH /participants/{id}
  ///
  /// İletişim bilgisi, rol veya status güncelleme.
  Future<UiParticipantSummary> updateParticipant({
    required int participantId,
    String? fullName,
    String? phone,
    ParticipantRole? role,
    ParticipantStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (role != null) body['role'] = _participantRoleToApi(role);
    if (status != null) {
      body['status'] = _participantStatusToApi(status);
    }

    final response = await _apiClient.patch(
      '/participants/$participantId',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UiParticipantSummary.fromJson(
          (data['participant'] as Map<String, dynamic>?) ?? data,
        );
      }
    }

    throw Exception('Failed to update participant $participantId ($code).');
  }

  /// DELETE /participants/{id}
  Future<void> deleteParticipant(int participantId) async {
    final response = await _apiClient.delete('/participants/$participantId');

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to delete participant $participantId ($code).');
    }
  }





  // ---------------------------- TEAMS (YENİ: EVENT İÇİ CRUD) ----------------------------

  /// GET /events/{eventId}/teams
  /// Event içindeki takımların listesini (membership detaylı da olsa) özet olarak döner.
  Future<List<UiTeamSummary>> getTeamsForEvent(int eventId) async {
    final response = await _apiClient.get('/events/$eventId/teams');

    if (response.statusCode == 200) {
      final data = response.data;

      List teamsJson;
      if (data is List) {
        teamsJson = data;
      } else if (data is Map<String, dynamic>) {
        teamsJson =
            (data['teams'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        teamsJson = [];
      }

      return teamsJson
          .whereType<Map<String, dynamic>>()
          .map(UiTeamSummary.fromJson)
          .toList();
    }

    throw Exception(
      'Failed to load teams for event $eventId (${response.statusCode}).',
    );
  }

  /// POST /events/{eventId}/teams
  Future<void> createTeamForEvent({
    required int eventId,
    required String name,
    required int leaderId,
    required List<int> memberIds,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'leaderId': leaderId,
      'memberIds': memberIds,
    };

    final response = await _apiClient.post(
      '/events/$eventId/teams',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to create team in event $eventId ($code).',
      );
    }
  }

  /// PATCH /teams/{teamId}
  /// name / leaderId / addMembers[] / removeMembers[] gövdesi.
  Future<void> updateTeam({
    required int teamId,
    String? name,
    int? leaderId,
    List<int>? addMemberIds,
    List<int>? removeMemberIds,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (leaderId != null) body['leaderId'] = leaderId;
    if (addMemberIds != null && addMemberIds.isNotEmpty) {
      body['addMembers'] = addMemberIds;
    }
    if (removeMemberIds != null && removeMemberIds.isNotEmpty) {
      body['removeMembers'] = removeMemberIds;
    }

    if (body.isEmpty) {
      // Boş PATCH atmaya gerek yok
      return;
    }

    final response = await _apiClient.patch(
      '/teams/$teamId',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to update team $teamId ($code).');
    }
  }

  /// DELETE /teams/{teamId}
  Future<void> deleteTeam(int teamId) async {
    final response = await _apiClient.delete('/teams/$teamId');

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to delete team $teamId ($code).');
    }
  }

  /// POST /teams/{teamId}/members
  Future<void> addTeamMembers({
    required int teamId,
    required List<int> memberIds,
  }) async {
    final body = <String, dynamic>{
      'memberIds': memberIds,
    };

    final response = await _apiClient.post(
      '/teams/$teamId/members',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to add members to team $teamId ($code).',
      );
    }
  }

  /// DELETE /teams/{teamId}/members/{userId}
  Future<void> removeTeamMember({
    required int teamId,
    required int userId,
  }) async {
    final response = await _apiClient.delete(
      '/teams/$teamId/members/$userId',
    );

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to remove member $userId from team $teamId ($code).',
      );
    }
  }

  // ---------------------------- TOPICS (yeni, event-bazlı) ----------------------------

  /// GET /events/{eventId}/topics
  Future<List<UiTopicSummary>> getTopicsForEvent(int eventId) async {
    final response = await _apiClient.get('/events/$eventId/topics');

    if (response.statusCode == 200) {
      final data = response.data;

      List topicsJson;
      if (data is List) {
        topicsJson = data;
      } else if (data is Map<String, dynamic>) {
        topicsJson =
            (data['topics'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        topicsJson = [];
      }

      return topicsJson
          .whereType<Map<String, dynamic>>()
          .map(UiTopicSummary.fromJson)
          .toList();
    }

    throw Exception(
      'Failed to load topics for event $eventId (${response.statusCode}).',
    );
  }

  /// POST /events/{eventId}/topics
  Future<UiTopicSummary> createTopicForEvent({
    required int eventId,
    required String title,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'title': title,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    final response = await _apiClient.post(
      '/events/$eventId/topics',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code == 200 || code == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UiTopicSummary.fromJson(
          (data['topic'] as Map<String, dynamic>?) ?? data,
        );
      }
    }

    throw Exception('Failed to create topic for event $eventId ($code).');
  }

  /// PATCH /topics/{topicId}
  Future<UiTopicSummary> updateTopic({
    required int topicId,
    String? title,
    String? description,
    TopicStatus? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = _topicStatusToApi(status);

    final response = await _apiClient.patch(
      '/topics/$topicId',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UiTopicSummary.fromJson(
          (data['topic'] as Map<String, dynamic>?) ?? data,
        );
      }
    }

    throw Exception('Failed to update topic $topicId ($code).');
  }

  /// Convenience: status = ARCHIVED
  Future<void> archiveTopic(int topicId) async {
    await updateTopic(
      topicId: topicId,
      status: TopicStatus.archived,
    );
  }

  /// DELETE /topics/{topicId}
  Future<void> deleteTopic(int topicId) async {
    final response = await _apiClient.delete('/topics/$topicId');

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception('Failed to delete topic $topicId ($code).');
    }
  }

  // ---------------------------- EVENTS ----------------------------

  Future<List<UiEventSummary>> getAllEvents() async {
    final response = await _apiClient.get('/events');

    if (response.statusCode == 200) {
      final data = response.data;

      List eventsJson;
      if (data is List) {
        eventsJson = data;
      } else if (data is Map<String, dynamic>) {
        eventsJson =
            (data['events'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        eventsJson = [];
      }

      return eventsJson
          .whereType<Map<String, dynamic>>()
          .map(UiEventSummary.fromJson)
          .toList();
    }

    throw Exception('Failed to load events (${response.statusCode}).');
  }

  Future<UiEventSummary> createEvent({
    required String name,
    required String description,
    required String ownerName,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
    };

    if (startDate != null) {
      body['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      body['endDate'] = endDate.toIso8601String();
    }

    final response = await _apiClient.post(
      '/events',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code == 200 || code == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UiEventSummary.fromJson(
          (data['event'] as Map<String, dynamic>?) ?? data,
        );
      }
    }

    throw Exception('Failed to create event ($code).');
  }

  Future<UiEventSummary> updateEvent({
    required int eventId,
    String? name,
    String? description,
    String? ownerName,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (ownerName != null) body['ownerName'] = ownerName;

    final response = await _apiClient.put(
      '/events/$eventId',
      data: body,
    );

    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return UiEventSummary.fromJson(
          (data['event'] as Map<String, dynamic>?) ?? data,
        );
      }
    }

    throw Exception(
      'Failed to update event $eventId ($code).',
    );
  }

  Future<void> archiveEvent(int eventId) async {
    final response = await _apiClient.post('/events/$eventId/archive');

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to archive event $eventId ($code).',
      );
    }
  }

  Future<void> deleteEvent(int eventId) async {
    final response = await _apiClient.delete('/events/$eventId');

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to delete event $eventId ($code).',
      );
    }
  }
}

final eventManagerRepositoryProvider =
    Provider<EventManagerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventManagerRepository(apiClient);
});
