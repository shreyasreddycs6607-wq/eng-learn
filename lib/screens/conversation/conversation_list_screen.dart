import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/conversation.dart';
import '../../models/exercise_progress.dart';
import 'conversation_screen.dart';

/// Real-Life Practice: the fixed list of situations. Whether one was
/// practiced / is due for review is derived from the existing per-exercise
/// progress — there is no separate conversation progress store.
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  static const _icons = {
    ConversationCategory.home: Icons.home_rounded,
    ConversationCategory.family: Icons.family_restroom_rounded,
    ConversationCategory.shopping: Icons.shopping_cart_rounded,
    ConversationCategory.phone: Icons.phone_rounded,
    ConversationCategory.travel: Icons.directions_bus_rounded,
    ConversationCategory.doctor: Icons.local_hospital_rounded,
    ConversationCategory.neighbour: Icons.people_rounded,
    ConversationCategory.food: Icons.restaurant_rounded,
  };

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
  (String, IconData?) _status(Conversation c) {
    final now = DateTime.now();
    final items = c.responseExerciseIds.map((id) => _progress[id]).toList();
    if (items.any((p) => p != null && p.isDueBy(now))) return ('Review', null);
    if (items.every((p) => p != null)) return ('Practice again', Icons.check_circle_rounded);
    return ('Start', null);
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
    final (label, doneIcon) = _status(c);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _open(c),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(_icons[c.category], color: AppColors.primary, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: Theme.of(context).textTheme.headlineMedium),
                    Text(c.kannadaTitle, style: Theme.of(context).textTheme.bodyLarge),
                    Text('${c.turns.length} turns', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Column(
                children: [
                  if (doneIcon != null) Icon(doneIcon, color: AppColors.correct),
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
