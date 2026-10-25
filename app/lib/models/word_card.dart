class WordCard {
  final String id;
  final String surface;
  final String pos;
  final String gloss;
  final String lessonId;
  final String lessonTitle;
  final String sentenceId;
  final String sentenceText;
  final int createdAt;

  int state; // 0 新卡, 1 学习中, 2 复习中
  double ease;
  int intervalDays;
  int dueAt;
  int reps;
  int lapses;

  WordCard({
    required this.id,
    required this.surface,
    required this.pos,
    required this.gloss,
    required this.lessonId,
    required this.lessonTitle,
    required this.sentenceId,
    required this.sentenceText,
    required this.createdAt,
    required this.dueAt,
    this.state = 0,
    this.ease = 2.5,
    this.intervalDays = 0,
    this.reps = 0,
    this.lapses = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        "id": id,
        "surface": surface,
        "pos": pos,
        "gloss": gloss,
        "lessonId": lessonId,
        "lessonTitle": lessonTitle,
        "sentenceId": sentenceId,
        "sentenceText": sentenceText,
        "createdAt": createdAt,
        "dueAt": dueAt,
        "state": state,
        "ease": ease,
        "intervalDays": intervalDays,
        "reps": reps,
        "lapses": lapses,
      };

  factory WordCard.fromJson(Map<String, dynamic> json) => WordCard(
        id: json["id"] as String? ?? "",
        surface: json["surface"] as String? ?? "",
        pos: json["pos"] as String? ?? "",
        gloss: json["gloss"] as String? ?? "",
        lessonId: json["lessonId"] as String? ?? "",
        lessonTitle: json["lessonTitle"] as String? ?? "",
        sentenceId: json["sentenceId"] as String? ?? "",
        sentenceText: json["sentenceText"] as String? ?? "",
        createdAt: json["createdAt"] as int? ?? 0,
        dueAt: json["dueAt"] as int? ?? 0,
        state: json["state"] as int? ?? 0,
        ease: (json["ease"] as num?)?.toDouble() ?? 2.5,
        intervalDays: json["intervalDays"] as int? ?? 0,
        reps: json["reps"] as int? ?? 0,
        lapses: json["lapses"] as int? ?? 0,
      );
}
