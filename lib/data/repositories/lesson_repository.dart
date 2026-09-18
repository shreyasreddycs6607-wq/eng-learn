import '../../models/lesson.dart';
import '../../models/lesson_content.dart';
import '../local/content/content_service.dart';

/// Loads lessons.json + lesson_content.json and assembles each Lesson's
/// `contents` (ordered by each record's own `order` field, per the schema
/// contract — never by JSON array position). Curriculum-wide cross-reference
/// validation lives in CurriculumValidator, not here.
class LessonRepository {
  final ContentService _content;
  List<Lesson>? _cache;
  List<LessonContent>? _contentCache;

  LessonRepository(this._content);

  Future<List<Lesson>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;

    final lessonJson = await _content.loadArray('assets/content/lessons.json', 'lessons');
    final lessons = lessonJson.map((j) => Lesson.fromJson(j as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final contents = await loadAllContent();
    final contentsByLesson = <String, List<LessonContent>>{};
    for (final c in contents) {
      contentsByLesson.putIfAbsent(c.lessonId, () => []).add(c);
    }

    final assembled = lessons.map((lesson) {
      final items = List<LessonContent>.from(contentsByLesson[lesson.id] ?? const []);
      items.sort((a, b) => a.order.compareTo(b.order));
      return lesson.withContents(items);
    }).toList();

    _cache = assembled;
    return assembled;
  }

  Future<List<LessonContent>> loadAllContent() async {
    final cached = _contentCache;
    if (cached != null) return cached;
    final json = await _content.loadArray('assets/content/lesson_content.json', 'content');
    final contents = json.map((j) => LessonContent.fromJson(j as Map<String, dynamic>)).toList();
    _contentCache = contents;
    return contents;
  }

  Future<Lesson?> byId(String id) async {
    for (final lesson in await loadAll()) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }
}
