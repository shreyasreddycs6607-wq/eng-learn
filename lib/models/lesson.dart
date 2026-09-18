import 'lesson_content.dart';

class Lesson {
  final String id;
  final int level;
  final int order;
  final String topic;
  final String title;
  final String kannadaTitle;
  final String description;
  final int estimatedMinutes;
  final List<String> vocabularyIds;
  final List<String> sentencePatternIds;
  final List<String> exerciseIds;
  final List<String> contentIds;
  final List<LessonContent> contents;

  const Lesson({
    required this.id,
    required this.level,
    required this.order,
    required this.topic,
    required this.title,
    required this.kannadaTitle,
    required this.description,
    required this.estimatedMinutes,
    this.vocabularyIds = const [],
    this.sentencePatternIds = const [],
    this.exerciseIds = const [],
    this.contentIds = const [],
    this.contents = const [],
  });

  Lesson withContents(List<LessonContent> contents) => Lesson(
        id: id,
        level: level,
        order: order,
        topic: topic,
        title: title,
        kannadaTitle: kannadaTitle,
        description: description,
        estimatedMinutes: estimatedMinutes,
        vocabularyIds: vocabularyIds,
        sentencePatternIds: sentencePatternIds,
        exerciseIds: exerciseIds,
        contentIds: contentIds,
        contents: contents,
      );

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      level: json['level'] as int,
      order: json['order'] as int,
      topic: json['topic'] as String,
      title: json['title'] as String,
      kannadaTitle: json['kannadaTitle'] as String,
      description: json['description'] as String? ?? '',
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 7,
      vocabularyIds: (json['vocabularyIds'] as List<dynamic>? ?? const []).cast<String>(),
      sentencePatternIds: (json['sentencePatternIds'] as List<dynamic>? ?? const []).cast<String>(),
      exerciseIds: (json['exerciseIds'] as List<dynamic>? ?? const []).cast<String>(),
      contentIds: (json['contentIds'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}
