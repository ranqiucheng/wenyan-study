import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:wenyan/data/content_repository.dart";
import "package:wenyan/models/lesson.dart";
import "package:wenyan/pages/teacher_editor_page.dart";
import "package:wenyan/pages/teacher_shell.dart";

late List<Lesson> lessons;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    lessons = await ContentRepository.loadAll();
  });

  testWidgets("teacher shell renders", (tester) async {
    await tester.pumpWidget(MaterialApp(home: TeacherShell(previewLessons: lessons)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text("内容编辑"), findsOneWidget);
  });

  testWidgets("editor renders every lesson", (tester) async {
    for (final lesson in lessons) {
      await tester.pumpWidget(MaterialApp(home: TeacherEditorPage(lesson: lesson)));
      await tester.pump();
      final error = tester.takeException();
      expect(error, isNull, reason: "lesson ${lesson.title}: $error");
      expect(find.textContaining(lesson.title), findsWidgets, reason: lesson.title);
    }
  });
}
