import "dart:convert";
import "dart:io";

import "package:archive/archive.dart";
import "package:crypto/crypto.dart";

import "../models/custom_question.dart";
import "../models/lesson.dart";

class ContentExporter {
  ContentExporter._();

  static File export({
    required List<Lesson> lessons,
    required Directory outDir,
    List<CustomQuestion> questions = const <CustomQuestion>[],
    String contentVersion = "2026.10-m3",
  }) {
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r"[^0-9]"), "").substring(0, 14);
    return exportTo(
      lessons: lessons,
      file: File("${outDir.path}/wenyan-content-$stamp.wyc"),
      questions: questions,
      contentVersion: contentVersion,
    );
  }

  static File exportTo({
    required List<Lesson> lessons,
    required File file,
    List<CustomQuestion> questions = const <CustomQuestion>[],
    String contentVersion = "2026.10-m3",
  }) {
    final files = <String, List<int>>{};
    final index = <String, dynamic>{
      "schemaVersion": 1,
      "contentVersion": contentVersion,
      "lessons": [
        for (final lesson in lessons)
          <String, dynamic>{
            "id": lesson.id,
            "title": lesson.title,
            "author": lesson.author,
            "volume": lesson.volume,
            "file": "lessons/${lesson.id}.json",
          },
      ],
    };
    files["index.json"] = utf8.encode(jsonEncode(index));
    for (final lesson in lessons) {
      files["lessons/${lesson.id}.json"] = utf8.encode(jsonEncode(lessonToJson(lesson)));
    }
    files["questions.json"] = utf8.encode(jsonEncode(<String, dynamic>{
      "questions": questions.map((q) => q.toJson()).toList(),
    }));

    final names = files.keys.toList()..sort();
    final checksumInput = <int>[];
    for (final name in names) {
      checksumInput.addAll(utf8.encode(name));
      checksumInput.addAll(files[name]!);
    }
    final checksum = "sha256:${sha256.convert(checksumInput)}";

    final counts = <String, int>{
      "lessons": lessons.length,
      "sentences": lessons.fold<int>(0, (sum, l) => sum + l.sentences.length),
      "tokens": lessons.fold<int>(0, (sum, l) => sum + l.sentences.fold<int>(0, (s, x) => s + x.tokens.length)),
      "questions": questions.length,
    };
    final manifest = <String, dynamic>{
      "schemaVersion": 1,
      "contentVersion": contentVersion,
      "builtAt": DateTime.now().toIso8601String(),
      "counts": counts,
      "checksum": checksum,
      "minAppVersion": "0.1.0",
    };

    final archive = Archive();
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(ArchiveFile("manifest.json", manifestBytes.length, manifestBytes));
    for (final name in names) {
      final data = files[name]!;
      archive.addFile(ArchiveFile("content/$name", data.length, data));
    }
    final zip = ZipEncoder().encode(archive);
    if (zip == null) {
      throw StateError("内容包打包失败");
    }

    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(zip, flush: true);
    return file;
  }

  static Map<String, dynamic> lessonToJson(Lesson lesson) {
    return <String, dynamic>{
      "id": lesson.id,
      "title": lesson.title,
      "author": lesson.author,
      "source": lesson.source,
      "volume": lesson.volume,
      "tags": lesson.tags,
      "reviewed": lesson.reviewed,
      "summary": lesson.summary,
      "sentences": [
        for (final sentence in lesson.sentences)
          <String, dynamic>{
            "id": sentence.id,
            "order": sentence.order,
            "text": sentence.text,
            "translation": sentence.translation,
            "tokens": [
              for (final token in sentence.tokens)
                <String, dynamic>{
                  "surface": token.surface,
                  "pos": token.pos,
                  "gloss": token.gloss,
                },
            ],
          },
      ],
    };
  }
}
