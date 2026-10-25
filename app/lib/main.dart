import "dart:io";
import "dart:typed_data";
import "dart:ui" show PlatformDispatcher;

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "pages/home_shell.dart";
import "services/content_importer.dart";
import "services/error_logger.dart";
import "theme.dart";

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();

const MethodChannel _incomingChannel = MethodChannel("wenyan/file_picker");

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    ErrorLogger.log(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogger.log(error, stack);
    return false;
  };
  ErrorWidget.builder = (details) {
    return Material(
      color: kPaper,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(
            "页面出错：\n${details.exceptionAsString()}\n\n日志已写入：%APPDATA%\\wenyan\\error.log",
            style: const TextStyle(color: Colors.red, fontSize: 13, height: 1.6),
          ),
        ),
      ),
    );
  };
  runApp(const WenyanApp());
  if (Platform.isAndroid) {
    _incomingChannel.setMethodCallHandler((call) async {
      if (call.method == "incomingPack" && call.arguments is Map) {
        _handleIncomingPack(Map<Object?, Object?>.from(call.arguments as Map));
      }
      return null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initial = await _incomingChannel.invokeMethod<Map<Object?, Object?>>("getInitialPack");
        if (initial != null) {
          _handleIncomingPack(initial);
        }
      } catch (_) {}
    });
  }
}

void _handleIncomingPack(Map<Object?, Object?> args) {
  final bytes = args["bytes"];
  if (bytes is! Uint8List) {
    return;
  }
  try {
    final result = ContentImporter.importBytes(bytes);
    _showImportDialog(
      true,
      "导入成功：${result.lessonCount} 篇 / ${result.sentenceCount} 句\n版本 ${result.contentVersion}\n\n返回首页会自动刷新内容。",
    );
  } catch (error) {
    _showImportDialog(false, "导入失败：$error");
  }
}

void _showImportDialog(bool ok, String message) {
  final context = appNavigatorKey.currentContext;
  if (context == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showImportDialog(ok, message));
    return;
  }
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(ok ? "导入成功" : "导入失败"),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("好")),
      ],
    ),
  );
}

class WenyanApp extends StatelessWidget {
  const WenyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "文言研习",
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kPaper,
        colorScheme: ColorScheme.fromSeed(seedColor: kAccent).copyWith(primary: kAccent, surface: kPaper),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPaper,
          foregroundColor: kInk,
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const HomeShell(),
    );
  }
}
