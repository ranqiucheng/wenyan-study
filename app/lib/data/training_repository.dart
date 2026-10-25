import "dart:convert";

import "package:flutter/services.dart";

import "../models/training.dart";

class TrainingRepository {
  TrainingRepository._();

  static Future<List<TrainingCategory>> loadAll() async {
    final raw = await rootBundle.loadString("assets/training/word_training.json");
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data["categories"] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(TrainingCategory.fromJson)
        .toList();
  }
}
