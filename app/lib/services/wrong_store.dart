import "package:flutter/foundation.dart";

import "app_storage.dart";

class WrongWord {
  final String surface;
  final String gloss;
  final String lessonTitle;
  final String sentenceText;
  final int wrongAt;

  WrongWord({
    required this.surface,
    required this.gloss,
    required this.lessonTitle,
    required this.sentenceText,
    required this.wrongAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        "surface": surface,
        "gloss": gloss,
        "lessonTitle": lessonTitle,
        "sentenceText": sentenceText,
        "wrongAt": wrongAt,
      };

  factory WrongWord.fromJson(Map<String, dynamic> json) => WrongWord(
        surface: json["surface"] as String? ?? "",
        gloss: json["gloss"] as String? ?? "",
        lessonTitle: json["lessonTitle"] as String? ?? "",
        sentenceText: json["sentenceText"] as String? ?? "",
        wrongAt: json["wrongAt"] as int? ?? 0,
      );
}

class WrongStore extends ChangeNotifier {
  WrongStore._();

  static final WrongStore instance = WrongStore._();

  final List<WrongWord> _items = <WrongWord>[];
  bool _loaded = false;

  List<WrongWord> get items => List<WrongWord>.unmodifiable(_items);
  int get count => _items.length;

  void load() {
    if (_loaded) {
      return;
    }
    _loaded = true;
    final data = AppStorage.readJson("wrongs.json");
    final list = data["items"];
    if (list is List) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _items.add(WrongWord.fromJson(item));
        }
      }
    }
    notifyListeners();
  }

  void add(WrongWord word) {
    _items.removeWhere((w) => w.surface == word.surface && w.lessonTitle == word.lessonTitle);
    _items.insert(0, word);
    if (_items.length > 200) {
      _items.removeRange(200, _items.length);
    }
    _save();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _save();
    notifyListeners();
  }

  void _save() {
    AppStorage.writeJson("wrongs.json", <String, dynamic>{
      "version": 1,
      "items": _items.map((w) => w.toJson()).toList(),
    });
  }
}
