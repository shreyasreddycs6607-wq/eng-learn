import '../../../models/conversation.dart';
import '../../../models/exercise.dart';

/// Conversation-specific checks, layered on top of CurriculumValidator: unique
/// IDs, 4–8 contiguous turns, known speakers, required Kannada/English,
/// local-only audio, and that every learner turn points at real, matching
/// exercises. Never throws — returns human-readable errors.
class ConversationValidator {
  static final _teluguScript = RegExp(r'[ఀ-౿]');
  static final _networkUrl = RegExp(r'^https?://', caseSensitive: false);

  static List<String> validate({required List<Conversation> conversations, required List<Exercise> exercises}) {
    final errors = <String>[];
    final byId = {for (final e in exercises) e.id: e};
    final seen = <String>{};

    for (final c in conversations) {
      if (!seen.add(c.id)) errors.add('Duplicate conversation id: ${c.id}');
      if (c.turns.length < 4 || c.turns.length > 8) {
        errors.add('Conversation ${c.id} has ${c.turns.length} turns (must be 4-8)');
      }
      for (final (label, text) in [
        ('title', c.title),
        ('kannadaTitle', c.kannadaTitle),
        ('kannadaSituation', c.kannadaSituation),
        ('situation', c.situation),
      ]) {
        if (text.trim().isEmpty) errors.add('Conversation ${c.id} missing $label');
      }
      if (_teluguScript.hasMatch(c.kannadaSituation) || _teluguScript.hasMatch(c.kannadaTitle)) {
        errors.add('Conversation ${c.id} contains Telugu script');
      }
      if (!c.turns.any((t) => t.isLearner)) errors.add('Conversation ${c.id} has no learner turn');

      for (var i = 0; i < c.turns.length; i++) {
        final t = c.turns[i];
        final where = 'Conversation ${c.id} turn ${t.order}';
        if (t.order != i + 1) errors.add('$where: turn order must run 1..n without gaps');
        if (!speakerLabels.containsKey(t.speaker)) errors.add('$where: unknown speaker "${t.speaker}"');
        if (t.kannadaText.trim().isEmpty) errors.add('$where missing kannadaText');
        if (t.englishText.trim().isEmpty) errors.add('$where missing englishText');
        if (_teluguScript.hasMatch(t.kannadaText)) errors.add('$where kannadaText contains Telugu script');
        final audio = t.audioPath;
        if (audio != null && (_networkUrl.hasMatch(audio) || !audio.startsWith('audio/'))) {
          errors.add('$where audioPath must be a local audio/ asset: $audio');
        }
        _validateResponses(c, t, where, byId, errors);
      }
    }
    return errors;
  }

  static void _validateResponses(Conversation c, ConversationTurn t, String where, Map<String, Exercise> byId, List<String> errors) {
    if (!t.isLearner) {
      if (t.responseExerciseIds.isNotEmpty) errors.add('$where is not a learner turn but has responseExerciseIds');
      return;
    }
    if (t.responseExerciseIds.length != 2) {
      errors.add('$where needs exactly 2 responseExerciseIds (choose, speak)');
      return;
    }
    const expected = [ExerciseType.multipleChoice, ExerciseType.speaking];
    for (var k = 0; k < 2; k++) {
      final id = t.responseExerciseIds[k];
      final e = byId[id];
      if (e == null) {
        errors.add('ERROR: $where references exercise $id, but it does not exist.');
      } else if (e.type != expected[k]) {
        errors.add('$where exercise $id must be ${expected[k].name}, is ${e.type.name}');
      } else if (e.conversationId != c.id) {
        errors.add('$where exercise $id must declare conversationId ${c.id}');
      }
    }
  }
}
