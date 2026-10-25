import "package:flutter/foundation.dart";

import "app_storage.dart";

class StatsStore extends ChangeNotifier {
  StatsStore._();

  static final StatsStore instance = StatsStore._();

  String _day = "";
  int reviews = 0;
  int quizSessions = 0;
  int questions = 0;
  int correct = 0;
  bool _loaded = false;

  int get accuracy => questions == 0 ? 0 : (correct * 100 / questions).round();

  void load() {
    if (_loaded) {
      return;
    }
    _loaded = true;
    final data = AppStorage.readJson("stats.json");
    _day = data["day"] as String? ?? "";
    reviews = data["reviews"] as int? ?? 0;
    quizSessions = data["quizSessions"] as int? ?? 0;
    questions = data["questions"] as int? ?? 0;
    correct = data["correct"] as int? ?? 0;
    _ensureToday();
    notifyListeners();
  }

  void recordReview() {
    _ensureToday();
    reviews += 1;
    _save();
    notifyListeners();
  }

  void recordQuiz({required int total, required int correctAnswers}) {
    _ensureToday();
    quizSessions += 1;
    questions += total;
    correct += correctAnswers;
    _save();
    notifyListeners();
  }

  DateTime get dayStart => DateTime.now();

  bool _ensureToday() {
    final today = _format(DateTime.now());
    if (_day == today) {
      return false;
    }
    _day = today;
    reviews = 0;
    quizSessions = 0;
    questions = 0;
    correct = 0;
    _save();
    return true;
  }

  String _format(DateTime time) {
    final month = time.month.toString().padLeft(2, "0");
    final day = time.day.toString().padLeft(2, "0");
    return "${time.year}-$month-$day";
  }

  void _save() {
    AppStorage.writeJson("stats.json", <String, dynamic>{
      "day": _day,
      "reviews": reviews,
      "quizSessions": quizSessions,
      "questions": questions,
      "correct": correct,
    });
  }
}
