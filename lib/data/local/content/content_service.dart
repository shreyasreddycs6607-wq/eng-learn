import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../models/content_manifest.dart';

class ContentLoadException implements Exception {
  final String message;
  ContentLoadException(this.message);

  @override
  String toString() => 'ContentLoadException: $message';
}

/// Loads and caches bundled curriculum JSON from assets/content/. The only
/// place in the app that touches rootBundle for curriculum — repositories
/// call this, widgets never do.
class ContentService {
  final Map<String, Map<String, dynamic>> _cache = {};
  ContentManifest? _manifest;

  /// Loads a JSON object file and returns the array stored under [key]
  /// (e.g. loadArray('assets/content/lessons.json', 'lessons')).
  Future<List<dynamic>> loadArray(String assetPath, String key) async {
    final json = await _loadObject(assetPath);
    final array = json[key];
    if (array is! List) {
      throw ContentLoadException('$assetPath is missing its "$key" array');
    }
    return array;
  }

  Future<Map<String, dynamic>> _loadObject(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache[assetPath] = decoded;
      return decoded;
    } catch (e) {
      throw ContentLoadException('Failed to load $assetPath: $e');
    }
  }

  Future<ContentManifest> manifest() async {
    final cached = _manifest;
    if (cached != null) return cached;
    final json = await _loadObject('assets/content/content_manifest.json');
    final manifest = ContentManifest.fromJson(json);
    _manifest = manifest;
    return manifest;
  }
}
