import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/data/local/content/audio_asset_checker.dart';
import 'package:english_kaliyona/models/vocabulary.dart';

/// Proves the missing-asset detector actually works: a path validator can't
/// tell "audio/english/water.mp3" apart from "audio/english/typo.mp3" — only
/// checking it against the real bundled AssetManifest can.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('flags a JSON-referenced audio path that is not actually bundled', () async {
    final missing = await AudioAssetChecker.findMissingAssets(
      vocabulary: const [
        Vocabulary(
          id: 'V999',
          english: 'Nonexistent',
          kannada: 'x',
          category: 'test',
          difficulty: 1,
          englishAudio: 'audio/english/this_file_does_not_exist.mp3',
        ),
      ],
      patterns: const [],
      exercises: const [],
      contents: const [],
    );

    expect(missing, hasLength(1));
    expect(missing.first, contains('this_file_does_not_exist.mp3'));
    expect(missing.first, contains('Vocabulary V999'));
  });

  test('does not flag a real bundled placeholder audio file', () async {
    final missing = await AudioAssetChecker.findMissingAssets(
      vocabulary: const [
        Vocabulary(
          id: 'V001',
          english: 'Water',
          kannada: 'ನೀರು',
          category: 'food_drink',
          difficulty: 1,
          englishAudio: 'audio/english/water.wav',
        ),
      ],
      patterns: const [],
      exercises: const [],
      contents: const [],
    );

    expect(missing, isEmpty);
  });

  test('null audio fields are never reported as missing', () async {
    final missing = await AudioAssetChecker.findMissingAssets(
      vocabulary: const [
        Vocabulary(id: 'V001', english: 'Water', kannada: 'ನೀರು', category: 'food_drink', difficulty: 1),
      ],
      patterns: const [],
      exercises: const [],
      contents: const [],
    );

    expect(missing, isEmpty);
  });
}
