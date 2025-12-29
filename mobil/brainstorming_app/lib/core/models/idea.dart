class IdeaModel {
  final int id;
  final int sessionId;
  final int roundNumber;
  final int authorId;
  final String content;
  final DateTime createdAt;

  IdeaModel({
    required this.id,
    required this.sessionId,
    required this.roundNumber,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory IdeaModel.fromJson(Map<String, dynamic> json) {
    return IdeaModel(
      id: json['id'] as int,
      sessionId: json['sessionId'] as int,
      roundNumber: json['roundNumber'] as int,
      authorId: json['authorId'] as int,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'roundNumber': roundNumber,
      'authorId': authorId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
