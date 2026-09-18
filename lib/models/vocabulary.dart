/// A reusable vocabulary entry, independent of any single lesson.
/// No Telugu script — only an optional Telugu audio reference.
class Vocabulary {
  final String id;
  final String english;
  final String kannada;
  final String category;
  final int difficulty;
  final String? englishAudio;
  final String? kannadaAudio;
  final String? teluguAudio;

  const Vocabulary({
    required this.id,
    required this.english,
    required this.kannada,
    required this.category,
    required this.difficulty,
    this.englishAudio,
    this.kannadaAudio,
    this.teluguAudio,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      id: json['id'] as String,
      english: json['english'] as String,
      kannada: json['kannada'] as String,
      category: json['category'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
      englishAudio: json['englishAudio'] as String?,
      kannadaAudio: json['kannadaAudio'] as String?,
      teluguAudio: json['teluguAudio'] as String?,
    );
  }
}
