import "package:flutter/foundation.dart";

import "app_storage.dart";

class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  double fontSize = 24;
  double lineHeight = 1.9;
  bool _loaded = false;

  void load() {
    if (_loaded) {
      return;
    }
    _loaded = true;
    final data = AppStorage.readJson("settings.json");
    fontSize = (data["fontSize"] as num?)?.toDouble() ?? 24;
    lineHeight = (data["lineHeight"] as num?)?.toDouble() ?? 1.9;
    notifyListeners();
  }

  void setFontSize(double value) {
    fontSize = value.clamp(18, 30).toDouble();
    _save();
    notifyListeners();
  }

  void setLineHeight(double value) {
    lineHeight = value.clamp(1.4, 2.4).toDouble();
    _save();
    notifyListeners();
  }

  void _save() {
    AppStorage.writeJson("settings.json", <String, dynamic>{
      "fontSize": fontSize,
      "lineHeight": lineHeight,
    });
  }
}
