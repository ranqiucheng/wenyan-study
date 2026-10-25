class Token {
  final String surface;
  final String pos;
  final String gloss;

  const Token({required this.surface, this.pos = "", this.gloss = ""});

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        surface: json["surface"] as String? ?? "",
        pos: json["pos"] as String? ?? "",
        gloss: json["gloss"] as String? ?? "",
      );
}

class Sentence {
  final String id;
  final int order;
  final String text;
  final String translation;
  final List<Token> tokens;

  const Sentence({
    required this.id,
    required this.order,
    required this.text,
    required this.translation,
    required this.tokens,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) => Sentence(
        id: json["id"] as String? ?? "",
        order: json["order"] as int? ?? 0,
        text: json["text"] as String? ?? "",
        translation: json["translation"] as String? ?? "",
        tokens: (json["tokens"] as List<dynamic>? ?? [])
            .map((e) => Token.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Lesson {
  final String id;
  final String title;
  final String author;
  final String source;
  final String volume;
  final List<String> tags;
  final bool reviewed;
  final String summary;
  final List<Sentence> sentences;

  const Lesson({
    required this.id,
    required this.title,
    required this.author,
    required this.source,
    required this.volume,
    required this.tags,
    required this.reviewed,
    required this.summary,
    required this.sentences,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json["id"] as String? ?? "",
        title: json["title"] as String? ?? "",
        author: json["author"] as String? ?? "",
        source: json["source"] as String? ?? "",
        volume: json["volume"] as String? ?? "",
        tags: (json["tags"] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        reviewed: json["reviewed"] as bool? ?? false,
        summary: json["summary"] as String? ?? "",
        sentences: (json["sentences"] as List<dynamic>? ?? [])
            .map((e) => Sentence.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order)),
      );
}
