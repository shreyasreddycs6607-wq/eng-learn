class SentenceExample {
  final String id;
  final String kannada;
  final String english;
  final String? englishAudio;

  const SentenceExample({required this.id, required this.kannada, required this.english, this.englishAudio});

  factory SentenceExample.fromJson(Map<String, dynamic> json) {
    return SentenceExample(
      id: json['id'] as String,
      kannada: json['kannada'] as String,
      english: json['english'] as String,
      englishAudio: json['englishAudio'] as String?,
    );
  }
}

/// A reusable sentence pattern (e.g. "I want + thing") shared across lessons.
class SentencePattern {
  final String id;
  final String pattern;
  final String kannadaPattern;
  final String englishTemplate;
  final int difficulty;
  final List<SentenceExample> examples;

  const SentencePattern({
    required this.id,
    required this.pattern,
    required this.kannadaPattern,
    required this.englishTemplate,
    required this.difficulty,
    this.examples = const [],
  });

  factory SentencePattern.fromJson(Map<String, dynamic> json) {
    return SentencePattern(
      id: json['id'] as String,
      pattern: json['pattern'] as String,
      kannadaPattern: json['kannadaPattern'] as String,
      englishTemplate: json['englishTemplate'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      examples: (json['examples'] as List<dynamic>? ?? const [])
          .map((e) => SentenceExample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
