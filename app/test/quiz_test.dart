import "dart:math";

import "package:flutter_test/flutter_test.dart";

import "package:wenyan/models/lesson.dart";
import "package:wenyan/services/quiz_builder.dart";
import "package:wenyan/services/wrong_store.dart";

Lesson makeLesson() => Lesson(
      id: "quanxue",
      title: "劝学",
      author: "荀子",
      source: "《荀子》",
      volume: "必修上册",
      tags: const ["课标"],
      reviewed: true,
      summary: "",
      sentences: const [
        Sentence(
          id: "s1",
          order: 1,
          text: "君子曰：学不可以已。",
          translation: "君子说：学习是不可以停止的。",
          tokens: [
            Token(surface: "已", pos: "动词", gloss: "停止"),
            Token(surface: "君子", pos: "名词", gloss: "有修养的人"),
          ],
        ),
      ],
    );

void main() {
  test("错题重练生成有效题目", () {
    final wrongs = [
      WrongWord(surface: "已", gloss: "停止", lessonTitle: "劝学", sentenceText: "君子曰：学不可以已。", wrongAt: 0),
    ];
    final questions = buildQuizFromWrongs(wrongs, [makeLesson()], random: Random(1));
    expect(questions.length, 1);
    expect(questions.first.surface, "已");
    expect(questions.first.options.contains(questions.first.gloss), isTrue);
    expect(questions.first.options.length, greaterThanOrEqualTo(2));
  });
}
