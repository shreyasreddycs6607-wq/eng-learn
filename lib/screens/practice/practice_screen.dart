import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../models/lesson.dart';
import '../../models/practice_state.dart';
import '../../services/practice_controller.dart';
import '../../widgets/practice_body.dart';
import '../speaking/speaking_screen.dart';

class PracticeScreen extends StatefulWidget {
  final Lesson lesson;

  const PracticeScreen({super.key, required this.lesson});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _loading = true;
  bool _failed = false;
  bool _wentToSpeaking = false;
  PracticeController? _controller;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    appServices.audio.stop();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final exercises = await appServices.exercises.forLesson(widget.lesson.id);
      if (!mounted) return;
      final controller = PracticeController(
        lesson: widget.lesson,
        exercises: exercises,
        progressRepository: appServices.exerciseProgress,
      );
      controller.startSession();
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[PRACTICE] Could not load exercises: $e');
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _goToSpeaking(PracticeController controller) {
    if (_wentToSpeaking) return;
    _wentToSpeaking = true;
    appServices.audio.stop();
    final session = controller.session;
    // Replace this screen: the session is over, so Back from Speaking should
    // return to the lesson, not to a finished practice screen that can't be answered.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SpeakingScreen(
          lesson: widget.lesson,
          correct: session.correctCount,
          incorrect: session.incorrectCount,
          total: session.total,
        ),
      ),
    );
  }

  void _continue(PracticeController controller) {
    // Only a tap on the feedback card advances; a stray second tap must not
    // fall through to the "finished" branch and navigate again.
    if (controller.session.status != PracticeStatus.showingFeedback) return;
    appServices.audio.stop();
    controller.continueToNext();
    if (controller.session.status == PracticeStatus.completed) {
      _goToSpeaking(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_failed) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Couldn't load the practice. Please go back and try again.",
                style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final controller = _controller!;
    if (controller.session.status == PracticeStatus.completed) {
      // No exercises authored yet for this lesson — skip straight through.
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToSpeaking(controller));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => PracticeBody(
        controller: controller,
        onContinue: () => _continue(controller),
      ),
    );
  }
}
