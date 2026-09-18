import '../../models/conversation.dart';
import '../local/content/content_service.dart';

class ConversationRepository {
  final ContentService _content;
  List<Conversation>? _cache;

  ConversationRepository(this._content);

  /// In ID order — a fixed, deterministic list.
  Future<List<Conversation>> loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final json = await _content.loadArray('assets/content/conversations.json', 'conversations');
    final list = json.map((j) => Conversation.fromJson(j as Map<String, dynamic>)).toList()..sort((a, b) => a.id.compareTo(b.id));
    _cache = list;
    return list;
  }
}
