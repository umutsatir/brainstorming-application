import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';

/// ------------------------------------------------------------
/// SESSION HISTORY ITEM (leader history screen için)
/// ------------------------------------------------------------
class UiLeaderSessionHistoryItem {
  final int sessionId;
  final String topicTitle;
  final String eventName;
  final DateTime startedAt;
  final int totalRounds;
  final int completedRounds;
  final int totalIdeas;
  final bool isCompleted;

  const UiLeaderSessionHistoryItem({
    required this.sessionId,
    required this.topicTitle,
    required this.eventName,
    required this.startedAt,
    required this.totalRounds,
    required this.completedRounds,
    required this.totalIdeas,
    required this.isCompleted,
  });

  /// Backend JSON → UI modeli
  ///
  /// Burayı olabildiğince toleranslı tuttuk; backend'de
  /// alan isimleri biraz farklı olsa da çoğunu yakalayabilsin.
  factory UiLeaderSessionHistoryItem.fromJson(Map<String, dynamic> json) {
    // id / sessionId
    final dynamic idRaw = json['id'] ?? json['sessionId'];
    final int sessionId =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    // topic / başlık
    final topicTitle = (json['topicTitle'] ??
            json['topic'] ??
            json['sessionTopic'] ??
            json['name'] ?? // sadece "name" alanı varsa
            '')
        .toString();

    // event adı (v1 backend'de eventName yoksa name'den de gelebilir)
    final eventName =
        (json['eventName'] ?? json['event_title'] ?? json['event'] ?? '')
            .toString();

    // başlangıç zamanı
    final startedRaw =
        json['startedAt'] ?? json['started_at'] ?? json['createdAt'];
    DateTime startedAt = DateTime.now();
    if (startedRaw is String) {
      startedAt = DateTime.tryParse(startedRaw) ?? DateTime.now();
    }

    // round sayıları (yoksa 0/0 kalır)
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

    // toplam idea
    final dynamic ideasRaw =
        json['totalIdeas'] ?? json['ideaCount'] ?? json['ideasTotal'] ?? 0;
    final int totalIdeas =
        ideasRaw is int ? ideasRaw : int.tryParse(ideasRaw.toString()) ?? 0;

    // status → completed mi?
    final statusStr =
        (json['status'] ?? json['sessionStatus'] ?? '').toString().toLowerCase();

    final bool isCompleted =
        statusStr == 'completed' ||
        statusStr == 'ended' ||
        statusStr == 'finished' ||
        (totalRounds > 0 && completedRounds >= totalRounds);

    return UiLeaderSessionHistoryItem(
      sessionId: sessionId,
      topicTitle: topicTitle,
      eventName: eventName,
      startedAt: startedAt,
      totalRounds: totalRounds,
      completedRounds: completedRounds,
      totalIdeas: totalIdeas,
      isCompleted: isCompleted,
    );
  }
}

/// ------------------------------------------------------------
/// MEMBER – MY SESSIONS (History item modeli)
/// ------------------------------------------------------------
class UiMemberSessionHistoryItem {
  final int sessionId;
  final String topicTitle;
  final String eventName;
  final DateTime startedAt;
  final int contributedIdeas;
  final bool isCompleted;

  const UiMemberSessionHistoryItem({
    required this.sessionId,
    required this.topicTitle,
    required this.eventName,
    required this.startedAt,
    required this.contributedIdeas,
    required this.isCompleted,
  });

