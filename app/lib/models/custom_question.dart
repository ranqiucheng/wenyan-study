class CustomQuestion {
  final String id;
  final String lessonId;
  final String sentence;
  final String surface;
  final String answer;
  final List<String> options;
  final String analysis;

  const CustomQuestion({
    required this.id,
    required this.lessonId,
    required this.sentence,
    required this.surface,
    required this.answer,
    required this.options,
    this.analysis = "",
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        "lessonId": lessonId,
        "sentence": sentence,
        "surface": surface,
        "answer": answer,
        "options": options,
        "analysis": analysis,
      };

  factory CustomQuestion.fromJson(Map<String, dynamic> json) => CustomQuestion(
        id: json["id"] as String? ?? "",
        lessonId: json["lessonId"] as String? ?? "",
        sentence: json["sentence"] as String? ?? "",
        surface: json["surface"] as String? ?? "",
        answer: json["answer"] as String? ?? "",
        options: (json["options"] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        analysis: json["analysis"] as String? ?? "",
      );
}
