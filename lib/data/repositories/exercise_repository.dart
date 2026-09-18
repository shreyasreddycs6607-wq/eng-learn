import '../../models/exercise.dart';
import '../local/content/content_service.dart';

class ExerciseRepository {
  final ContentService _content;
  List<Exercise>? _cache;

  ExerciseRepository(this._content);

  Future<List<Exercise>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _content.loadArray('assets/content/exercises.json', 'exercises');
    final exercises = json.map((j) => Exercise.fromJson(j as Map<String, dynamic>)).toList();
    _cache = exercises;
    return exercises;
  }

  /// Exercises for a lesson, in their defined `order` — never JSON file order.
  /// Conversation reply exercises are reached through their conversation.
  Future<List<Exercise>> forLesson(String lessonId) async {
    final list = (await loadAll()).where((e) => e.lessonId == lessonId && e.conversationId == null).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}
