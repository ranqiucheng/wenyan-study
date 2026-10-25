import "dart:convert";
import "dart:io";

import "package:archive/archive.dart";
import "package:crypto/crypto.dart";

import "imported_content_store.dart";

class ImportResult {
  final int lessonCount;
  final int sentenceCount;
  final String contentVersion;
  final String checksum;

  ImportResult({
    required this.lessonCount,
    required this.sentenceCount,
    required this.contentVersion,
    required this.checksum,
  });
}

class ContentImporter {
  ContentImporter._();

  static ImportResult importFile(File file) {
    if (!file.existsSync()) {
      throw const FormatException("文件不存在");
    }
    return importBytes(file.readAsBytesSync());
  }

  static ImportResult importBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile("manifest.json");
    if (manifestFile == null) {
      throw const FormatException("内容包缺少 manifest.json");
    }
    final manifestRaw = manifestFile.content as List<int>;
    final manifest = jsonDecode(utf8.decode(manifestRaw)) as Map<String, dynamic>;
    if (manifest["schemaVersion"] != 1) {
      throw FormatException("不支持的内容包版本：${manifest["schemaVersion"]}");
    }
    final contentVersion = manifest["contentVersion"] as String? ?? "unknown";
    final expectedChecksum = manifest["checksum"] as String? ?? "";

    final entries = <String, List<int>>{};
    for (final entry in archive.files) {
      if (entry.name.startsWith("content/") && entry.isFile) {
        entries[entry.name.substring("content/".length)] = entry.content as List<int>;
      }
    }
    if (entries.isEmpty) {
      throw const FormatException("内容包里没有 content/ 目录");
    }
    final names = entries.keys.toList()..sort();
    final buffer = <int>[];
    for (final name in names) {
      buffer.addAll(utf8.encode(name));
      buffer.addAll(entries[name]!);
    }
    final actualChecksum = "sha256:${sha256.convert(buffer)}";
    if (expectedChecksum.isNotEmpty && expectedChecksum != actualChecksum) {
      throw const FormatException("内容包校验和不匹配，文件可能损坏");
    }

    final indexBytes = entries["index.json"];
    if (indexBytes == null) {
      throw const FormatException("内容包缺少 index.json");
    }
    final index = jsonDecode(utf8.decode(indexBytes)) as Map<String, dynamic>;
    final lessonEntries = index["lessons"] as List<dynamic>? ?? <dynamic>[];
    final lessons = <Map<String, dynamic>>[];
    var sentenceCount = 0;
    for (final item in lessonEntries) {
      final map = item as Map<String, dynamic>;
      final rel = map["file"] as String? ?? "";
      final bytes = entries[rel];
      if (bytes == null) {
        throw FormatException("缺少篇目文件：$rel");
      }
      final lesson = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      lessons.add(lesson);
      sentenceCount += (lesson["sentences"] as List<dynamic>? ?? <dynamic>[]).length;
    }

    final questions = <Map<String, dynamic>>[];
    final questionBytes = entries["questions.json"];
    if (questionBytes != null) {
      final payload = jsonDecode(utf8.decode(questionBytes));
      if (payload is Map<String, dynamic>) {
        for (final item in payload["questions"] as List<dynamic>? ?? <dynamic>[]) {
          if (item is Map<String, dynamic>) {
            questions.add(item);
          }
        }
      }
    }

    ImportedContentStore.instance.addPack(
      contentVersion: contentVersion,
      checksum: actualChecksum,
      lessons: lessons,
      questions: questions,
    );
    return ImportResult(
      lessonCount: lessons.length,
      sentenceCount: sentenceCount,
      contentVersion: contentVersion,
      checksum: actualChecksum,
    );
  }
}
