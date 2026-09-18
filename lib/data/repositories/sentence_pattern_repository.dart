import '../../models/sentence_pattern.dart';
import '../local/content/content_service.dart';

class SentencePatternRepository {
  final ContentService _content;
  List<SentencePattern>? _cache;

  SentencePatternRepository(this._content);

  Future<List<SentencePattern>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _content.loadArray('assets/content/sentence_patterns.json', 'sentencePatterns');
    final patterns = json.map((j) => SentencePattern.fromJson(j as Map<String, dynamic>)).toList();
    _cache = patterns;
    return patterns;
  }
}
