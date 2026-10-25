import "dart:io";

import "package:archive/archive.dart";
import "package:flutter_test/flutter_test.dart";

import "package:wenyan/models/lesson.dart";
import "package:wenyan/models/custom_question.dart";
import "package:wenyan/services/content_exporter.dart";
import "package:wenyan/services/content_importer.dart";
import "package:wenyan/services/imported_content_store.dart";
import "package:wenyan/services/teacher_store.dart";

Lesson makeLesson() => Lesson(
      id: "quanxue",
      title: "劝学",
      author: "荀子",
      source: "《荀子》",
      volume: "必修上册",
      tags: const ["课标"],
      reviewed: false,
      summary: "测试",
      sentences: const [
        Sentence(
          id: "quanxue-001",
          order: 1,
          text: "君子曰：学不可以已。",
          translation: "君子说：学习是不可以停止的。",
          tokens: [
            Token(surface: "君子", pos: "名词", gloss: "有修养的人"),
            Token(surface: "已", pos: "动词", gloss: "停止"),
          ],
        ),
      ],
    );

void main() {
  test("编辑会叠加到原始内容", () {
    final store = TeacherStore.instance;
    store.setToken(lessonId: "quanxue", sentenceId: "quanxue-001", index: 1, pos: "动词", gloss: "停止（改）");
    store.setTranslation(lessonId: "quanxue", sentenceId: "quanxue-001", text: "君子说：学习不可以停下。");
    store.setReviewed("quanxue", true);
    final applied = store.apply(makeLesson());
    expect(applied.sentences.first.tokens[1].gloss, "停止（改）");
    expect(applied.sentences.first.translation, "君子说：学习不可以停下。");
    expect(applied.reviewed, isTrue);
    expect(store.editCountForLesson("quanxue"), greaterThanOrEqualTo(2));
    store.clearAll();
  });

  test("导出的 .wyc 含 manifest 与内容", () {
    final dir = Directory.systemTemp.createTempSync("wenyan_export_");
    final file = ContentExporter.export(lessons: [makeLesson()], outDir: dir);
    expect(file.existsSync(), isTrue);
    final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    final manifestFile = archive.findFile("manifest.json");
    expect(manifestFile, isNotNull);
    final manifestText = String.fromCharCodes(manifestFile!.content as List<int>);
    expect(manifestText.contains("contentVersion"), isTrue);
    expect(archive.findFile("content/index.json"), isNotNull);
    expect(archive.findFile("content/lessons/quanxue.json"), isNotNull);
    dir.deleteSync(recursive: true);
  });

  test("导出到指定文件路径", () {
    final dir = Directory.systemTemp.createTempSync("wenyan_save_");
    final target = File("${dir.path}/my-pack.wyc");
    final file = ContentExporter.exportTo(lessons: [makeLesson()], file: target);
    expect(file.path, target.path);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
    dir.deleteSync(recursive: true);
  });

  test("新建篇目/句子/词条并合并导出", () {
    final store = TeacherStore.instance;
    final created = store.createLesson(title: "自建篇", author: "老师", source: "自建", volume: "必修上册");
    store.addSentence(created, text: "学而时习之。", translation: "学习并时常温习。");
    var applied = store.apply(created);
    expect(applied.sentences.length, 1);
    final sentenceId = applied.sentences.first.id;
    store.addToken(created, sentenceId, surface: "习", pos: "动词", gloss: "温习");
    applied = store.apply(created);
    expect(applied.sentences.first.tokens.first.gloss, "温习");
    final all = store.applyAll([makeLesson()]);
    expect(all.length, 2);
    store.clearAll();
  });

  test("删除篇目/句子/词条", () {
    final store = TeacherStore.instance;
    final created = store.createLesson(title: "删除测试", author: "老师", source: "自建", volume: "必修上册");
    store.addSentence(created, text: "测试句。", translation: "测试译文。");
    var applied = store.apply(created);
    final sid = applied.sentences.first.id;
    store.addToken(created, sid, surface: "测试", pos: "名词", gloss: "测试释义");
    applied = store.apply(created);
    expect(applied.sentences.first.tokens.length, 1);
    store.deleteToken(created, sid, 0);
    applied = store.apply(created);
    expect(applied.sentences.first.tokens, isEmpty);
    store.deleteSentence(created, sid);
    applied = store.apply(created);
    expect(applied.sentences, isEmpty);
    store.deleteLesson(created.id);
    final all = store.applyAll([makeLesson()]);
    expect(all.any((lesson) => lesson.id == created.id), isFalse);
    store.clearAll();
  });

  test("自定义题目导出后再导入", () {
    final store = TeacherStore.instance;
    final question = CustomQuestion(
      id: "q_test",
      lessonId: "quanxue",
      sentence: "君子曰：学不可以已。",
      surface: "已",
      answer: "停止",
      options: ["停止", "开始", "已经", "完毕"],
      analysis: "已，停止。",
    );
    store.addQuestion(question);
    final dir = Directory.systemTemp.createTempSync("wenyan_question_");
    final file = ContentExporter.export(lessons: [makeLesson()], outDir: dir, questions: store.questions);
    ContentImporter.importFile(file);
    expect(ImportedContentStore.instance.allQuestions.any((q) => q.id == "q_test"), isTrue);
    ImportedContentStore.instance.clear();
    store.removeQuestion("q_test");
    dir.deleteSync(recursive: true);
  });

  test("篇目排序会持久化顺序", () {
    final store = TeacherStore.instance;
    store.moveLesson([makeLesson(), makeLesson()], "quanxue", 1);
    expect(store.questions, isEmpty);
    store.clearAll();
  });
}
