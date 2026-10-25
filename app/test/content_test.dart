import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:wenyan/data/content_repository.dart";
import "package:wenyan/models/lesson.dart";
import "package:wenyan/pages/reading_page.dart";

late List<Lesson> lessons;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    lessons = await ContentRepository.loadAll();
  });

  test("加载 3 篇示例内容", () {
    expect(lessons.length, greaterThanOrEqualTo(35));
    expect(lessons.first.title, "劝学");
    expect(lessons.first.sentences.length, greaterThanOrEqualTo(10));
    expect(lessons.first.sentences.first.tokens, isNotEmpty);
  });

  testWidgets("阅读页能渲染原文与标题", (tester) async {
    await tester.pumpWidget(MaterialApp(home: ReadingPage(lesson: lessons.first)));
    await tester.pump();
    expect(find.text("劝学"), findsWidgets);
    expect(find.textContaining("学不可以已"), findsOneWidget);
  });
}
