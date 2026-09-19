import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exercise.dart';
import '../../models/exercise_answer.dart';
import '../../models/exercise_option.dart';
import '../primary_button.dart';

class WordOrderingExercise extends StatefulWidget {
  final Exercise exercise;
  final ExerciseAnswer? submittedAnswer;
  final ValueChanged<ExerciseAnswer> onSubmit;

  const WordOrderingExercise({
    super.key,
    required this.exercise,
    required this.submittedAnswer,
    required this.onSubmit,
  });

  @override
  State<WordOrderingExercise> createState() => _WordOrderingExerciseState();
}

class _WordOrderingExerciseState extends State<WordOrderingExercise> {
  late List<ExerciseOption> _bank;
  final List<ExerciseOption> _built = [];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(WordOrderingExercise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id) _reset();
  }

  void _reset() {
    _bank = List.of(widget.exercise.options);
    _built.clear();
  }

  bool get _locked => widget.submittedAnswer != null;

  void _tapBank(ExerciseOption option) {
    if (_locked) return;
    setState(() {
      _bank.remove(option);
      _built.add(option);
    });
  }

  void _tapBuilt(ExerciseOption option) {
    if (_locked) return;
    setState(() {
      _built.remove(option);
      _bank.add(option);
    });
  }

  void _check() {
    if (_bank.isNotEmpty) return;
    widget.onSubmit(OrderedOptionIdsAnswer(value: _built.map((o) => o.id).toList()));
  }

  @override
  Widget build(BuildContext context) {
    final submitted = widget.submittedAnswer;
    final displayIds = submitted is OrderedOptionIdsAnswer ? submitted.value : _built.map((o) => o.id).toList();
    final displayWords = widget.exercise.options
        .where((o) => displayIds.contains(o.id))
        .toList()
      ..sort((a, b) => displayIds.indexOf(a.id).compareTo(displayIds.indexOf(b.id)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Your sentence:', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                // The tray the sentence is built in.
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 2),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displayWords.map((o) => _chip(o, placed: true)).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_locked)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bank.map((o) => _chip(o, placed: false)).toList(),
                  ),
              ],
            ),
          ),
        ),
        if (!_locked) ...[
          Semantics(
            label: 'Check answer',
            child: PrimaryButton(label: 'CHECK', onPressed: _bank.isEmpty && _built.isNotEmpty ? _check : null),
          ),
        ],
      ],
    );
  }

  Widget _chip(ExerciseOption option, {required bool placed}) {
    return ActionChip(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: placed ? AppColors.primary : AppColors.border, width: 2),
      ),
      backgroundColor: placed ? AppColors.primarySoft : AppColors.surface,
      disabledColor: placed ? AppColors.primarySoft : AppColors.surface,
      label: Text(option.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      onPressed: _locked ? null : () => placed ? _tapBuilt(option) : _tapBank(option),
    );
  }
}
