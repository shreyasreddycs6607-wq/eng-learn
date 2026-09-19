import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/exercise.dart';
import '../../models/practice_state.dart';
import '../../services/practice_controller.dart';
import '../../services/revision_selector.dart';
import '../../widgets/practice_body.dart';
import '../../widgets/message_view.dart';

/// Today's Revision: RevisionSelector -> exercise IDs -> ExerciseRepository
/// -> PracticeController -> the same PracticeBody the lessons use. No
/// separate exercise renderer, no separate progress system: each answer is
/// recorded by the practice engine through ExerciseProgressRepository.
class DailyRevisionScreen extends StatefulWidget {
  const DailyRevisionScreen({super.key});

  @override
  State<DailyRevisionScreen> createState() => _DailyRevisionScreenState();
}

enum _Phase { loading, error, noHistory, caughtUp, intro, session }

class _DailyRevisionScreenState extends State<DailyRevisionScreen> {
  _Phase _phase = _Phase.loading;
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
      final now = DateTime.now();
      final all = await appServices.exerciseProgress.getAll();
      final selected = RevisionSelector.select(all, now);
      final byId = {for (final e in await appServices.exercises.loadAll()) e.id: e};
      // Progress rows whose exercise no longer exists are simply skipped.
      final exercises = selected.map((s) => byId[s.exerciseId]).whereType<Exercise>().toList();
      if (!mounted) return;
      setState(() {
        _controller = PracticeController(exercises: exercises, progressRepository: appServices.exerciseProgress);
        _phase = all.isEmpty ? _Phase.noHistory : (exercises.isEmpty ? _Phase.caughtUp : _Phase.intro);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[UI] Could not load: $e');
      if (mounted) setState(() => _phase = _Phase.error);
    }
  }

  void _start() {
    _controller!.startSession();
    setState(() => _phase = _Phase.session);
  }

  void _continue() {
    appServices.audio.stop();
    _controller!.continueToNext();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Phase.session:
        final controller = _controller!;
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) => controller.session.status == PracticeStatus.completed
              ? _message(
                  context,
                  title: 'Revision Complete!',
                  body: _summary(controller),
                  button: 'Done',
                  icon: Icons.emoji_events_rounded,
                  tone: _Tone.celebrate,
                  onPressed: () => Navigator.of(context).pop(),
                )
              : PracticeBody(controller: controller, onContinue: _continue),
        );
      case _Phase.error:
        return _message(context,
            title: "Couldn't load revision",
            body: 'Please go back and try again.',
            button: 'Back',
            icon: Icons.error_outline_rounded,
            tone: _Tone.problem,
            onPressed: () => Navigator.of(context).pop());
      case _Phase.noHistory:
        return _message(context,
            title: 'No revision yet',
            body: 'Practice a lesson first. Items you practice will come back here.',
            button: 'Back',
            icon: Icons.menu_book_rounded,
            onPressed: () => Navigator.of(context).pop());
      case _Phase.caughtUp:
        return _message(context,
            title: "You're all caught up!",
            body: 'Nothing to revise right now. Come back tomorrow.',
            button: 'Back',
            icon: Icons.task_alt_rounded,
            tone: _Tone.celebrate,
            onPressed: () => Navigator.of(context).pop());
      case _Phase.intro:
        final n = _controller!.session.total;
        return _message(context,
            title: "Today's Revision",
            body: '$n item${n == 1 ? '' : 's'} \u00b7 about 5 min',
            button: 'Start Revision',
            icon: Icons.autorenew_rounded,
            onPressed: _start);
    }
  }

  String _summary(PracticeController c) {
    final s = c.session;
    return s.incorrectCount == 0
        ? 'You got all ${s.correctCount} right. Well done!'
        : '${s.correctCount} right, ${s.incorrectCount} to practice more. They will come back soon.';
  }

  Widget _message(
    BuildContext context, {
    required String title,
    required String body,
    required String button,
    required IconData icon,
    _Tone tone = _Tone.neutral,
    required VoidCallback onPressed,
  }) {
    final (fg, bg) = switch (tone) {
      _Tone.neutral => (AppColors.primary, AppColors.primarySoft),
      _Tone.celebrate => (AppColors.almost, AppColors.accentSoft),
      _Tone.problem => (AppColors.incorrect, AppColors.incorrectSoft),
    };
    return MessageView(
      icon: icon,
      iconColor: fg,
      iconBackground: bg,
      title: title,
      body: body,
      primaryLabel: button,
      onPrimary: onPressed,
    );
  }
}

enum _Tone { neutral, celebrate, problem }
