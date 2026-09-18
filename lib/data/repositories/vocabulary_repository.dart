import '../../models/vocabulary.dart';
import '../local/content/content_service.dart';

class VocabularyRepository {
  final ContentService _content;
  List<Vocabulary>? _cache;

  VocabularyRepository(this._content);

  Future<List<Vocabulary>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _content.loadArray('assets/content/vocabulary.json', 'vocabulary');
    final words = json.map((j) => Vocabulary.fromJson(j as Map<String, dynamic>)).toList();
    _cache = words;
    return words;
  }
}
