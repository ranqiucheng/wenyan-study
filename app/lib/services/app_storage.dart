import "dart:convert";
import "dart:io";

/// 纯 Dart 本地存储：JSON 文件，Windows 与 Android 通用，不依赖原生插件。
class AppStorage {
  AppStorage._();

  static Directory? _dir;

  /// 仅测试使用：设置后所有读写都走该目录。
  static Directory? overrideDir;

  static Directory dataDir() {
    final override = overrideDir;
    if (override != null) {
      if (!override.existsSync()) {
        override.createSync(recursive: true);
      }
      return override;
    }
    final cached = _dir;
    if (cached != null) {
      return cached;
    }
    late Directory dir;
    if (Platform.isAndroid) {
      // 应用私有目录；包名变更时需要同步修改。
      dir = Directory("/data/data/com.wenyan.wenyan/files");
    } else if (Platform.isWindows) {
      final base = Platform.environment["APPDATA"] ?? Directory.current.path;
      dir = Directory("$base/wenyan");
    } else {
      dir = Directory("${Directory.current.path}/.wenyan_data");
    }
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  static File file(String name) {
    return File("${dataDir().path}/$name");
  }

  static Map<String, dynamic> readJson(String name) {
    try {
      final f = file(name);
      if (!f.existsSync()) {
        return <String, dynamic>{};
      }
      final decoded = jsonDecode(f.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static void writeJson(String name, Map<String, dynamic> data) {
    try {
      file(name).writeAsStringSync(jsonEncode(data), flush: true);
    } catch (_) {
      // 存储失败不阻塞使用；后续可加日志。
    }
  }
}
