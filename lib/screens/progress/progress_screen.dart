import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/progress.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Lesson> _lessons = [];
  Map<String, LessonProgress> _progress = {};
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await appServices.lessons.loadAll();
    final progress = await appServices.progress.loadAllProgress();
    final profile = await appServices.progress.loadProfile();
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _progress = progress;
      _streak = profile.streak;
      _loading = false;
    });
  }

  Future<void> _resetProgress() async {
    await appServices.progressRepository.resetAll();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final completedLessons = _lessons.where((l) => _progress[l.id]?.completed == true);
    final wordsLearned = appServices.progress.totalWordsLearned(_lessons, _progress);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _stat(context, 'Lessons completed', '${completedLessons.length}'),
          const SizedBox(height: 24),
          _stat(context, 'Words learned', '$wordsLearned'),
          const SizedBox(height: 24),
          _stat(context, '🔥 Streak', '$_streak days'),
          const SizedBox(height: 32),
          Text('Lessons', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          ..._lessons.map((l) => _lessonRow(context, l.title, _progress[l.id]?.completed == true)),
          if (kDebugMode) ...[
            const SizedBox(height: 32),
            OutlinedButton(onPressed: _resetProgress, child: const Text('Reset progress (debug)')),
          ],
        ],
      ),
    );
  }

  Widget _lessonRow(BuildContext context, String title, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: completed ? AppColors.correct : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.displayMedium),
          ],
        ),
      ),
    );
  }
}
