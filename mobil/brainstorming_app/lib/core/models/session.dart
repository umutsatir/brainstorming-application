class SessionModel {
  final int id;
  final int eventId;
  final int teamId;
  final String status; // CREATED | STARTED | PAUSED | COMPLETED
  final int currentRound;
  final int totalRounds;
  final int roundDurationSeconds;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  SessionModel({
    required this.id,
    required this.eventId,
    required this.teamId,
    required this.status,
    required this.currentRound,
    required this.totalRounds,
    required this.roundDurationSeconds,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as int,
      eventId: json['eventId'] as int,
      teamId: json['teamId'] as int,
      status: json['status'] as String? ?? 'CREATED',
      currentRound: json['currentRound'] as int? ?? 0,
      totalRounds: json['totalRounds'] as int? ?? 5,
      roundDurationSeconds: json['roundDurationSeconds'] as int? ?? 300,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'teamId': teamId,
      'status': status,
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'roundDurationSeconds': roundDurationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