  /// Backend JSON → UI modeli (esnek)
  factory UiMemberSessionHistoryItem.fromJson(Map<String, dynamic> json) {
    // id / sessionId
    final dynamic idRaw = json['id'] ?? json['sessionId'];
    final int sessionId =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    // topic / başlık
    final topicTitle =
        (json['topicTitle'] ?? json['topic'] ?? json['sessionTopic'] ?? '')
            .toString();

    // event adı
    final eventName =
        (json['eventName'] ?? json['event_title'] ?? json['event'] ?? '')
            .toString();

    // başlangıç zamanı
    final startedRaw =
        json['startedAt'] ?? json['started_at'] ?? json['createdAt'];
    DateTime startedAt = DateTime.now();
    if (startedRaw is String) {
      startedAt = DateTime.tryParse(startedRaw) ?? DateTime.now();
    }

    // kullanıcının katkı verdiği fikir sayısı
    final dynamic contributedRaw = json['contributedIdeas'] ??
        json['myIdeaCount'] ??
        json['ideasByYou'] ??
        json['ideaCount'] ??
        0;
    final int contributedIdeas = contributedRaw is int
        ? contributedRaw
        : int.tryParse(contributedRaw.toString()) ?? 0;

    // status → completed mi?
    final statusStr =
        (json['status'] ?? json['sessionStatus'] ?? '').toString().toLowerCase();

    final bool isCompleted = statusStr == 'completed' ||
        statusStr == 'ended' ||
        statusStr == 'finished';

    return UiMemberSessionHistoryItem(
      sessionId: sessionId,
      topicTitle: topicTitle,
      eventName: eventName,
      startedAt: startedAt,
      contributedIdeas: contributedIdeas,
      isCompleted: isCompleted,
    );
  }
}

/// ------------------------------------------------------------
/// LEADER LIVE SESSION STATE (LeaderSessionScreen için)
/// ------------------------------------------------------------
/// GET /api/sessions/{id} veya kontrol endpointlerinin
/// döndürdüğü “session state” DTO’sunu UI tarafına map etmek için.
class LeaderLiveSessionState {
  final int sessionId;
  final String status; // "PENDING" | "RUNNING" | "PAUSED" | "COMPLETED" ...
  final int currentRound;
  final int roundCount;
  final int timerRemainingSeconds;

  const LeaderLiveSessionState({
    required this.sessionId,
    required this.status,
    required this.currentRound,
    required this.roundCount,
    required this.timerRemainingSeconds,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isRunning => status.toUpperCase() == 'RUNNING';
  bool get isPaused => status.toUpperCase() == 'PAUSED';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory LeaderLiveSessionState.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['id'] ?? json['sessionId'];
    final int sessionId =
        idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0;

    final status =
        (json['status'] ?? json['sessionStatus'] ?? 'PENDING').toString();

    final dynamic currentRoundRaw =
        json['currentRound'] ?? json['roundNumber'] ?? 0;
    final int currentRound = currentRoundRaw is int
        ? currentRoundRaw
        : int.tryParse(currentRoundRaw.toString()) ?? 0;

    final dynamic roundCountRaw =
        json['roundCount'] ?? json['totalRounds'] ?? json['roundsPlanned'] ?? 0;
    final int roundCount = roundCountRaw is int
        ? roundCountRaw
        : int.tryParse(roundCountRaw.toString()) ?? 0;

    final dynamic timerRaw =
        json['timerRemaining'] ?? json['timerRemainingSeconds'] ?? 0;
    final int timerRemainingSeconds = timerRaw is int
        ? timerRaw
        : int.tryParse(timerRaw.toString()) ?? 0;

    return LeaderLiveSessionState(
      sessionId: sessionId,
      status: status,
      currentRound: currentRound,
      roundCount: roundCount,
      timerRemainingSeconds: timerRemainingSeconds,
    );
  }
}

/// ------------------------------------------------------------
/// SESSION REPOSITORY
/// ------------------------------------------------------------
class SessionRepository {
  final ApiClient _apiClient;

  SessionRepository(this._apiClient);

