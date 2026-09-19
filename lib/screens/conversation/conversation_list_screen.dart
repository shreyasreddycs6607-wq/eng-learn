import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/conversation.dart';
import '../../models/exercise_progress.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/soft_card.dart';
import 'conversation_screen.dart';
import 'conversation_style.dart';

/// Real-Life Practice: the fixed list of situations. Whether one was
/// practiced / is due for review is derived from the existing per-exercise
/// progress — there is no separate conversation progress store.
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<Conversation> _conversations = [];
  Map<String, ExerciseProgress> _progress = {};
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final conversations = await appServices.conversations.loadAll();
      final progress = await appServices.exerciseProgress.getAll();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _progress = {for (final p in progress) p.exerciseId: p};
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[UI] Could not load: $e');
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  /// "Review" when something in it is due, a check once every reply has been
  /// tried, otherwise "Start".
  (String, Color, Color, IconData?) _status(Conversation c) {
    final now = DateTime.now();
    final items = c.responseExerciseIds.map((id) => _progress[id]).toList();
    if (items.any((p) => p != null && p.isDueBy(now))) return ('Review', AppColors.almost, AppColors.accentSoft, null);
    if (items.every((p) => p != null)) return ('Practice again', AppColors.correct, AppColors.correctSoft, Icons.check_rounded);
    return ('Start', AppColors.primary, AppColors.primarySoft, null);
  }

  bool _opening = false;

  Future<void> _open(Conversation c) async {
    if (_opening) return; // a double tap on a card must not open the conversation twice
    _opening = true;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ConversationScreen(conversation: c)));
    _opening = false;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Life Practice')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed || _conversations.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No conversations are available right now.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Choose a situation', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    for (final c in _conversations) _card(context, c),
                  ],
                ),
    );
  }

  Widget _card(BuildContext context, Conversation c) {
    final text = Theme.of(context).textTheme;
    final style = ConversationStyle.of(c.category);
    final (label, fg, bg, doneIcon) = _status(c);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        onTap: () => _open(c),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            IconBadge(icon: style.icon, size: 60, background: style.background, foreground: style.foreground),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title, style: text.titleLarge),
                  Text(c.kannadaTitle, style: text.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (doneIcon != null) ...[Icon(doneIcon, size: 16, color: fg), const SizedBox(width: 4)],
                            Flexible(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg))),
                          ],
                        ),
                      ),
                      Text('${c.turns.length} turns', style: text.bodyMedium?.copyWith(fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
