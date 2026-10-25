import "dart:io";

import "package:flutter/foundation.dart";

import "../models/custom_question.dart";
import "../models/lesson.dart";
import "app_storage.dart";

class ImportedPack {
  final String contentVersion;
  final String checksum;
  final int importedAt;
  final List<Map<String, dynamic>> lessons;
  final List<Map<String, dynamic>> questions;

  ImportedPack({
    required this.contentVersion,
    required this.checksum,
    required this.importedAt,
    required this.lessons,
    this.questions = const <Map<String, dynamic>>[],
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        "contentVersion": contentVersion,
        "checksum": checksum,
        "importedAt": importedAt,
        "lessons": lessons,
        "questions": questions,
      };

  factory ImportedPack.fromJson(Map<String, dynamic> json) => ImportedPack(
        contentVersion: json["contentVersion"] as String? ?? "",
        checksum: json["checksum"] as String? ?? "",
        importedAt: json["importedAt"] as int? ?? 0,
        lessons: (json["lessons"] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(),
        questions: (json["questions"] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
}

class ImportedContentStore extends ChangeNotifier {
  ImportedContentStore._();

  static final ImportedContentStore instance = ImportedContentStore._();

  final List<ImportedPack> _packs = <ImportedPack>[];
  bool _loaded = false;

  List<ImportedPack> get packs => List<ImportedPack>.unmodifiable(_packs);

  Directory get importsDir => Directory("${AppStorage.dataDir().path}/imports");

  void load() {
    if (_loaded) {
      return;
    }
    _loaded = true;
    final data = AppStorage.readJson("imported_content.json");
    final list = data["packs"];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _packs.add(ImportedPack.fromJson(item));
        }
      }
    }
    notifyListeners();
  }

  List<File> scanPackFiles() {
    try {
      final dir = importsDir;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
        return const <File>[];
      }
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith(".wyc"))
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (_) {
      return const <File>[];
    }
  }

  void addPack({
    required String contentVersion,
    required String checksum,
    required List<Map<String, dynamic>> lessons,
    List<Map<String, dynamic>> questions = const <Map<String, dynamic>>[],
  }) {
    _packs.add(ImportedPack(
      contentVersion: contentVersion,
      checksum: checksum,
      importedAt: DateTime.now().millisecondsSinceEpoch,
      lessons: lessons,
      questions: questions,
    ));
    _save();
    notifyListeners();
  }

  void removePack(ImportedPack pack) {
    _packs.remove(pack);
    _save();
    notifyListeners();
  }

  void clear() {
    _packs.clear();
    _save();
    notifyListeners();
  }

  int get lessonCount {
    final ids = <String>{};
    for (final pack in _packs) {
      for (final raw in pack.lessons) {
        final id = raw["id"];
        if (id is String) {
          ids.add(id);
        }
      }
    }
    return ids.length;
  }

  List<CustomQuestion> get allQuestions {
    final result = <CustomQuestion>[];
    for (final pack in _packs) {
      for (final raw in pack.questions) {
        result.add(CustomQuestion.fromJson(raw));
      }
    }
    return result;
  }

  List<Lesson> merge(List<Lesson> base) {
    if (_packs.isEmpty) {
      return base;
    }
    final byId = <String, Lesson>{for (final lesson in base) lesson.id: lesson};
    final order = base.map((l) => l.id).toList();
    for (final pack in _packs) {
      for (final raw in pack.lessons) {
        final lesson = Lesson.fromJson(raw);
        if (!byId.containsKey(lesson.id)) {
          order.add(lesson.id);
        }
        byId[lesson.id] = lesson;
      }
    }
    return order.map((id) => byId[id]!).toList();
  }

  void _save() {
    AppStorage.writeJson("imported_content.json", <String, dynamic>{
      "version": 1,
      "packs": _packs.map((p) => p.toJson()).toList(),
    });
  }
}
