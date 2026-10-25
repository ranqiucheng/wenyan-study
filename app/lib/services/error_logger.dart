import "dart:io";

import "app_storage.dart";

class ErrorLogger {
  ErrorLogger._();

  static void log(Object error, StackTrace? stack) {
    try {
      final file = File("${AppStorage.dataDir().path}/error.log");
      final text = "\n[${DateTime.now().toIso8601String()}]\n$error\n${stack ?? ""}\n";
      file.writeAsStringSync(text, mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
