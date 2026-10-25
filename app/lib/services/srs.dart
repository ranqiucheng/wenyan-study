import "../models/word_card.dart";

/// 简化的间隔重复：rating 0=忘记 1=模糊 2=记得 3=简单。
class Srs {
  Srs._();

  static void rate(WordCard card, int rating) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (rating <= 0) {
      card.lapses += 1;
      card.ease = (card.ease - 0.2).clamp(1.3, 2.8).toDouble();
      card.intervalDays = 0;
      card.dueAt = now + 10 * 60 * 1000; // 10 分钟后
      card.state = 1;
      return;
    }
    if (card.reps == 0) {
      card.intervalDays = rating == 1 ? 1 : (rating == 2 ? 2 : 4);
    } else {
      final factor = rating == 1 ? 1.2 : (rating == 2 ? card.ease : card.ease * 1.3);
      card.intervalDays = (card.intervalDays * factor).round().clamp(1, 365);
    }
    final delta = rating == 1 ? -0.15 : (rating == 2 ? 0.0 : 0.15);
    card.ease = (card.ease + delta).clamp(1.3, 2.8).toDouble();
    card.reps += 1;
    card.state = 2;
    card.dueAt = now + card.intervalDays * 86400000;
  }
}
