import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/progress.dart';
import '../../models/reminder_setting.dart';
import '../../widgets/secondary_button.dart';
import '../lesson/lesson_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Lesson> _lessons = [];
  Map<String, LessonProgress> _progress = {};
  int _streak = 0;
  ReminderSetting _reminder = const ReminderSetting();
  bool _changingReminder = false;
  bool _loading = true;
  bool _failed = false;

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
      final reminder = await appServices.reminders.current();
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
        _progress = progress;
        _streak = profile.streak;
        _reminder = reminder;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[PROGRESS] Could not load progress: $e');
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  bool _opening = false;

  void _say(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _reloadReminder() async {
    final setting = await appServices.reminders.current();
    if (mounted) setState(() => _reminder = setting);
  }

  Future<void> _toggleReminder(bool on) async {
    if (_changingReminder) return;
    _changingReminder = true;
    try {
      if (on) {
        final allowed = await appServices.reminders.enable(_reminder.minutesOfDay);
        if (!allowed && mounted) _say("Notifications are turned off for this app. You can allow them in your phone's Settings.");
      } else {
        await appServices.reminders.disable();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[REMINDER] Could not change the reminder: $e');
      if (mounted) _say("Couldn't change the reminder. Please try again.");
    } finally {
      _changingReminder = false;
    }
    await _reloadReminder();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute),
    );
    if (picked == null) return;
    try {
      await appServices.reminders.changeTime(picked.hour * 60 + picked.minute);
    } catch (e) {
      if (kDebugMode) debugPrint('[REMINDER] Could not change the time: $e');
      if (mounted) _say("Couldn't change the reminder time. Please try again.");
    }
    await _reloadReminder();
  }

  Widget _reminderCard(BuildContext context) {
    final time = TimeOfDay(hour: _reminder.hour, minute: _reminder.minute).format(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Daily reminder', style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Text(
                _reminder.enabled ? 'Every day at $time' : 'Off. Turn on for a gentle daily reminder to practise.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              value: _reminder.enabled,
              onChanged: _toggleReminder,
            ),
            if (_reminder.enabled) ...[
              const SizedBox(height: 8),
              SecondaryButton(label: 'Change time', onPressed: _pickReminderTime),
            ],
          ],
        ),
      ),
    );
  }

  /// Redo a finished lesson (lessons -> practice -> speaking, exactly as the first time).
  Future<void> _reopen(Lesson lesson) async {
    if (_opening) return; // a double tap must not stack two lessons
    _opening = true;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)));
    _opening = false;
    _load();
  }

  Future<void> _resetProgress() async {
    await appServices.progressRepository.resetAll();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Progress')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Couldn't load your progress. Please go back and try again.",
                style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          ),
        ),
      );
    }

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
          const SizedBox(height: 24),
          _reminderCard(context),
          const SizedBox(height: 32),
          Text('Lessons', style: Theme.of(context).textTheme.headlineMedium),
          if (completedLessons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tap a finished lesson to do it again.', style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          ..._lessons.map((l) => _lessonRow(context, l, _progress[l.id]?.completed == true)),
          if (kDebugMode) ...[
            const SizedBox(height: 32),
            OutlinedButton(onPressed: _resetProgress, child: const Text('Reset progress (debug)')),
          ],
        ],
      ),
    );
  }

  /// A finished lesson is tappable (redo it); one not finished yet is just listed —
  /// the Home screen's Continue button takes the learner to the next lesson.
  Widget _lessonRow(BuildContext context, Lesson lesson, bool completed) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: completed ? AppColors.correct : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.kannadaTitle, style: Theme.of(context).textTheme.bodyLarge),
                Text(lesson.title, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (completed) const Icon(Icons.replay_rounded, color: AppColors.primary),
        ],
      ),
    );
    if (!completed) return row;
    return Semantics(
      button: true,
      label: 'Do ${lesson.title} again',
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: () => _reopen(lesson), child: row),
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
