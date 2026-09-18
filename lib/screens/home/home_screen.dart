import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../models/lesson.dart';
import '../../models/mastery_level.dart';
import '../../models/progress.dart';
import '../../services/revision_selector.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/lesson_card.dart';
import '../conversation/conversation_list_screen.dart';
import '../lesson/lesson_screen.dart';
import '../progress/progress_screen.dart';
import '../revision/daily_revision_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Lesson> _lessons = [];
  Map<String, LessonProgress> _progress = {};
  int _streak = 0;
  int _revisionCount = 0;
  bool _hasHistory = false;
  Map<MasteryLevel, int> _mastery = {};
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lessons = await appServices.lessons.loadAll();
      final progress = await appServices.progress.loadAllProgress();
      final profile = await appServices.progress.loadProfile();
      final attempts = await appServices.exerciseProgress.getAll();
      final mastery = await appServices.exerciseProgress.masterySummary();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _progress = progress;
        _streak = profile.streak;
        _revisionCount =
            RevisionSelector.select(attempts, DateTime.now()).length;
        _hasHistory = attempts.isNotEmpty;
        _mastery = mastery;
        _loading = false;
      });
    } catch (e) {
      // Bundled content/database failure — should only happen from a
      // packaging bug, but must never leave the learner on a blank screen.
      if (kDebugMode) debugPrint('[HOME] Could not load: $e');
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Lesson get _nextLesson {
    for (final lesson in _lessons) {
      if (_progress[lesson.id]?.completed != true) return lesson;
    }
    return _lessons.last;
  }

  bool _opening = false;

  Future<void> _continueLesson() async {
    if (_opening) return; // a double tap on the lesson card must not stack two lessons
    _opening = true;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonScreen(lesson: _nextLesson)),
    );
    _opening = false;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Couldn't load your lessons.",
                    style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Try again',
                  onPressed: () {
                    setState(() {
                      _error = false;
                      _loading = true;
                    });
                    _load();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final next = _nextLesson;
    final isFirstTime = _progress.isEmpty;
    final completedCount = _progress.values.where((p) => p.completed).length;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text('English ಕಲಿಯೋಣ ❤️',
                        style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 32),
                    Text(
                        isFirstTime ? "Let's learn English." : "Today's Lesson",
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    LessonCard(
                        lesson: next, completed: false, onTap: _continueLesson),
                    const Spacer(),
                    PrimaryButton(
                      label: isFirstTime
                          ? 'Start Lesson'
                          : 'Continue → ${next.title}',
                      onPressed: _continueLesson,
                    ),
                    const SizedBox(height: 16),
                    if (!isFirstTime) ...[
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Text('$_streak day${_streak == 1 ? '' : 's'}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          const Spacer(),
                          Text(_progressDots(completedCount, _lessons.length),
                              style: const TextStyle(
                                  fontSize: 18, letterSpacing: 2)),
                        ],
                      ),
                      if (_hasHistory)
                        Text(
                          'Learning ${_mastery[MasteryLevel.learning] ?? 0} · Practicing ${_mastery[MasteryLevel.practicing] ?? 0} · Comfortable ${_mastery[MasteryLevel.comfortable] ?? 0}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 16),
                    ],
                    SecondaryButton(
                      label: 'Real-Life Practice',
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ConversationListScreen()),
                        );
                        _load();
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'My Progress',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ProgressScreen()),
                      ),
                    ),
                    if (_hasHistory) ...[
                      const SizedBox(height: 12),
                      SecondaryButton(
                        label: _revisionCount > 0
                            ? "Today's Revision ($_revisionCount)"
                            : "Today's Revision",
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const DailyRevisionScreen()),
                          );
                          _load();
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _progressDots(int completed, int total) {
    return List.generate(total, (i) => i < completed ? '●' : '○').join(' ');
  }
}
