import "dart:convert";

import "package:flutter/services.dart";

import "../models/lesson.dart";
import "../services/imported_content_store.dart";

class ContentRepository {
  static const String _root = "assets/content";

  static Future<List<Lesson>> loadAll() async {
    final indexRaw = await rootBundle.loadString("$_root/index.json");
    final index = jsonDecode(indexRaw) as Map<String, dynamic>;
    final entries = (index["lessons"] as List<dynamic>? ?? []);
    final lessons = <Lesson>[];
    for (final entry in entries) {
      final map = entry as Map<String, dynamic>;
      final raw = await rootBundle.loadString("$_root/${map["file"]}");
      lessons.add(Lesson.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    final store = ImportedContentStore.instance;
    store.load();
    return store.merge(lessons);
  }
}
