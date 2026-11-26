enum VedicCategory { sutra, subSutra }

enum AnswerType {
  integer, // Single integer (e.g., 5625 or -4)
  quotientRemainder, // Two fields: Quotient and Remainder
  pairXY, // Two fields: x and y
  booleanYesNo, // Segmented button: Yes / No
}

class VedicExample {
  final String problem;
  final String steps;
  final String answer;

  const VedicExample({
    required this.problem,
    required this.steps,
    required this.answer,
  });
}

class VedicItem {
  final String id;
  final int number;
  final String sanskritName;
  final String translation;
  final VedicCategory category;
  final String summary;
  final String theory;
  final List<VedicExample> examples;

  const VedicItem({
    required this.id,
    required this.number,
    required this.sanskritName,
    required this.translation,
    required this.category,
    required this.summary,
    required this.theory,
    required this.examples,
  });
}

class MathProblem {
  final String prompt;
  final AnswerType answerType;
  final String primaryAnswer;
  final String? secondaryAnswer;
  final String solutionSteps;
  final String hint;

  const MathProblem({
    required this.prompt,
    required this.answerType,
    required this.primaryAnswer,
    this.secondaryAnswer,
    required this.solutionSteps,
    required this.hint,
  });
}

class SessionRecord {
  final int? id;
  final int playerId;
  final String itemId;
  final String itemTitle;
  final int score;
  final int correctCount;
  final int totalQuestions;
  final int durationSeconds;
  final DateTime completedAt;

  const SessionRecord({
    this.id,
    required this.playerId,
    required this.itemId,
    required this.itemTitle,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.durationSeconds,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'player_id': playerId,
    'item_id': itemId,
    'item_title': itemTitle,
    'score': score,
    'correct_count': correctCount,
    'total_questions': totalQuestions,
    'duration_seconds': durationSeconds,
    'completed_at': completedAt.toIso8601String(),
  };

  factory SessionRecord.fromMap(Map<String, dynamic> map) => SessionRecord(
    id: map['id'] as int?,
    playerId: map['player_id'] as int,
    itemId: map['item_id'] as String,
    itemTitle: map['item_title'] as String,
    score: map['score'] as int,
    correctCount: map['correct_count'] as int,
    totalQuestions: map['total_questions'] as int,
    durationSeconds: map['duration_seconds'] as int,
    completedAt: DateTime.parse(map['completed_at'] as String),
  );
}

class Player {
  final int? id;
  final String uuid;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  const Player({
    this.id,
    required this.uuid,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'uuid': uuid,
    'name': name,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory Player.fromMap(Map<String, dynamic> map) => Player(
    id: map['id'] as int?,
    uuid: map['uuid'] as String,
    name: map['name'] as String,
    isActive: (map['is_active'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
