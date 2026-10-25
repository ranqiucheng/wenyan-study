class TrainingSense {
  final String gloss;
  final String example;

  const TrainingSense({required this.gloss, required this.example});

  factory TrainingSense.fromJson(Map<String, dynamic> json) => TrainingSense(
        gloss: json["gloss"] as String? ?? "",
        example: json["example"] as String? ?? "",
      );
}

class TrainingItem {
  final String id;
  final String word;
  final String example;
  final String source;
  final String familiar;
  final String contextual;
  final String ancient;
  final String modern;
  final List<TrainingSense> senses;
  final int answerIndex;

  const TrainingItem({
    required this.id,
    required this.word,
    required this.example,
    required this.source,
    this.familiar = "",
    this.contextual = "",
    this.ancient = "",
    this.modern = "",
    this.senses = const <TrainingSense>[],
    this.answerIndex = 0,
  });

  factory TrainingItem.fromJson(Map<String, dynamic> json) => TrainingItem(
        id: json["id"] as String? ?? "",
        word: json["word"] as String? ?? "",
        example: json["example"] as String? ?? "",
        source: json["source"] as String? ?? "",
        familiar: json["familiar"] as String? ?? "",
        contextual: json["contextual"] as String? ?? "",
        ancient: json["ancient"] as String? ?? "",
        modern: json["modern"] as String? ?? "",
        senses: (json["senses"] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TrainingSense.fromJson)
            .toList(),
        answerIndex: json["answerIndex"] as int? ?? 0,
      );
}

class TrainingCategory {
  final String id;
  final String title;
  final String description;
  final List<TrainingItem> items;

  const TrainingCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.items,
  });

  factory TrainingCategory.fromJson(Map<String, dynamic> json) => TrainingCategory(
        id: json["id"] as String? ?? "",
        title: json["title"] as String? ?? "",
        description: json["description"] as String? ?? "",
        items: (json["items"] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TrainingItem.fromJson)
            .toList(),
      );
}
