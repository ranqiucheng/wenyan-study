import "dart:math";

import "../models/lesson.dart";
import "wrong_store.dart";

class QuizQuestion {
  final String surface;
  final String gloss;
  final String sentenceText;
  final String lessonTitle;
  final List<String> options;
  final String analysis;

  QuizQuestion({
    required this.surface,
    required this.gloss,
    required this.sentenceText,
    required this.lessonTitle,
    required this.options,
    this.analysis = "",
  });
}

class _Entry {
  final String surface;
  final String gloss;
  final String sentenceText;
  final String lessonTitle;

  _Entry(this.surface, this.gloss, this.sentenceText, this.lessonTitle);
}

List<QuizQuestion> buildQuiz(List<Lesson> lessons, {int count = 10, Random? random}) {
  final rnd = random ?? Random();
  final pool = <_Entry>[];
  for (final lesson in lessons) {
    for (final sentence in lesson.sentences) {
      for (final token in sentence.tokens) {
        if (token.gloss.isNotEmpty) {
          pool.add(_Entry(token.surface, token.gloss, sentence.text, lesson.title));
        }
      }
    }
  }
  pool.shuffle(rnd);
  final chosen = pool.take(count).toList();
  final glossPool = pool.map((e) => e.gloss).toSet().toList();

  return chosen.map((entry) {
    final options = <String>{entry.gloss};
    final others = List<String>.of(glossPool)..shuffle(rnd);
    for (final gloss in others) {
      if (options.length >= 4) {
        break;
      }
      options.add(gloss);
    }
    final list = options.toList()..shuffle(rnd);
    return QuizQuestion(
      surface: entry.surface,
      gloss: entry.gloss,
      sentenceText: entry.sentenceText,
      lessonTitle: entry.lessonTitle,
      options: list,
    );
  }).toList();
}


List<QuizQuestion> buildQuizFromWrongs(
  List<WrongWord> wrongs,
  List<Lesson> lessons, {
  int count = 10,
  Random? random,
}) {
  final rnd = random ?? Random();
  final entries = <_Entry>[];
  for (final wrong in wrongs) {
    if (wrong.gloss.isNotEmpty) {
      entries.add(_Entry(wrong.surface, wrong.gloss, wrong.sentenceText, wrong.lessonTitle));
    }
  }
  if (entries.isEmpty) {
    return <QuizQuestion>[];
  }
  entries.shuffle(rnd);
  final chosen = entries.take(count).toList();
  final glossPool = <String>{};
  for (final lesson in lessons) {
    for (final sentence in lesson.sentences) {
      for (final token in sentence.tokens) {
        if (token.gloss.isNotEmpty) {
          glossPool.add(token.gloss);
        }
      }
    }
  }
  for (final entry in entries) {
    glossPool.add(entry.gloss);
  }
  final pool = glossPool.toList();
  return chosen.map((entry) {
    final options = <String>{entry.gloss};
    final others = List<String>.of(pool)..shuffle(rnd);
    for (final gloss in others) {
      if (options.length >= 4) {
        break;
      }
      options.add(gloss);
    }
    final list = options.toList()..shuffle(rnd);
    return QuizQuestion(
      surface: entry.surface,
      gloss: entry.gloss,
      sentenceText: entry.sentenceText,
      lessonTitle: entry.lessonTitle,
      options: list,
    );
  }).toList();
}
