import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../../../models/exercise.dart';
import '../../../models/lesson_content.dart';
import '../../../models/sentence_pattern.dart';
import '../../../models/vocabulary.dart';

/// A valid `audio/...` path in the JSON proves the *reference* is
/// well-formed (see CurriculumValidator) — it does not prove the file was
/// actually bundled. This does: it diffs every referenced audio path
/// against Flutter's real asset manifest, so a missing recording shows up
/// as a clear development-time message instead of a silent "Audio
/// unavailable" the first time a learner taps play.
class AudioAssetChecker {
  static Future<List<String>> findMissingAssets({
    required List<Vocabulary> vocabulary,
    required List<SentencePattern> patterns,
    required List<Exercise> exercises,
    required List<LessonContent> contents,
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final available = manifest.listAssets().toSet();
    final missing = <String>[];

    void check(String? path, String referencedBy) {
      if (path == null) return;
      if (!available.contains('assets/$path')) {
        missing.add('Missing audio asset: $path\nReferenced by: $referencedBy');
      }
    }

    for (final v in vocabulary) {
      check(v.englishAudio, 'Vocabulary ${v.id}');
      check(v.kannadaAudio, 'Vocabulary ${v.id}');
      check(v.teluguAudio, 'Vocabulary ${v.id}');
    }
    for (final p in patterns) {
      for (final ex in p.examples) {
        check(ex.englishAudio, 'Sentence pattern ${p.id} example ${ex.id}');
      }
    }
    for (final c in contents) {
      check(c.englishAudio, 'Content ${c.id}');
      check(c.teluguAudio, 'Content ${c.id}');
    }
    for (final e in exercises) {
      check(e.audioPath, 'Exercise ${e.id}');
    }

    return missing;
  }
}
