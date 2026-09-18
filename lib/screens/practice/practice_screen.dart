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
  }

  void _goToSpeaking(PracticeController controller) {
    appServices.audio.stop();
    final session = controller.session;
    Navigator.of(context).push(
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
