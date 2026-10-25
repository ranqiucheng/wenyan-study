import "dart:io";
import "dart:typed_data";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

import "package:wenyan/data/content_repository.dart";
import "package:wenyan/models/lesson.dart";
import "package:wenyan/models/word_card.dart";
import "package:wenyan/pages/classroom_page.dart";
import "package:wenyan/pages/home_page.dart";
import "package:wenyan/pages/quiz_page.dart";
import "package:wenyan/pages/review_page.dart";
import "package:wenyan/pages/teacher_editor_page.dart";
import "package:wenyan/pages/teacher_shell.dart";
import "package:wenyan/pages/reading_page.dart";
import "package:wenyan/theme.dart";

late List<Lesson> lessons;

Future<void> loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadFont("SimSun", r"C:\Windows\Fonts\simsun.ttc");
    await loadFont("Microsoft YaHei", r"C:\Windows\Fonts\msyh.ttc");
    await loadFont("MaterialIcons", r"D:\dev\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf");
    lessons = await ContentRepository.loadAll();
  });

  testWidgets("reading preview", (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(880, 1800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        fontFamily: "Microsoft YaHei",
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk, elevation: 0, centerTitle: false),
      ),
      home: ReadingPage(lesson: lessons.first),
    ));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/reading.png"));
  });

  testWidgets("home preview", (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(880, 1800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        fontFamily: "Microsoft YaHei",
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk, elevation: 0, centerTitle: false),
      ),
      home: HomePage(loader: () => Future<List<Lesson>>.value(lessons)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/home.png"));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets("review card preview", (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(880, 1800);
    addTearDown(tester.view.reset);
    final card = WordCard(
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
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        fontFamily: "Microsoft YaHei",
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk, elevation: 0, centerTitle: false),
      ),
      home: ReviewPage(previewCards: [card]),
    ));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/review_front.png"));
    await tester.tap(find.textContaining("＿＿＿"));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/review_back.png"));
  });

  testWidgets("quiz preview", (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(880, 1800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        fontFamily: "Microsoft YaHei",
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk, elevation: 0, centerTitle: false),
      ),
      home: QuizPage(previewLessons: lessons),
    ));
    await tester.pump();
    await tester.tap(find.text("开始练习"));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/quiz.png"));
  });

  testWidgets("teacher shell preview", (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        fontFamily: "Microsoft YaHei",
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk, elevation: 0, centerTitle: false),
      ),
      home: TeacherShell(previewLessons: lessons),
    ));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/teacher_shell.png"));
  });

  testWidgets("teacher editor preview", (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(1600, 1200);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        fontFamily: "Microsoft YaHei",
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk, elevation: 0, centerTitle: false),
      ),
      home: TeacherEditorPage(lesson: lessons.first),
    ));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/teacher_editor.png"));
  });

  testWidgets("classroom preview", (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(1760, 1100);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        fontFamily: "Microsoft YaHei",
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(backgroundColor: kPaper, foregroundColor: kInk, elevation: 0, centerTitle: false),
      ),
      home: ClassroomPage(lesson: lessons.first),
    ));
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile("goldens/classroom.png"));
  });
}
