import '../../../models/exercise.dart';
import '../../../models/exercise_answer.dart';
import '../../../models/lesson.dart';
import '../../../models/lesson_content.dart';
import '../../../models/sentence_pattern.dart';
import '../../../models/vocabulary.dart';

/// A single validation pass over the whole curriculum: unique IDs, resolvable
/// references, required text, local-only audio, and no Telugu script leaking
/// into learner-facing fields. Returns human-readable error strings — it
/// never throws, so a content bug surfaces as a debug-log list, not a crash.
class CurriculumValidator {
  static final _teluguScript = RegExp(r'[ఀ-౿]');
  static final _networkUrl = RegExp(r'^https?://', caseSensitive: false);
  static final _windowsAbsolutePath = RegExp(r'^[A-Za-z]:[\\/]');
  static const _allowedAudioExtensions = {'.mp3', '.wav', '.m4a', '.aac', '.ogg'};

  static List<String> validate({
    required List<Lesson> lessons,
    required List<Vocabulary> vocabulary,
    required List<SentencePattern> patterns,
    required List<Exercise> exercises,
    required List<LessonContent> contents,
  }) {
    final errors = <String>[];

    final lessonIds = _uniqueIds(lessons.map((l) => l.id), 'lesson', errors);
    final vocabIds = _uniqueIds(vocabulary.map((v) => v.id), 'vocabulary', errors);
    final patternIds = _uniqueIds(patterns.map((p) => p.id), 'sentence pattern', errors);
    final exerciseIds = _uniqueIds(exercises.map((e) => e.id), 'exercise', errors);
    final contentIds = _uniqueIds(contents.map((c) => c.id), 'content', errors);

    _validateLessonOrderAndLevel(lessons, errors);
    _validateLessonReferences(lessons, vocabIds, patternIds, exerciseIds, contentIds, errors);
    _validateLessonText(lessons, errors);

    for (final v in vocabulary) {
      if (v.english.trim().isEmpty) errors.add('Vocabulary ${v.id} missing english text');
      if (v.kannada.trim().isEmpty) errors.add('Vocabulary ${v.id} missing kannada text');
      _checkNoTelugu('Vocabulary ${v.id} kannada', v.kannada, errors);
      _checkLocalAudio('Vocabulary ${v.id} englishAudio', v.englishAudio, errors);
      _checkLocalAudio('Vocabulary ${v.id} kannadaAudio', v.kannadaAudio, errors);
      _checkLocalAudio('Vocabulary ${v.id} teluguAudio', v.teluguAudio, errors);
    }

    for (final p in patterns) {
      if (p.examples.length < 2) errors.add('Sentence pattern ${p.id} has fewer than 2 examples');
      for (final ex in p.examples) {
        _checkNoTelugu('Pattern ${p.id} example ${ex.id} kannada', ex.kannada, errors);
        _checkLocalAudio('Pattern ${p.id} example ${ex.id} englishAudio', ex.englishAudio, errors);
      }
    }

    for (final c in contents) {
      if (!lessonIds.contains(c.lessonId)) {
        errors.add('ERROR: Content ${c.id} references lesson ${c.lessonId}, but that lesson does not exist.');
      }
      if (c.englishText.trim().isEmpty) errors.add('Content ${c.id} missing englishText');
      if (c.kannadaText.trim().isEmpty) errors.add('Content ${c.id} missing kannadaText');
      _checkNoTelugu('Content ${c.id} kannadaText', c.kannadaText, errors);
      _checkLocalAudio('Content ${c.id} englishAudio', c.englishAudio, errors);
      _checkLocalAudio('Content ${c.id} teluguAudio', c.teluguAudio, errors);
    }

    for (final e in exercises) {
      if (!lessonIds.contains(e.lessonId)) {
        errors.add('ERROR: Exercise ${e.id} references lesson ${e.lessonId}, but that lesson does not exist.');
      }
      _checkLocalAudio('Exercise ${e.id} audioPath', e.audioPath, errors);
      _checkNoTelugu('Exercise ${e.id} kannadaText', e.kannadaText ?? '', errors);
      _validateExerciseAnswer(e, errors);
      if ((e.type == ExerciseType.listening || e.type == ExerciseType.speaking) && e.audioPath == null) {
        errors.add('Exercise ${e.id} is ${e.type.name} but has no audioPath (required for this type)');
      }
    }

    return errors;
  }

