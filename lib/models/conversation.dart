/// Real-Life Practice content: a short, fixed, pre-authored exchange — never
/// generated. Learner turns point at ordinary exercises (a choose-the-reply
/// multipleChoice, then a speaking exercise) by ID, so answer checking,
/// speaking evaluation, mastery and revision all reuse the existing systems.
enum ConversationCategory { home, family, shopping, phone, travel, doctor, neighbour, food }

const learnerSpeaker = 'learner';

/// Speaker keys a turn may use, mapped to the label shown to the learner.
const speakerLabels = {
  learnerSpeaker: 'You',
  'family': 'Family',
  'child': 'Child',
  'shopkeeper': 'Shopkeeper',
  'friend': 'Friend',
  'conductor': 'Conductor',
  'doctor': 'Doctor',
  'neighbour': 'Neighbour',
  'waiter': 'Waiter',
};

class ConversationTurn {
  final int order;
  final String speaker;
  final String kannadaText;
  final String englishText;
  final String? audioPath;

  /// Learner turns only: [choose-reply exercise id, speaking exercise id].
  final List<String> responseExerciseIds;

  const ConversationTurn({
    required this.order,
    required this.speaker,
    required this.kannadaText,
    required this.englishText,
    this.audioPath,
    this.responseExerciseIds = const [],
  });

  bool get isLearner => speaker == learnerSpeaker;

  factory ConversationTurn.fromJson(Map<String, dynamic> json) => ConversationTurn(
        order: json['order'] as int,
        speaker: json['speaker'] as String,
        kannadaText: json['kannadaText'] as String,
        englishText: json['englishText'] as String,
        audioPath: json['audioPath'] as String?,
        responseExerciseIds: (json['responseExerciseIds'] as List<dynamic>? ?? const []).cast<String>(),
      );
}

class Conversation {
  final String id;
  final ConversationCategory category;
  final String title;
  final String kannadaTitle;
  final String kannadaSituation;
  final String situation;
  final List<ConversationTurn> turns;

  const Conversation({
    required this.id,
    required this.category,
    required this.title,
    required this.kannadaTitle,
    required this.kannadaSituation,
    required this.situation,
    required this.turns,
  });

  Iterable<String> get responseExerciseIds => turns.expand((t) => t.responseExerciseIds);

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String;
    final category = ConversationCategory.values.where((c) => c.name == categoryName);
    if (category.isEmpty) throw FormatException('Unknown conversation category: $categoryName');
    final turns = (json['turns'] as List<dynamic>).map((t) => ConversationTurn.fromJson(t as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.order.compareTo(b.order)); // explicit order, never file order
    return Conversation(
      id: json['id'] as String,
      category: category.first,
      title: json['title'] as String,
      kannadaTitle: json['kannadaTitle'] as String,
      kannadaSituation: json['kannadaSituation'] as String,
      situation: json['situation'] as String,
      turns: turns,
    );
  }
}
