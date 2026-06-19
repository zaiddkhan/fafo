enum QuestDifficulty { easy, medium, hard }

QuestDifficulty questDifficultyFromJson(String? value) {
  return switch (value) {
    'medium' => QuestDifficulty.medium,
    'hard' => QuestDifficulty.hard,
    _ => QuestDifficulty.easy,
  };
}

extension QuestDifficultyLabel on QuestDifficulty {
  String get label => switch (this) {
        QuestDifficulty.easy => 'Easy • under 30 min',
        QuestDifficulty.medium => 'Medium • a few hours',
        QuestDifficulty.hard => 'Hard • full day or group effort',
      };

  /// Short badge text shown top-right of a quest card.
  String get badgeLabel => switch (this) {
        QuestDifficulty.easy => 'Easy',
        QuestDifficulty.medium => 'Medium',
        QuestDifficulty.hard => 'Hard',
      };

  /// Rough time-to-complete estimate shown under the badge.
  String get timeEstimate => switch (this) {
        QuestDifficulty.easy => '< 30 min',
        QuestDifficulty.medium => '1-3 hrs',
        QuestDifficulty.hard => 'Full Day',
      };
}

class QuestResponse {
  const QuestResponse({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.published,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.city,
  });

  final String id;
  final String title;
  final String? description;
  final QuestDifficulty difficulty;
  final String? city;
  final bool published;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory QuestResponse.fromJson(Map<String, dynamic> json) {
    return QuestResponse(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      difficulty: questDifficultyFromJson(json['difficulty'] as String?),
      city: json['city'] as String?,
      published: json['published'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

enum QuestActivationStatus { active, completed }

QuestActivationStatus questActivationStatusFromJson(String? value) =>
    value == 'completed' ? QuestActivationStatus.completed : QuestActivationStatus.active;

/// A quest the current user has started, with its participation status.
class QuestActivation {
  const QuestActivation({
    required this.quest,
    required this.status,
    required this.activatedAt,
    this.completedAt,
  });

  final QuestResponse quest;
  final QuestActivationStatus status;
  final DateTime activatedAt;
  final DateTime? completedAt;

  bool get isActive => status == QuestActivationStatus.active;
  bool get isCompleted => status == QuestActivationStatus.completed;

  factory QuestActivation.fromJson(Map<String, dynamic> json) {
    return QuestActivation(
      quest: QuestResponse.fromJson(json['quest'] as Map<String, dynamic>),
      status: questActivationStatusFromJson(json['status'] as String?),
      activatedAt: DateTime.parse(json['activated_at'] as String),
      completedAt: json['completed_at'] == null ? null : DateTime.parse(json['completed_at'] as String),
    );
  }
}
