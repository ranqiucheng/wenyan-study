import "dart:io";

import "package:flutter_test/flutter_test.dart";

import "package:wenyan/data/content_repository.dart";
import "package:wenyan/models/lesson.dart";
import "package:wenyan/services/content_exporter.dart";
import "package:wenyan/services/app_storage.dart";
import "package:wenyan/services/content_importer.dart";
import "package:wenyan/services/imported_content_store.dart";

Lesson makeLesson() => Lesson(
      id: "test_lesson",
      title: "测试篇",
      author: "测试",
      source: "《测试》",
      volume: "必修上册",
      tags: const ["课标"],
      reviewed: true,
      summary: "导入测试",
      sentences: const [
        Sentence(
          id: "test-001",
          order: 1,
          text: "学而时习之，不亦说乎？",
          translation: "学习并且时常温习，不也是快乐的吗？",
          tokens: [
            Token(surface: "说", pos: "形容词", gloss: "通“悦”，愉快"),
          ],
        ),
      ],
    );

late Directory testDataDir;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    testDataDir = Directory.systemTemp.createTempSync("wenyan_data_");
    AppStorage.overrideDir = testDataDir;
  });

  tearDownAll(() {
    AppStorage.overrideDir = null;
    if (testDataDir.existsSync()) {
      testDataDir.deleteSync(recursive: true);
    }
  });

  test("导出再导入：校验通过并合并到内容库", () {
    final dir = Directory.systemTemp.createTempSync("wenyan_import_");
    final file = ContentExporter.export(lessons: [makeLesson()], outDir: dir);
    final result = ContentImporter.importFile(file);
    expect(result.lessonCount, 1);
    expect(result.sentenceCount, 1);
    expect(result.checksum.startsWith("sha256:"), isTrue);
    expect(ImportedContentStore.instance.lessonCount, greaterThanOrEqualTo(1));
    ImportedContentStore.instance.clear();
    dir.deleteSync(recursive: true);
  });

  test("导入后合并进内容库", () async {
    final dir = Directory.systemTemp.createTempSync("wenyan_import2_");
    final file = ContentExporter.export(lessons: [makeLesson()], outDir: dir);
    ContentImporter.importFile(file);
    final lessons = await ContentRepository.loadAll();
    expect(lessons.any((lesson) => lesson.id == "test_lesson"), isTrue);
    ImportedContentStore.instance.clear();
    dir.deleteSync(recursive: true);
  });
}
