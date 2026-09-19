import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/progress.dart';
import '../../models/reminder_setting.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/secondary_button.dart';
import '../../widgets/soft_card.dart';
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
    final text = Theme.of(context).textTheme;
    final time = TimeOfDay(hour: _reminder.hour, minute: _reminder.minute).format(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 8, 14, 16),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: IconBadge(
              icon: _reminder.enabled ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              background: _reminder.enabled ? AppColors.accentSoft : AppColors.primarySoft,
              foreground: _reminder.enabled ? AppColors.almost : AppColors.primary,
            ),
            title: Text('Daily reminder', style: text.titleMedium),
            subtitle: Text(
              _reminder.enabled ? 'Every day at $time' : 'Off. Turn on for a gentle daily reminder to practise.',
              style: text.bodyMedium,
            ),
            value: _reminder.enabled,
            onChanged: _toggleReminder,
          ),
          if (_reminder.enabled) ...[
            const SizedBox(height: 4),
            SecondaryButton(label: 'Change time', icon: Icons.schedule_rounded, onPressed: _pickReminderTime),
          ],
        ],
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen, 32),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _stat(context, Icons.menu_book_rounded, AppColors.primary, AppColors.primarySoft, '${completedLessons.length}', 'Lessons')),
                const SizedBox(width: 10),
                Expanded(child: _stat(context, Icons.spellcheck_rounded, AppColors.correct, AppColors.correctSoft, '$wordsLearned', 'Words')),
                const SizedBox(width: 10),
                Expanded(child: _stat(context, Icons.local_fire_department_rounded, AppColors.almost, AppColors.accentSoft, '$_streak', _streak == 1 ? 'Day streak' : 'Days streak')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _reminderCard(context),
          const SizedBox(height: 28),
          Text('Lessons', style: text.titleLarge),
          if (completedLessons.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tap a finished lesson to do it again.', style: text.bodyMedium),
          ],
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < _lessons.length; i++) ...[
                  if (i > 0) const Divider(indent: 20, endIndent: 20),
                  _lessonRow(context, _lessons[i], _progress[_lessons[i].id]?.completed == true),
                ],
              ],
            ),
          ),
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
    final text = Theme.of(context).textTheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? AppColors.correct : AppColors.background,
              border: completed ? null : Border.all(color: AppColors.border, width: 2),
            ),
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                : Text('${lesson.order}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.kannadaTitle, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(lesson.title, style: text.bodyMedium),
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
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _reopen(lesson), child: row),
    );
  }

  Widget _stat(BuildContext context, IconData icon, Color color, Color background, String value, String label) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        children: [
          IconBadge(icon: icon, size: 40, background: background, foreground: color),
          const SizedBox(height: 10),
          Text(value, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: text.bodyMedium?.copyWith(fontSize: 15), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
