class ExerciseOption {
  final String id;
  final String text;

  const ExerciseOption({required this.id, required this.text});

  factory ExerciseOption.fromJson(Map<String, dynamic> json) {
    return ExerciseOption(id: json['id'] as String, text: json['text'] as String);
  }
}