  static Set<String> _uniqueIds(Iterable<String> ids, String kind, List<String> errors) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) errors.add('Duplicate $kind id: $id');
    }
    return seen;
  }

  static void _validateLessonOrderAndLevel(List<Lesson> lessons, List<String> errors) {
    final orders = <int>{};
    for (final l in lessons) {
      if (l.level < 1 || l.level > 3) errors.add('Lesson ${l.id} has invalid level ${l.level} (must be 1-3)');
      if (!orders.add(l.order)) errors.add('Lesson ${l.id} has a duplicate order value: ${l.order}');
    }
  }

  static void _validateLessonText(List<Lesson> lessons, List<String> errors) {
    for (final l in lessons) {
      if (l.title.trim().isEmpty) errors.add('Lesson ${l.id} missing title');
      if (l.kannadaTitle.trim().isEmpty) errors.add('Lesson ${l.id} missing kannadaTitle');
      if (l.contents.isEmpty) errors.add('Lesson ${l.id} has no content (a lesson screen needs at least one card)');
      _checkNoTelugu('Lesson ${l.id} kannadaTitle', l.kannadaTitle, errors);
    }
  }

  static void _validateLessonReferences(
    List<Lesson> lessons,
    Set<String> vocabIds,
    Set<String> patternIds,
    Set<String> exerciseIds,
    Set<String> contentIds,
    List<String> errors,
  ) {
    for (final l in lessons) {
      for (final id in l.vocabularyIds) {
        if (!vocabIds.contains(id)) errors.add('ERROR: Lesson ${l.id} references vocabulary $id, but it does not exist.');
      }
      for (final id in l.sentencePatternIds) {
        if (!patternIds.contains(id)) errors.add('ERROR: Lesson ${l.id} references sentence pattern $id, but it does not exist.');
      }
      for (final id in l.exerciseIds) {
        if (!exerciseIds.contains(id)) errors.add('ERROR: Lesson ${l.id} references exercise $id, but it does not exist.');
      }
      for (final id in l.contentIds) {
        if (!contentIds.contains(id)) errors.add('ERROR: Lesson ${l.id} references content $id, but it does not exist.');
      }
    }
  }

  static void _validateExerciseAnswer(Exercise e, List<String> errors) {
    final optionIds = e.options.map((o) => o.id).toSet();
    if (optionIds.length != e.options.length) {
      errors.add('Exercise ${e.id} has duplicate option ids');
    }

    final answer = e.answer;
    switch (answer) {
      case OptionIdAnswer():
        if (e.options.isNotEmpty && !optionIds.contains(answer.value)) {
          errors.add('Exercise ${e.id} answer "${answer.value}" is not among its options');
        }
        if (e.type == ExerciseType.wordOrdering) {
          errors.add('Exercise ${e.id} is wordOrdering but uses an optionId answer');
        }
      case OrderedOptionIdsAnswer():
        if (e.type != ExerciseType.wordOrdering) {
          errors.add('Exercise ${e.id} uses an orderedOptionIds answer but is not wordOrdering');
        }
        if (answer.value.toSet().length != answer.value.length) {
          errors.add('Exercise ${e.id} answer has duplicate option ids');
        }
        for (final id in answer.value) {
          if (!optionIds.contains(id)) errors.add('Exercise ${e.id} answer references unknown option $id');
        }
        if (answer.value.length != e.options.length) {
          errors.add('Exercise ${e.id} answer does not cover all options');
        }
      case TextAnswer():
        if (e.type != ExerciseType.speaking) {
          errors.add('Exercise ${e.id} uses a text answer but is not a speaking exercise');
        }
        if (answer.value.trim().isEmpty) errors.add('Exercise ${e.id} has an empty text answer');
    }

    if (e.type == ExerciseType.speaking) {
      if (answer is! TextAnswer) errors.add('Exercise ${e.id} is speaking but does not use a text answer');
      if (e.options.isNotEmpty) errors.add('Exercise ${e.id} is speaking but has non-empty options');
    }
  }

  /// null means "no audio configured" and is always valid. Anything else
  /// must be a real local asset path — "" is never treated as null.
  static void _checkLocalAudio(String label, String? path, List<String> errors) {
    if (path == null) return;

    if (path.trim().isEmpty) {
      errors.add('$label is an empty string — use null when no audio is configured, not ""');
      return;
    }
    if (_networkUrl.hasMatch(path)) {
      errors.add('$label uses a network URL, must be a local asset: $path');
      return;
    }
    if (path.contains('..')) {
      errors.add('$label contains a path traversal segment: $path');
      return;
    }
    if (path.startsWith('/') || _windowsAbsolutePath.hasMatch(path)) {
      errors.add('$label is an absolute path, must be relative to assets/: $path');
      return;
    }
    if (!path.startsWith('audio/')) {
      errors.add('$label must start with "audio/": $path');
      return;
    }
    final lower = path.toLowerCase();
    if (!_allowedAudioExtensions.any(lower.endsWith)) {
      errors.add('$label has an unsupported extension: $path');
    }
  }

  static void _checkNoTelugu(String label, String text, List<String> errors) {
    if (_teluguScript.hasMatch(text)) errors.add('$label contains Telugu script, which must never be learner-facing: $text');
  }
}
