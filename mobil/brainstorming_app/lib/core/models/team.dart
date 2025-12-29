// lib/core/models/team.dart
class Team {
  final int id;
  final String name;
  final String? description;
  final int? eventId;      // Bu team hangi event'e bağlı? (opsiyonel)
  final int? memberCount;  // Backend sayıyı dönüyorsa kullanırız

  Team({
    required this.id,
    required this.name,
    this.description,
    this.eventId,
    this.memberCount,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      eventId: json['eventId'] as int?,
      memberCount: json['memberCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'eventId': eventId,
      'memberCount': memberCount,
    };
  }
}
