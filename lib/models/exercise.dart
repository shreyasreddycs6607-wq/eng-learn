import 'exercise_answer.dart';
import 'exercise_option.dart';

enum ExerciseType { multipleChoice, kannadaToEnglish, englishToKannada, fillBlank, wordOrdering, listening, speaking }

ExerciseType _exerciseTypeFromJson(String value) {
  for (final t in ExerciseType.values) {
    if (t.name == value) return t;
  }
  throw FormatException('Unknown exercise type: $value');
}

class Exercise {
  final String id;
  final String lessonId;
  final ExerciseType type;
  final int order;
  final String question;
  final String? kannadaText;
  final String? englishText;
  final String? audioPath;
  final List<ExerciseOption> options;
  final ExerciseAnswer answer;
  final String? explanation;

  /// Set only on Real-Life Practice reply exercises. They live in the same
  /// exercises.json (so revision, mastery and answer checking treat them like
  /// any other exercise) but are excluded from a lesson's own practice list.
  final String? conversationId;

  const Exercise({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.order,
    required this.question,
    this.kannadaText,
    this.englishText,
    this.audioPath,
    required this.options,
    required this.answer,
    this.explanation,
    this.conversationId,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      type: _exerciseTypeFromJson(json['type'] as String),
      order: json['order'] as int,
      question: json['question'] as String,
      kannadaText: json['kannadaText'] as String?,
      englishText: json['englishText'] as String?,
      audioPath: json['audioPath'] as String?,
      options: (json['options'] as List<dynamic>? ?? const [])
          .map((o) => ExerciseOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      answer: ExerciseAnswer.fromJson(json['answer'] as Map<String, dynamic>),
      explanation: json['explanation'] as String?,
      conversationId: json['conversationId'] as String?,
    );
  }
}
