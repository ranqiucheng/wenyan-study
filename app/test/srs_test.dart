import "package:flutter_test/flutter_test.dart";

import "package:wenyan/models/word_card.dart";
import "package:wenyan/services/srs.dart";

WordCard makeCard() => WordCard(
      id: "quanxue::quanxue-001::1",
      surface: "已",
      pos: "动词",
      gloss: "停止",
      lessonId: "quanxue",
      lessonTitle: "劝学",
      sentenceId: "quanxue-001",
      sentenceText: "君子曰：学不可以已。",
      createdAt: 0,
      dueAt: 0,
    );

void main() {
  test("记得会延长复习间隔", () {
    final card = makeCard();
    Srs.rate(card, 2);
    final first = card.intervalDays;
    expect(card.reps, 1);
    expect(first, greaterThan(0));
    Srs.rate(card, 2);
    expect(card.intervalDays, greaterThanOrEqualTo(first));
  });

  test("忘记会重置间隔并记 lapses", () {
    final card = makeCard();
    Srs.rate(card, 3);
    expect(card.intervalDays, greaterThan(0));
    Srs.rate(card, 0);
    expect(card.lapses, 1);
    expect(card.intervalDays, 0);
    expect(card.state, 1);
  });

  test("ease 不会低于下限", () {
    final card = makeCard();
    for (var i = 0; i < 20; i++) {
      Srs.rate(card, 0);
    }
    expect(card.ease, greaterThanOrEqualTo(1.3));
  });
}