  /// LEADER – belirli bir takımın oturumları
  ///
  /// V1 backend’e göre:
  ///   GET /api/sessions  → tüm session’lar
  ///
  /// Burada:
  ///  - önce tüm session listesini çekiyoruz,
  ///  - sonra JSON içindeki teamId / team_id alanına göre
  ///    client-side filtre yapıyoruz.
  Future<List<UiLeaderSessionHistoryItem>> getTeamSessions(int teamId) async {
    final response = await _apiClient.get('/api/sessions');

    if (response.statusCode == 200) {
      final data = response.data;

      List sessionsJson;
      if (data is List) {
        sessionsJson = data;
      } else if (data is Map<String, dynamic>) {
        // { "sessions": [...] } veya { "data": [...] } olabilir
        sessionsJson =
            (data['sessions'] as List?) ?? (data['data'] as List?) ?? [];
      } else {
        sessionsJson = [];
      }

      // Eğer backend JSON'da teamId bilgisi varsa,
      // sadece o takıma ait olanları gösterelim.
      sessionsJson = sessionsJson.where((raw) {
        if (raw is! Map<String, dynamic>) return true;

        final teamRaw = raw['teamId'] ?? raw['team_id'];
        if (teamRaw == null) {
          // Backend teamId göndermiyorsa, filtre uygulamadan bırak.
          return true;
        }

        final parsedTeamId = teamRaw is int
            ? teamRaw
            : int.tryParse(teamRaw.toString()) ?? -1;

        return parsedTeamId == teamId;
      }).toList();

      return sessionsJson
          .map((e) =>
              UiLeaderSessionHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load sessions (${response.statusCode}).');
  }

  /// MEMBER – current user’ın katıldığı oturumlar
  ///
  /// GET /api/sessions
  ///  - Backend JWT’den current user’ı okuyup
  ///    sadece katıldığı session’ları döndürebilir.
  ///  - İstersen query param da kullanabilirsin (memberScope=joined).
  Future<List<UiMemberSessionHistoryItem>> getMySessions() async {
    final response = await _apiClient.get(
      '/api/sessions',
      queryParameters: {
        'memberScope': 'joined', // backend ister kullanır ister ignore eder
      },
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

      return sessionsJson
          .map(
            (e) =>
                UiMemberSessionHistoryItem.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception('Failed to load member sessions (${response.statusCode}).');
  }

  /// GET /api/sessions/{sessionId}
  /// → canlı session state’i al (currentRound, status, timerRemaining vs.)
  Future<LeaderLiveSessionState> getLiveSessionState(int sessionId) async {
    final response = await _apiClient.get('/api/sessions/$sessionId');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return LeaderLiveSessionState.fromJson(data);
      }
    }

    throw Exception('Failed to load session $sessionId');
  }

  /// ŞU AN KULLANDIĞIN backend’e göre:
  ///   POST /api/sessions/{id}/start
  ///   POST /api/sessions/{id}/pause
  ///   POST /api/sessions/{id}/complete
  ///
  /// action:
  ///   "START"  → /start
  ///   "RESUME" → /start   (pause'dan devam için)
  ///   "PAUSE"  → /pause
  ///   "END"    → /complete
  Future<LeaderLiveSessionState> controlSession({
    required int sessionId,
    required String action,
  }) async {
    final String upper = action.toUpperCase();

    late final String path;
    if (upper == 'START' || upper == 'RESUME') {
      path = '/api/sessions/$sessionId/start';
    } else if (upper == 'PAUSE') {
      path = '/api/sessions/$sessionId/pause';
    } else if (upper == 'END' || upper == 'COMPLETE') {
      path = '/api/sessions/$sessionId/complete';
    } else {
      throw ArgumentError('Unsupported action: $action');
    }

    final response = await _apiClient.post(path);

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return LeaderLiveSessionState.fromJson(data);
      }
    }

    throw Exception(
      'Failed to $action session $sessionId (${response.statusCode})',
    );
  }

  /// NOT: V1 backend listende round / AI endpoint’i yok.
  /// Aşağıdaki iki metodu şimdilik dokunmadan bırakıyorum;
  /// ileride backend’e eklendiğinde gerçekten bağlayabilirsin.

  /// POST /sessions/{sessionId}/rounds/advance
  Future<LeaderLiveSessionState> advanceRound(int sessionId) async {
    final response =
        await _apiClient.post('/api/sessions/$sessionId/rounds/advance');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return LeaderLiveSessionState.fromJson(data);
      }
    }

    throw Exception(
      'Failed to advance round for session $sessionId (${response.statusCode})',
    );
  }

  /// POST /ai/sessions/{sessionId}/suggestions
  Future<void> requestAiSuggestions({
    required int sessionId,
    required int roundNumber,
  }) async {
    final response = await _apiClient.post(
      '/api/ai/sessions/$sessionId/suggestions',
      data: {
        'roundNumber': roundNumber,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception(
        'Failed to request AI suggestions (${response.statusCode})',
      );
    }
  }
}

/// Riverpod provider – hem leader hem member buradan kullanacak
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SessionRepository(apiClient);
});

/// Member history ekranı için FutureProvider
final memberSessionsFutureProvider =
    FutureProvider<List<UiMemberSessionHistoryItem>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getMySessions();
});
