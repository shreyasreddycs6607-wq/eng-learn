import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/mastery_level.dart';
import '../../models/progress.dart';
import '../../services/revision_selector.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/message_view.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';
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
        _revisionCount = RevisionSelector.select(attempts, DateTime.now()).length;
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

  /// Opens [screen] and refreshes Home when the learner comes back. A double
  /// tap on a card must never stack two copies of the same screen.
  Future<void> _open(Widget screen) async {
    if (_opening) return;
    _opening = true;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _opening = false;
    _load();
  }

  Future<void> _continueLesson() => _open(LessonScreen(lesson: _nextLesson));

  /// Kannada first, English underneath — by the phone's local time.
  (String, String) get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return ('ಶುಭೋದಯ', 'Good morning');
    if (hour < 17) return ('ಶುಭ ಮಧ್ಯಾಹ್ನ', 'Good afternoon');
    return ('ಶುಭ ಸಂಜೆ', 'Good evening');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error) {
      return MessageView(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.incorrect,
        iconBackground: AppColors.incorrectSoft,
        title: "Couldn't load your lessons.",
        primaryLabel: 'Try again',
        onPrimary: () {
          setState(() {
            _error = false;
            _loading = true;
          });
          _load();
        },
      );
    }

    final text = Theme.of(context).textTheme;
    final isFirstTime = _progress.isEmpty;
    final (greetingKn, greetingEn) = _greeting;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 20, AppSpacing.screen, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greetingKn, style: text.displaySmall),
                        Text(isFirstTime ? "Let's learn English." : greetingEn, style: text.bodyMedium),
                      ],
                    ),
                  ),
                  if (!isFirstTime) ...[const SizedBox(width: 12), _StreakChip(days: _streak)],
                ],
              ),
              const SizedBox(height: 24),
              _HeroCard(
                lesson: _nextLesson,
                total: _lessons.length,
                completed: _progress.values.where((p) => p.completed).length,
                firstTime: isFirstTime,
                onContinue: _continueLesson,
              ),
              const SizedBox(height: 28),
              Text('Practice', style: text.titleLarge),
              const SizedBox(height: 12),
              _practiceTiles(context),
              const SizedBox(height: 12),
              _progressTile(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _practiceTiles(BuildContext context) {
    final conversations = _PracticeTile(
      icon: Icons.forum_rounded,
      iconBackground: AppColors.accentSoft,
      iconColor: AppColors.almost,
      title: 'Real-Life Practice',
      subtitle: 'Short conversations',
      onTap: () => _open(const ConversationListScreen()),
    );
    if (!_hasHistory) return conversations;

    final revision = _PracticeTile(
      icon: Icons.autorenew_rounded,
      iconBackground: AppColors.primarySoft,
      iconColor: AppColors.primary,
      title: "Today's Revision",
      subtitle: _revisionCount > 0 ? '$_revisionCount to review' : 'All caught up',
      badge: _revisionCount > 0 ? '$_revisionCount' : null,
      onTap: () => _open(const DailyRevisionScreen()),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: revision), const SizedBox(width: 12), Expanded(child: conversations)],
      ),
    );
  }

  Widget _progressTile(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      onTap: () => _open(const ProgressScreen()),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const IconBadge(icon: Icons.bar_chart_rounded, background: AppColors.primarySoft, foreground: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Progress', style: text.titleMedium),
                if (_hasHistory)
                  Wrap(
                    spacing: 12,
                    children: [
                      _MasteryDot(color: AppColors.textSecondary, label: 'Learning', count: _mastery[MasteryLevel.learning] ?? 0),
                      _MasteryDot(color: AppColors.accent, label: 'Practicing', count: _mastery[MasteryLevel.practicing] ?? 0),
                      _MasteryDot(color: AppColors.correct, label: 'Comfortable', count: _mastery[MasteryLevel.comfortable] ?? 0),
                    ],
                  )
                else
                  Text('Lessons, words and streak', style: text.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// "Continue where you stopped": the one obvious action on Home.
class _HeroCard extends StatelessWidget {
  final Lesson lesson;
  final int total;
  final int completed;
  final bool firstTime;
  final VoidCallback onContinue;

  const _HeroCard({
    required this.lesson,
    required this.total,
    required this.completed,
    required this.firstTime,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : completed / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(
          children: [
            // Soft decorative discs — depth without images.
            Positioned(right: -40, top: -50, child: _disc(170, 0.07)),
            Positioned(left: -30, bottom: -60, child: _disc(150, 0.05)),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      firstTime ? 'START HERE' : 'CONTINUE LEARNING',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(lesson.kannadaTitle, style: text.displaySmall?.copyWith(color: Colors.white)),
                  Text(lesson.title, style: text.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.22),
                            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$completed of $total', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: firstTime ? 'Start Lesson' : 'Continue',
                    icon: Icons.play_arrow_rounded,
                    color: Colors.white,
                    foregroundColor: AppColors.primary,
                    onPressed: onContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _disc(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)),
      );
}

class _StreakChip extends StatelessWidget {
  final int days;

  const _StreakChip({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.accent, size: 24),
          const SizedBox(width: 6),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.almost),
          ),
        ],
      ),
    );
  }
}

class _PracticeTile extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _PracticeTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBadge(icon: icon, size: 52, background: iconBackground, foreground: iconColor),
              if (badge != null)
                Container(
                  constraints: const BoxConstraints(minWidth: 30),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(16)),
                  child: Text(badge!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: text.titleMedium),
          const SizedBox(height: 2),
          Text(subtitle, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _MasteryDot extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _MasteryDot({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Flexible(child: Text('$label $count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15))),
      ],
    );
  }
}
