/// One canonical answer shape for every exercise type — never a bare
/// `dynamic`/`Object?` field that forces `is String` / `is List` checks
/// scattered through the UI. See AnswerChecker for how these compare.
sealed class ExerciseAnswer {
  const ExerciseAnswer();

  factory ExerciseAnswer.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String;
    switch (kind) {
      case 'optionId':
        return OptionIdAnswer(value: json['value'] as String);
      case 'text':
        return TextAnswer(value: json['value'] as String);
      case 'orderedOptionIds':
        return OrderedOptionIdsAnswer(
          value: (json['value'] as List<dynamic>).map((e) => e as String).toList(),
        );
      default:
        throw FormatException('Unknown exercise answer kind: $kind');
    }
  }
}

class OptionIdAnswer extends ExerciseAnswer {
  final String value;
  const OptionIdAnswer({required this.value});
}

class TextAnswer extends ExerciseAnswer {
  final String value;
  const TextAnswer({required this.value});
}

class OrderedOptionIdsAnswer extends ExerciseAnswer {
  final List<String> value;
  const OrderedOptionIdsAnswer({required this.value});
}
