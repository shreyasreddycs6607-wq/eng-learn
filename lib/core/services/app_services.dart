import 'package:flutter/foundation.dart';
import '../../data/local/content/audio_asset_checker.dart';
import '../../data/local/content/content_service.dart';
import '../../data/local/content/conversation_validator.dart';
import '../../data/local/content/curriculum_validator.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/conversation_repository.dart';
import '../../data/repositories/exercise_progress_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/sentence_pattern_repository.dart';
import '../../data/repositories/vocabulary_repository.dart';
import '../../services/audio_service.dart';
import '../../services/progress_service.dart';
import '../../services/revision_scheduler.dart';
import '../../services/speech_recognition_service.dart';

/// One instance per app run, created in main() before runApp. Screens read
/// this instead of each constructing their own repositories/database
/// connection, so the JSON cache and the single SQLite connection are
/// actually shared across navigation rather than reopened per screen.
class AppServices {
  final AppDatabase database;
  final LessonRepository lessons;
  final ExerciseRepository exercises;
  final VocabularyRepository vocabulary;
  final SentencePatternRepository sentencePatterns;
  final ProgressRepository progressRepository;
  final ProgressService progress;
  final AudioService audio;
  final SpeechRecognitionService speech;
  final ExerciseProgressRepository exerciseProgress;
  final ConversationRepository conversations;

  AppServices._({
    required this.database,
    required this.lessons,
    required this.exercises,
    required this.vocabulary,
    required this.sentencePatterns,
    required this.progressRepository,
    required this.progress,
    required this.audio,
    required this.speech,
    required this.exerciseProgress,
    required this.conversations,
  });

  /// Tests pass an in-memory database and fake audio/speech backends; the app
  /// calls this with no arguments.
  factory AppServices({AppDatabase? database, AudioService? audio, SpeechRecognitionService? speech}) {
    final content = ContentService();
    database ??= AppDatabase();
    final lessons = LessonRepository(content);
    final progressRepository = ProgressRepository(database);
    final progress = ProgressService(lessons, progressRepository);
    return AppServices._(
      database: database,
      lessons: lessons,
      exercises: ExerciseRepository(content),
      vocabulary: VocabularyRepository(content),
      sentencePatterns: SentencePatternRepository(content),
      progressRepository: progressRepository,
      progress: progress,
      audio: audio ?? AudioService(),
      speech: speech ?? SpeechRecognitionService(),
      exerciseProgress: ExerciseProgressRepository(database, RevisionScheduler(), progress.recordActivityToday),
      conversations: ConversationRepository(content),
    );
  }

  /// One cross-referenced validation pass over the whole curriculum. Called
  /// once at startup in debug builds; logs issues instead of crashing.
  Future<List<String>> validateCurriculum() async {
    final allExercises = await exercises.loadAll();
    return [
      ...CurriculumValidator.validate(
        lessons: await lessons.loadAll(),
        vocabulary: await vocabulary.loadAll(),
        patterns: await sentencePatterns.loadAll(),
        exercises: allExercises,
        contents: await lessons.loadAllContent(),
      ),
      ...ConversationValidator.validate(conversations: await conversations.loadAll(), exercises: allExercises),
    ];
  }

  Future<void> validateCurriculumInDebug() async {
    if (!kDebugMode) return;
    final issues = await validateCurriculum();
    if (issues.isNotEmpty) {
      debugPrint('Curriculum validation found ${issues.length} issue(s):\n- ${issues.join('\n- ')}');
    }

    // Content production (recording real audio) is ongoing — a nonzero
    // count here is expected until the library is complete, so this is a
    // one-line summary, not a per-file dump.
    final missingAudio = await AudioAssetChecker.findMissingAssets(
      vocabulary: await vocabulary.loadAll(),
      patterns: await sentencePatterns.loadAll(),
      exercises: await exercises.loadAll(),
      contents: await lessons.loadAllContent(),
    );
    if (missingAudio.isNotEmpty) {
      debugPrint('[AUDIO] ${missingAudio.length} referenced audio file(s) not yet bundled.');
    }

    // §75/§78: keep progress references safe if curriculum content ever changes.
    final validExerciseIds = (await exercises.loadAll()).map((e) => e.id).toSet();
    await exerciseProgress.pruneDangling(validExerciseIds);
  }
}

late final AppServices appServices;
