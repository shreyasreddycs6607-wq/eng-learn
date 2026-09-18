import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/content_service.dart';
import 'package:english_kaliyona/data/repositories/conversation_repository.dart';
import 'package:english_kaliyona/data/repositories/exercise_repository.dart';
import 'package:english_kaliyona/data/repositories/lesson_repository.dart';
import 'package:english_kaliyona/data/repositories/sentence_pattern_repository.dart';
import 'package:english_kaliyona/data/repositories/vocabulary_repository.dart';

/// The audit found 184 of 230 referenced audio files missing (all .mp3 names
/// with no file behind them), which left 11 listening exercises unanswerable.
/// This keeps that from coming back: every referenced clip must be bundled,
/// except optional Telugu/Kannada audio, which is documented below.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Optional support audio that has no recording yet. The UI hides these
  /// buttons; add a real recording, then delete the entry here.
  const optionalMissing = {'audio/telugu/water_telugu.mp3'};

  test('every referenced audio file is bundled (optional Telugu/Kannada excepted)', () async {
    final content = ContentService();
    final lessons = LessonRepository(content);
    final referenced = <String, String>{}; // path -> who references it
    for (final v in await VocabularyRepository(content).loadAll()) {
      for (final p in [v.englishAudio, v.kannadaAudio, v.teluguAudio]) {
        if (p != null) referenced[p] = 'vocabulary ${v.id}';
      }
    }
    for (final p in await SentencePatternRepository(content).loadAll()) {
      for (final ex in p.examples) {
        if (ex.englishAudio != null) referenced[ex.englishAudio!] = 'pattern ${p.id}';
      }
    }
    for (final c in await lessons.loadAllContent()) {
      for (final p in [c.englishAudio, c.teluguAudio]) {
        if (p != null) referenced[p] = 'content ${c.id}';
      }
    }
    for (final e in await ExerciseRepository(content).loadAll()) {
      if (e.audioPath != null) referenced[e.audioPath!] = 'exercise ${e.id} (${e.type.name})';
    }
    for (final c in await ConversationRepository(content).loadAll()) {
      for (final t in c.turns) {
        if (t.audioPath != null) referenced[t.audioPath!] = 'conversation ${c.id} turn ${t.order}';
      }
    }

    final bundled = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
    final missing = referenced.entries.where((e) => !bundled.contains('assets/${e.key}') && !optionalMissing.contains(e.key));

    expect(missing.map((e) => '${e.key} <- ${e.value}'), isEmpty);
  });

  test('every listening and speaking exercise has its (required) audio bundled', () async {
    final bundled = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
    final exercises = await ExerciseRepository(ContentService()).loadAll();
    final needAudio = exercises.where((e) => e.type.name == 'listening' || e.type.name == 'speaking');

    expect(needAudio, isNotEmpty);
    for (final e in needAudio) {
      expect(bundled, contains('assets/${e.audioPath}'), reason: 'exercise ${e.id}');
    }
  });
}
