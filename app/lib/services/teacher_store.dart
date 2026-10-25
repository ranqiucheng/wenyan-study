import "package:flutter/foundation.dart";

import "../models/lesson.dart";
import "../models/custom_question.dart";
import "app_storage.dart";
import "content_exporter.dart";

/// 老师端的本地改稿：差异编辑 + 新建/删除篇目。
class TeacherStore extends ChangeNotifier {
  TeacherStore._();

  static final TeacherStore instance = TeacherStore._();

  final Map<String, Map<String, dynamic>> _tokens = <String, Map<String, dynamic>>{};
  final Map<String, String> _translations = <String, String>{};
  final Map<String, bool> _reviewed = <String, bool>{};
  final Map<String, Map<String, dynamic>> _fullLessons = <String, Map<String, dynamic>>{};
  final Set<String> _deletedLessons = <String>{};
  final List<CustomQuestion> _questions = <CustomQuestion>[];
  final List<String> _lessonOrder = <String>[];
  bool _loaded = false;

  bool get loaded => _loaded;

  void load() {
    if (_loaded) {
      return;
    }
    _loaded = true;
    final data = AppStorage.readJson("teacher_edits.json");
    final tokens = data["tokens"];
    if (tokens is Map) {
      tokens.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _tokens[key.toString()] = value;
        }
      });
    }
    final translations = data["translations"];
    if (translations is Map) {
      translations.forEach((key, value) {
        if (value is String) {
          _translations[key.toString()] = value;
        }
      });
    }
    final reviewed = data["reviewed"];
    if (reviewed is Map) {
      reviewed.forEach((key, value) {
        if (value is bool) {
          _reviewed[key.toString()] = value;
        }
      });
    }
    final lessons = data["lessons"];
    if (lessons is Map) {
      lessons.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          _fullLessons[key.toString()] = value;
        }
      });
    }
    final deleted = data["deleted"];
    if (deleted is List) {
      for (final item in deleted) {
        if (item is String) {
          _deletedLessons.add(item);
        }
      }
    }
    final questions = data["questions"];
    if (questions is List) {
      for (final item in questions) {
        if (item is Map<String, dynamic>) {
          _questions.add(CustomQuestion.fromJson(item));
        }
      }
    }
    final lessonOrder = data["lessonOrder"];
    if (lessonOrder is List) {
      for (final item in lessonOrder) {
        if (item is String) {
          _lessonOrder.add(item);
        }
      }
    }
    notifyListeners();
  }

  bool hasTokenEdit(String lessonId, String sentenceId, int index) {
    return _tokens.containsKey("$lessonId::$sentenceId::$index");
  }

  bool hasTranslationEdit(String lessonId, String sentenceId) {
    return _translations.containsKey("$lessonId::$sentenceId");
  }

  int editCountForLesson(String lessonId) {
    final prefix = "$lessonId::";
    var count = _tokens.keys.where((k) => k.startsWith(prefix)).length;
    count += _translations.keys.where((k) => k.startsWith(prefix)).length;
    if (_fullLessons.containsKey(lessonId)) {
      count += 1;
    }
    return count;
  }

  bool reviewedFor(String lessonId) => _reviewed[lessonId] ?? false;

  bool isCreated(String lessonId) => _fullLessons.containsKey(lessonId);

  bool isDeleted(String lessonId) => _deletedLessons.contains(lessonId);

  int get createdCount => _fullLessons.length;

  void setToken({
    required String lessonId,
    required String sentenceId,
    required int index,
    required String pos,
    required String gloss,
  }) {
    _tokens["$lessonId::$sentenceId::$index"] = <String, dynamic>{"pos": pos, "gloss": gloss};
    _save();
    notifyListeners();
  }

  void setTranslation({required String lessonId, required String sentenceId, required String text}) {
    _translations["$lessonId::$sentenceId"] = text;
    _save();
    notifyListeners();
  }

  void setReviewed(String lessonId, bool value) {
    _reviewed[lessonId] = value;
    _save();
    notifyListeners();
  }

  void markAllReviewed(List<Lesson> lessons) {
    for (final lesson in lessons) {
      _reviewed[lesson.id] = true;
    }
    _save();
    notifyListeners();
  }

  Lesson createLesson({
    required String title,
    required String author,
    required String source,
    required String volume,
    String summary = "",
    List<String> tags = const <String>["自建"],
  }) {
    final id = "custom_${DateTime.now().millisecondsSinceEpoch}";
    final lesson = Lesson(
      id: id,
      title: title,
      author: author,
      source: source,
      volume: volume,
      tags: tags,
      reviewed: false,
      summary: summary,
      sentences: const <Sentence>[],
    );
    _fullLessons[id] = ContentExporter.lessonToJson(lesson);
    _save();
    notifyListeners();
    return lesson;
  }

  void deleteLesson(String lessonId) {
    _deletedLessons.add(lessonId);
    _fullLessons.remove(lessonId);
    _reviewed.remove(lessonId);
    _bakeDiffs(lessonId);
    _save();
    notifyListeners();
  }

  void addSentence(Lesson base, {required String text, required String translation}) {
    final current = apply(base);
    final sentences = List<Sentence>.of(current.sentences);
    sentences.add(Sentence(
      id: "s_${DateTime.now().millisecondsSinceEpoch}",
      order: sentences.length + 1,
      text: text,
      translation: translation,
      tokens: const <Token>[],
    ));
    _saveFull(_rebuild(current, sentences));
  }

  void deleteSentence(Lesson base, String sentenceId) {
    final current = apply(base);
    final sentences = current.sentences.where((s) => s.id != sentenceId).toList();
    _fullLessons[base.id] = ContentExporter.lessonToJson(_rebuild(current, sentences));
    _bakeDiffs(base.id);
    _save();
    notifyListeners();
  }

  void addToken(Lesson base, String sentenceId, {required String surface, required String pos, required String gloss}) {
    final current = apply(base);
    final sentences = current.sentences.map((sentence) {
      if (sentence.id != sentenceId) {
        return sentence;
      }
      final tokens = List<Token>.of(sentence.tokens)
        ..add(Token(surface: surface, pos: pos, gloss: gloss));
      return Sentence(
        id: sentence.id,
        order: sentence.order,
        text: sentence.text,
        translation: sentence.translation,
        tokens: tokens,
      );
    }).toList();
    _saveFull(_rebuild(current, sentences));
  }

  void deleteToken(Lesson base, String sentenceId, int index) {
    final current = apply(base);
    final sentences = current.sentences.map((sentence) {
      if (sentence.id != sentenceId) {
        return sentence;
      }
      final tokens = List<Token>.of(sentence.tokens);
      if (index >= 0 && index < tokens.length) {
        tokens.removeAt(index);
      }
      return Sentence(
        id: sentence.id,
        order: sentence.order,
        text: sentence.text,
        translation: sentence.translation,
        tokens: tokens,
      );
    }).toList();
    _fullLessons[base.id] = ContentExporter.lessonToJson(_rebuild(current, sentences));
    _bakeDiffs(base.id);
    _save();
    notifyListeners();
  }

  Lesson _rebuild(Lesson current, List<Sentence> sentences) {
    return Lesson(
      id: current.id,
      title: current.title,
      author: current.author,
      source: current.source,
      volume: current.volume,
      tags: current.tags,
      reviewed: current.reviewed,
      summary: current.summary,
      sentences: sentences,
    );
  }

  void _saveFull(Lesson lesson) {
    _fullLessons[lesson.id] = ContentExporter.lessonToJson(lesson);
    _save();
    notifyListeners();
  }

  /// 原始篇目 + 老师新建的篇目（排除已删除）。
  List<Lesson> baseLessonsWithCreated(List<Lesson> base) {
    final result = base.where((lesson) => !_deletedLessons.contains(lesson.id)).toList();
    final ids = result.map((l) => l.id).toSet();
    for (final entry in _fullLessons.entries) {
      if (!ids.contains(entry.key) && !_deletedLessons.contains(entry.key)) {
        result.add(Lesson.fromJson(entry.value));
      }
    }
    if (_lessonOrder.isNotEmpty) {
      result.sort((a, b) {
        final ia = _lessonOrder.indexOf(a.id);
        final ib = _lessonOrder.indexOf(b.id);
        if (ia == -1 && ib == -1) return 0;
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });
    }
    return result;
  }

  List<Lesson> applyAll(List<Lesson> base) {
    return baseLessonsWithCreated(base).map(apply).toList();
  }

  Lesson apply(Lesson base) {
    final full = _fullLessons[base.id];
    final source = full == null ? base : Lesson.fromJson(full);
    final sentences = <Sentence>[];
    for (final sentence in source.sentences) {
      final tokens = <Token>[];
      for (var i = 0; i < sentence.tokens.length; i++) {
        final token = sentence.tokens[i];
        final edit = _tokens["${base.id}::${sentence.id}::$i"];
        if (edit == null) {
          tokens.add(token);
          continue;
        }
        final pos = (edit["pos"] as String?) ?? "";
        final gloss = (edit["gloss"] as String?) ?? "";
        tokens.add(Token(
          surface: token.surface,
          pos: pos.isEmpty ? token.pos : pos,
          gloss: gloss.isEmpty ? token.gloss : gloss,
        ));
      }
      final translation = _translations["${base.id}::${sentence.id}"] ?? sentence.translation;
      sentences.add(Sentence(
        id: sentence.id,
        order: sentence.order,
        text: sentence.text,
        translation: translation,
        tokens: tokens,
      ));
    }
    return Lesson(
      id: source.id,
      title: source.title,
      author: source.author,
      source: source.source,
      volume: source.volume,
      tags: source.tags,
      reviewed: _reviewed[base.id] ?? source.reviewed,
      summary: source.summary,
      sentences: sentences,
    );
  }

  List<CustomQuestion> get questions => List<CustomQuestion>.unmodifiable(_questions);

  List<CustomQuestion> questionsForLesson(String lessonId) {
    return _questions.where((q) => q.lessonId == lessonId).toList();
  }

  void addQuestion(CustomQuestion question) {
    _questions.add(question);
    _save();
    notifyListeners();
  }

  void removeQuestion(String questionId) {
    _questions.removeWhere((q) => q.id == questionId);
    _save();
    notifyListeners();
  }

  void moveLesson(List<Lesson> current, String lessonId, int delta) {
    final ids = current.map((l) => l.id).toList();
    final index = ids.indexOf(lessonId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= ids.length) {
      return;
    }
    ids.removeAt(index);
    ids.insert(target, lessonId);
    _lessonOrder
      ..clear()
      ..addAll(ids);
    _save();
    notifyListeners();
  }

  void _bakeDiffs(String lessonId) {
    final prefix = "$lessonId::";
    _tokens.removeWhere((key, _) => key.startsWith(prefix));
    _translations.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clearAll() {
    _questions.clear();
    _lessonOrder.clear();
    _tokens.clear();
    _translations.clear();
    _reviewed.clear();
    _fullLessons.clear();
    _deletedLessons.clear();
    _save();
    notifyListeners();
  }

  void _save() {
    AppStorage.writeJson("teacher_edits.json", <String, dynamic>{
      "version": 3,
      "tokens": _tokens,
      "translations": _translations,
      "reviewed": _reviewed,
      "lessons": _fullLessons,
      "deleted": _deletedLessons.toList(),
      "questions": _questions.map((q) => q.toJson()).toList(),
      "lessonOrder": _lessonOrder,
    });
  }
}
