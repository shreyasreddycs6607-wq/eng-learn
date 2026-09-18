import 'package:flutter_test/flutter_test.dart';
import 'package:english_kaliyona/models/speech_recognition_state.dart';
import 'package:english_kaliyona/services/speech_recognition_service.dart';
import '../fakes/fake_speech_backend.dart';

void main() {
  late FakeSpeechBackend backend;
  late SpeechRecognitionService service;

  setUp(() {
    backend = FakeSpeechBackend();
    service = SpeechRecognitionService(backend);
  });

  test('starts idle', () {
    expect(service.state, SpeechRecognitionState.idle);
  });

  group('availability', () {
    test('unavailable engine reports the unavailable state and never listens', () async {
      backend.availableResult = false;

      await service.startListening();

      expect(service.state, SpeechRecognitionState.unavailable);
      expect(backend.listenCallCount, 0);
    });
  });

  group('permission', () {
    test('requests permission only when starting to listen, not before', () async {
      backend.permissionGranted = false; // starts unpermitted
      expect(service.state, SpeechRecognitionState.idle, reason: 'no permission prompt at construction time');

      await service.startListening();

      expect(service.state, SpeechRecognitionState.permissionDenied);
      expect(backend.listenCallCount, 0, reason: 'must not attempt to listen without permission');
    });

    test('denied permission does not crash and leaves the app usable', () async {
      backend.permissionGranted = false;
      await service.startListening();
      expect(service.state, SpeechRecognitionState.permissionDenied);

      // Retrying is safe and produces the same, stable outcome.
      await service.startListening();
      expect(service.state, SpeechRecognitionState.permissionDenied);
    });

    test('granting permission allows listening to proceed', () async {
      backend.permissionGranted = true;
      await service.startListening();
      expect(service.state, SpeechRecognitionState.listening);
    });
  });

  group('listening lifecycle', () {
    test('full happy path: idle -> listening -> processing -> recognized', () async {
      final states = <SpeechRecognitionState>[];
      service.stateStream.listen(states.add);

      await service.startListening();
      backend.emitResult('I want water', isFinal: false, confidence: null);
      backend.emitResult('I want water', isFinal: true, confidence: 0.9);
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        SpeechRecognitionState.listening,
        SpeechRecognitionState.processing,
        SpeechRecognitionState.recognized,
      ]);
    });

    test('a final transcript is delivered on the results stream', () async {
      final transcripts = <String>[];
      service.results.listen((r) {
        if (r.isFinal) transcripts.add(r.transcript);
      });

      await service.startListening();
      backend.emitResult('I want water', isFinal: true, confidence: 0.9);
      await Future<void>.delayed(Duration.zero);

      expect(transcripts, ['I want water']);
    });

    test('listening -> error on a platform error', () async {
      await service.startListening();
      backend.emitError('error_no_match');
      expect(service.state, SpeechRecognitionState.error);
    });

    test('a start failure reports error without throwing', () async {
      backend.listenStartsSuccessfully = false;
      await service.startListening();
      expect(service.state, SpeechRecognitionState.error);
    });
  });

  group('prevent double listening', () {
    test('tapping the microphone twice does not start a second session', () async {
      await service.startListening();
      await service.startListening(); // second tap while already listening

      expect(backend.listenCallCount, 1);
    });

    test('a session already processing ignores another start request', () async {
      await service.startListening();
      await service.stopListening(); // -> processing

      await service.startListening();

      expect(backend.listenCallCount, 1);
    });
  });

  group('stop and cancel', () {
    test('stopListening moves to processing and calls the backend once', () async {
      await service.startListening();
      await service.stopListening();

      expect(service.state, SpeechRecognitionState.processing);
      expect(backend.stopCallCount, 1);
    });

    test('cancel discards the session and returns to idle', () async {
      await service.startListening();
      await service.cancel();

      expect(service.state, SpeechRecognitionState.idle);
      expect(backend.cancelCallCount, 1);
    });
  });
}
