// lib/core/models/event.dart
class Event {
  final int id;
  final String name;
  final String? description;

  // Planlanan zaman + süre
  final DateTime? scheduledAt;
  final int? durationMinutes;

  // Gerçek oturum başlangıç/bitiş
  final DateTime? startTime;
  final DateTime? endTime;

  // Örn: SCHEDULED / IN_PROGRESS / COMPLETED
  final String? status;

  Event({
    required this.id,
    required this.name,
    this.description,
    this.scheduledAt,
    this.durationMinutes,
    this.startTime,
    this.endTime,
    this.status,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
    };
  }

  Event copyWith({
    int? id,
    String? name,
    String? description,
    DateTime? scheduledAt,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    String? status,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }
}
