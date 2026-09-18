enum ContentType { word, sentence, pattern, example }

ContentType _contentTypeFromJson(String value) {
  for (final t in ContentType.values) {
    if (t.name == value) return t;
  }
  throw FormatException('Unknown content type: $value');
}

class LessonContent {
  final String id;
  final String lessonId;
  final ContentType type;
  final String kannadaText;
  final String englishText;
  final String? englishAudio;
  final String? teluguAudio;
  final int order;

  const LessonContent({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.kannadaText,
    required this.englishText,
    this.englishAudio,
    this.teluguAudio,
    required this.order,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      type: _contentTypeFromJson(json['type'] as String),
      kannadaText: json['kannadaText'] as String,
      englishText: json['englishText'] as String,
      englishAudio: json['englishAudio'] as String?,
      teluguAudio: json['teluguAudio'] as String?,
      order: json['order'] as int,
    );
  }
}
