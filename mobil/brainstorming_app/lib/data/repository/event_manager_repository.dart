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

enum EventStatus { planned, live, completed, archived }

EventStatus _parseEventStatus(dynamic raw) {
  final s = raw?.toString().toLowerCase() ?? '';
  if (s.contains('live') || s.contains('running')) {
    return EventStatus.live;
  }
  if (s.contains('completed') || s.contains('done') || s.contains('finished')) {
    return EventStatus.completed;
  }
  if (s.contains('archived')) {
    return EventStatus.archived;
  }
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

    // owner: ya direkt string, ya da nested object olabilir.
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
    final endDate =
        parseDt(json['endDate'] ?? json['end'] ?? json['ends_at']);

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
/// SESSIONS + TEAMS MODELLER (eskisiyle aynı bıraktım)
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

class UiTeamSummary {
  final int id;
  final String name;
  final String focus;
  final int memberCount;
  final int maxMembers;
  final int ideasCount;
  final int sessionsCount;

  const UiTeamSummary({
    required this.id,
    required this.name,
    required this.focus,
    required this.memberCount,
    required this.maxMembers,
    required this.ideasCount,
    required this.sessionsCount,
  });

  factory UiTeamSummary.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['id'] ?? json['teamId'];
    final int id =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final name =
        (json['name'] ?? json['teamName'] ?? json['title'] ?? '').toString();

    final focus =
        (json['focus'] ?? json['description'] ?? json['topic'] ?? '')
            .toString();

    final dynamic memberCountRaw =
        json['memberCount'] ?? json['members'] ?? 0;
    final int memberCount = memberCountRaw is int
        ? memberCountRaw
        : int.tryParse(memberCountRaw.toString()) ?? 0;

    final dynamic maxMembersRaw =
        json['maxMembers'] ?? json['capacity'] ?? 0;
    final int maxMembers = maxMembersRaw is int
        ? maxMembersRaw
        : int.tryParse(maxMembersRaw.toString()) ?? 0;

    final dynamic ideasRaw =
        json['ideasCount'] ?? json['ideaCount'] ?? json['totalIdeas'] ?? 0;
    final int ideasCount =
        ideasRaw is int ? ideasRaw : int.tryParse(ideasRaw.toString()) ?? 0;

    final dynamic sessionsRaw =
        json['sessionsCount'] ?? json['sessionCount'] ?? 0;
    final int sessionsCount = sessionsRaw is int
        ? sessionsRaw
        : int.tryParse(sessionsRaw.toString()) ?? 0;

    return UiTeamSummary(
      id: id,
      name: name,
      focus: focus,
      memberCount: memberCount,
      maxMembers: maxMembers,
      ideasCount: ideasCount,
      sessionsCount: sessionsCount,
    );
  }
}

/// ------------------------------------------------------------
/// REPOSITORY
/// ------------------------------------------------------------

class EventManagerRepository {
  final ApiClient _apiClient;

  EventManagerRepository(this._apiClient);

  // ---------------------------- SESSIONS ----------------------------

  Future<List<UiEventSession>> getEventSessionsForEvent(int eventId) async {
    final response = await _apiClient.get(
      '//api/sessions',
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

  // ---------------------------- TEAMS ----------------------------

  Future<List<UiTeamSummary>> getAllTeams() async {
    final response = await _apiClient.get('//api/teams');

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

    throw Exception('Failed to load teams (${response.statusCode}).');
  }

  Future<Set<int>> getAssignedTeamIds(int eventId) async {
    final response = await _apiClient.get('/api/events/$eventId/teams');

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

      final ids = <int>{};
      for (final raw in teamsJson) {
        if (raw is! Map<String, dynamic>) continue;
        final dynamic idRaw = raw['id'] ?? raw['teamId'];
        final int id =
            idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
        if (id > 0) ids.add(id);
      }
      return ids;
    }

    throw Exception(
      'Failed to load assigned teams for event $eventId (${response.statusCode}).',
    );
  }

  Future<void> assignTeamToEvent({
    required int eventId,
    required int teamId,
  }) async {
    final response = await _apiClient.post(
      '/api/events/$eventId/teams',
      data: {'teamId': teamId},
    );

    final code = response.statusCode ?? 0;
    if (code != 200 && code != 201 && code != 204) {
      throw Exception(
        'Failed to assign team $teamId to event $eventId ($code).',
      );
    }
  }

  Future<void> unassignTeamFromEvent({
    required int eventId,
    required int teamId,
  }) async {
    final response = await _apiClient.delete('/api/events/$eventId/teams/$teamId');

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to unassign team $teamId from event $eventId ($code).',
      );
    }
  }

  // ---------------------------- TOPICS ----------------------------

  Future<List<UiTopicSummary>> getAllTopics() async {
    final response = await _apiClient.get('/api/topics');

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

    throw Exception('Failed to load topics (${response.statusCode}).');
  }

  Future<Set<int>> getAssignedTopicIds(int eventId) async {
    final response = await _apiClient.get('/api/events/$eventId/topics');

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

      final ids = <int>{};
      for (final raw in topicsJson) {
        if (raw is! Map<String, dynamic>) continue;
        final dynamic idRaw = raw['id'] ?? raw['topicId'];
        final int id =
            idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;
        if (id > 0) ids.add(id);
      }
      return ids;
    }

    throw Exception(
      'Failed to load assigned topics for event $eventId '
      '(${response.statusCode}).',
    );
  }

  Future<void> assignTopicToEvent({
    required int eventId,
    required int topicId,
  }) async {
    final response = await _apiClient.post(
      '/api/events/$eventId/topics',
      data: {'topicId': topicId},
    );

    final code = response.statusCode ?? 0;
    if (code != 200 && code != 201 && code != 204) {
      throw Exception(
        'Failed to assign topic $topicId to event $eventId ($code).',
      );
    }
  }

  Future<void> unassignTopicFromEvent({
    required int eventId,
    required int topicId,
  }) async {
    final response =
        await _apiClient.delete('/api/events/$eventId/topics/$topicId');

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw Exception(
        'Failed to unassign topic $topicId from event $eventId ($code).',
      );
    }
  }

  // ---------------------------- EVENTS ----------------------------

  Future<List<UiEventSummary>> getAllEvents() async {
    final response = await _apiClient.get('/api/events');

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
  }) async {
    final response = await _apiClient.post(
      '/api/events',
      data: {
        'name': name,
        'description': description,
        // ownerId backend tarafında JWT’den çekilsin, burada göndermiyoruz.
      },
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
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    final response = await _apiClient.put(
      '/api/events/$eventId',
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
    final response = await _apiClient.post('/api/events/$eventId/archive');

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
