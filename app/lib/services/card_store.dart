import "package:flutter/foundation.dart";

import "../models/lesson.dart";
import "../models/word_card.dart";
import "app_storage.dart";
import "srs.dart";
import "stats_store.dart";

class CardStore extends ChangeNotifier {
  CardStore._();

  static final CardStore instance = CardStore._();

  final List<WordCard> _cards = <WordCard>[];
  bool _loaded = false;

  List<WordCard> get cards => List<WordCard>.unmodifiable(_cards);
  int get total => _cards.length;

  void load() {
    if (_loaded) {
      return;
    }
    _loaded = true;
    final data = AppStorage.readJson("cards.json");
    final list = data["cards"];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _cards.add(WordCard.fromJson(item));
        }
      }
    }
    notifyListeners();
  }

  List<WordCard> dueCards([DateTime? now]) {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final result = _cards.where((c) => c.dueAt <= t).toList();
    result.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return result;
  }

  int get dueCount => dueCards().length;

  bool addFromToken({
    required Lesson lesson,
    required Sentence sentence,
    required Token token,
    required int index,
  }) {
    final id = "${lesson.id}::${sentence.id}::$index";
    if (_cards.any((c) => c.id == id)) {
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    _cards.add(WordCard(
      id: id,
      surface: token.surface,
      pos: token.pos,
      gloss: token.gloss,
      lessonId: lesson.id,
      lessonTitle: lesson.title,
      sentenceId: sentence.id,
      sentenceText: sentence.text,
      createdAt: now,
      dueAt: now,
    ));
    _save();
    notifyListeners();
    return true;
  }

  int addAllFromLesson(Lesson lesson) {
    var added = 0;
    for (final sentence in lesson.sentences) {
      for (var i = 0; i < sentence.tokens.length; i++) {
        if (addFromToken(lesson: lesson, sentence: sentence, token: sentence.tokens[i], index: i)) {
          added++;
        }
      }
    }
    return added;
  }

  void rate(WordCard card, int rating) {
    Srs.rate(card, rating);
    StatsStore.instance.recordReview();
    _save();
    notifyListeners();
  }

  void clear() {
    _cards.clear();
    _save();
    notifyListeners();
  }

  void _save() {
    AppStorage.writeJson("cards.json", <String, dynamic>{
      "version": 1,
      "cards": _cards.map((c) => c.toJson()).toList(),
    });
  }
}
