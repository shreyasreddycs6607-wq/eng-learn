import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/content_service.dart';
import 'package:english_kaliyona/data/local/content/conversation_validator.dart';
import 'package:english_kaliyona/data/repositories/conversation_repository.dart';
import 'package:english_kaliyona/data/repositories/exercise_repository.dart';
import 'package:english_kaliyona/models/conversation.dart';
import 'package:english_kaliyona/models/exercise.dart';

Conversation _conv({List<ConversationTurn>? turns, String id = 'CONV900'}) => Conversation(
      id: id,
      category: ConversationCategory.home,
      title: 't',
      kannadaTitle: 'k',
      kannadaSituation: 'k',
      situation: 's',
      turns: turns ??
          [
            for (var i = 1; i <= 4; i++) ConversationTurn(order: i, speaker: 'family', kannadaText: 'k', englishText: 'Hi.'),
            const ConversationTurn(order: 5, speaker: 'learner', kannadaText: 'k', englishText: 'Hi.', responseExerciseIds: ['NOPE', 'NOPE2']),
          ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled conversations', () {
    test('pass full validation with zero issues', () async {
      final content = ContentService();
      final errors = ConversationValidator.validate(
        conversations: await ConversationRepository(content).loadAll(),
        exercises: await ExerciseRepository(content).loadAll(),
      );
      expect(errors, isEmpty, reason: errors.join('\n'));
    });

    test('cover all eight situations, 4-8 turns each, in a fixed ID order', () async {
      final all = await ConversationRepository(ContentService()).loadAll();
      expect(all.map((c) => c.category).toSet(), ConversationCategory.values.toSet());
      expect(all.map((c) => c.id), ['CONV001', 'CONV002', 'CONV003', 'CONV004', 'CONV005', 'CONV006', 'CONV007', 'CONV008']);
      for (final c in all) {
        expect(c.turns.length, inInclusiveRange(4, 8), reason: c.id);
      }
    });

    test('every referenced audio file is actually bundled', () async {
      final available = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
      final all = await ConversationRepository(ContentService()).loadAll();
      final exercises = await ExerciseRepository(ContentService()).loadAll();
      final missing = <String>[
        for (final c in all) ...c.turns.map((t) => t.audioPath).whereType<String>(),
        ...exercises.where((e) => e.conversationId != null).map((e) => e.audioPath).whereType<String>(),
      ].where((p) => !available.contains('assets/$p')).toList();
      expect(missing, isEmpty);
    });

    test('reply exercises do not leak into a lesson\'s own practice list', () async {
      final repo = ExerciseRepository(ContentService());
      for (final id in ['L026', 'L030']) {
        expect((await repo.forLesson(id)).where((e) => e.conversationId != null), isEmpty);
      }
    });

    test('every conversation reply exercise is a multipleChoice/speaking pair', () async {
      final all = await ConversationRepository(ContentService()).loadAll();
      final byId = {for (final e in await ExerciseRepository(ContentService()).loadAll()) e.id: e};
      for (final t in all.expand((c) => c.turns).where((t) => t.isLearner)) {
        expect(byId[t.responseExerciseIds[0]]!.type, ExerciseType.multipleChoice);
        expect(byId[t.responseExerciseIds[1]]!.type, ExerciseType.speaking);
      }
    });
  });

  group('ConversationValidator', () {
    test('flags too few turns', () {
      final errors = ConversationValidator.validate(conversations: [_conv(turns: [const ConversationTurn(order: 1, speaker: 'family', kannadaText: 'k', englishText: 'Hi.')])], exercises: const []);
      expect(errors.any((e) => e.contains('must be 4-8')), isTrue);
    });

    test('flags too many turns', () {
      final turns = [for (var i = 1; i <= 9; i++) ConversationTurn(order: i, speaker: 'family', kannadaText: 'k', englishText: 'Hi.')];
      final errors = ConversationValidator.validate(conversations: [_conv(turns: turns)], exercises: const []);
      expect(errors.any((e) => e.contains('must be 4-8')), isTrue);
    });

    test('flags dangling exercise references', () {
      final errors = ConversationValidator.validate(conversations: [_conv()], exercises: const []);
      expect(errors.any((e) => e.contains('NOPE') && e.contains('does not exist')), isTrue);
    });

    test('flags duplicate conversation ids', () {
      final errors = ConversationValidator.validate(conversations: [_conv(), _conv()], exercises: const []);
      expect(errors.any((e) => e.contains('Duplicate conversation id')), isTrue);
    });

    test('flags a turn order gap and an unknown speaker', () {
      final turns = [
        const ConversationTurn(order: 1, speaker: 'family', kannadaText: 'k', englishText: 'Hi.'),
        const ConversationTurn(order: 3, speaker: 'wizard', kannadaText: 'k', englishText: 'Hi.'),
        const ConversationTurn(order: 4, speaker: 'family', kannadaText: 'k', englishText: 'Hi.'),
        const ConversationTurn(order: 5, speaker: 'family', kannadaText: 'k', englishText: 'Hi.'),
      ];
      final errors = ConversationValidator.validate(conversations: [_conv(turns: turns)], exercises: const []);
      expect(errors.any((e) => e.contains('turn order')), isTrue);
      expect(errors.any((e) => e.contains('unknown speaker')), isTrue);
    });

    test('flags missing Kannada/English and network audio', () {
      final turns = [
        const ConversationTurn(order: 1, speaker: 'family', kannadaText: '', englishText: 'Hi.'),
        const ConversationTurn(order: 2, speaker: 'family', kannadaText: 'k', englishText: ''),
        const ConversationTurn(order: 3, speaker: 'family', kannadaText: 'k', englishText: 'Hi.', audioPath: 'https://example.com/a.mp3'),
        const ConversationTurn(order: 4, speaker: 'family', kannadaText: 'k', englishText: 'Hi.'),
      ];
      final errors = ConversationValidator.validate(conversations: [_conv(turns: turns)], exercises: const []);
      expect(errors.any((e) => e.contains('missing kannadaText')), isTrue);
      expect(errors.any((e) => e.contains('missing englishText')), isTrue);
      expect(errors.any((e) => e.contains('local audio/')), isTrue);
    });
  });
}
