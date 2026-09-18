import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/exercise_answer.dart';
import '../answer_option.dart';
import '../primary_button.dart';

/// Shared rendering for every exercise type whose interaction is "read a
/// prompt, pick one option, tap Check": multipleChoice, kannadaToEnglish,
/// englishToKannada, fillBlank, and listening are all structurally this
/// same list-of-options + Check button — the five ExerciseType-named
/// subclasses below exist so the practice dispatcher and widget tests can
/// address them by type, without re-implementing this five times.
class ChoiceExerciseView extends StatefulWidget {
  final Exercise exercise;
  final ExerciseAnswer? submittedAnswer;
  final ValueChanged<ExerciseAnswer> onSubmit;

  const ChoiceExerciseView({
    super.key,
    required this.exercise,
    required this.submittedAnswer,
    required this.onSubmit,
  });

  @override
  State<ChoiceExerciseView> createState() => _ChoiceExerciseViewState();
}

class _ChoiceExerciseViewState extends State<ChoiceExerciseView> {
  String? _draftOptionId;

  @override
  void didUpdateWidget(ChoiceExerciseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) {
      _draftOptionId = null;
    }
  }

  void _select(String optionId) {
    if (widget.submittedAnswer != null) return;
    setState(() => _draftOptionId = optionId);
  }

  void _check() {
    final id = _draftOptionId;
    if (id == null) return;
    widget.onSubmit(OptionIdAnswer(value: id));
  }

  @override
  Widget build(BuildContext context) {
    final answered = widget.submittedAnswer != null;
    final submitted = widget.submittedAnswer;
    final submittedId = submitted is OptionIdAnswer ? submitted.value : null;
    final expected = widget.exercise.answer;
    final expectedId = expected is OptionIdAnswer ? expected.value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: widget.exercise.options.map((option) {
              return AnswerOption(
                label: option.text,
                isSelected: answered ? option.id == submittedId : option.id == _draftOptionId,
                isCorrectAnswer: option.id == expectedId,
                answered: answered,
                onTap: () => _select(option.id),
              );
            }).toList(),
          ),
        ),
        if (!answered) ...[
          const SizedBox(height: 12),
          Semantics(
            label: 'Check answer',
            child: PrimaryButton(label: 'CHECK', onPressed: _draftOptionId == null ? null : _check),
          ),
        ],
      ],
    );
  }
}

class MultipleChoiceExercise extends ChoiceExerciseView {
  const MultipleChoiceExercise({super.key, required super.exercise, required super.submittedAnswer, required super.onSubmit});
}

class KannadaToEnglishExercise extends ChoiceExerciseView {
  const KannadaToEnglishExercise({super.key, required super.exercise, required super.submittedAnswer, required super.onSubmit});
}

class EnglishToKannadaExercise extends ChoiceExerciseView {
  const EnglishToKannadaExercise({super.key, required super.exercise, required super.submittedAnswer, required super.onSubmit});
}

class FillBlankExercise extends ChoiceExerciseView {
  const FillBlankExercise({super.key, required super.exercise, required super.submittedAnswer, required super.onSubmit});
}

class ListeningExercise extends ChoiceExerciseView {
  const ListeningExercise({super.key, required super.exercise, required super.submittedAnswer, required super.onSubmit});
}
