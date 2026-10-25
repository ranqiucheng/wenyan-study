import "dart:typed_data";

import "package:flutter/services.dart";

class PickedContentPack {
  final String name;
  final Uint8List bytes;

  PickedContentPack({required this.name, required this.bytes});
}

class AndroidFilePicker {
  AndroidFilePicker._();

  static const MethodChannel _channel = MethodChannel("wenyan/file_picker");

  static Future<PickedContentPack?> pickContentPack() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>("pickContentPack");
    if (result == null) {
      return null;
    }
    final bytes = result["bytes"];
    if (bytes is! Uint8List) {
      return null;
    }
    return PickedContentPack(
      name: result["name"] as String? ?? "content.wyc",
      bytes: bytes,
    );
  }
}
