import "package:flutter/material.dart";

import "../data/content_repository.dart";
import "../models/lesson.dart";
import "../models/word_card.dart";
import "../services/card_store.dart";
import "../theme.dart";

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, this.previewCards});

  /// 仅用于界面预览/测试；为空时读取真实复习卡。
  final List<WordCard>? previewCards;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  List<Lesson> _lessons = const <Lesson>[];
  List<WordCard> _queue = const <WordCard>[];
  int _index = 0;
  bool _flipped = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    CardStore.instance.load();
    _refresh();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    try {
      final lessons = await ContentRepository.loadAll();
      if (mounted) {
        setState(() => _lessons = lessons);
      }
    } catch (_) {}
  }

  void _refresh() {
    final preview = widget.previewCards;
    _queue = preview == null ? CardStore.instance.dueCards() : List<WordCard>.of(preview);
    _index = 0;
    _flipped = false;
    _finished = _queue.isEmpty;
  }

  void _collectAll() {
    var added = 0;
    for (final lesson in _lessons) {
      added += CardStore.instance.addAllFromLesson(lesson);
    }
    setState(_refresh);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(added > 0 ? "已收集 $added 张复习卡" : "所有生词都已收集")),
    );
  }

  void _rate(int rating) {
    if (_queue.isEmpty || _index >= _queue.length) {
      return;
    }
    CardStore.instance.rate(_queue[_index], rating);
    setState(() {
      _index += 1;
      _flipped = false;
      if (_index >= _queue.length) {
        _finished = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("字词卡", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: "刷新",
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_refresh),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: CardStore.instance,
        builder: (context, _) {
          final preview = widget.previewCards;
          final noCards = preview == null ? CardStore.instance.total == 0 : preview.isEmpty;
          if (noCards) {
            return _emptyView();
          }
          if (_finished || _queue.isEmpty) {
            return _doneView();
          }
          return _cardView(_queue[_index]);
        },
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style_outlined, size: 64, color: kMuted),
            const SizedBox(height: 16),
            const Text("还没有复习卡", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 8),
            const Text("去阅读页点字词加入，或一键收集全部生词", style: TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _lessons.isEmpty ? null : _collectAll,
              icon: const Icon(Icons.playlist_add),
              label: const Text("一键收集全部生词"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: kGreen),
            const SizedBox(height: 16),
            const Text("今天的复习完成了", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 8),
            Text("共有 ${CardStore.instance.total} 张卡，待复习 ${CardStore.instance.dueCount} 张", style: const TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => setState(_refresh),
              child: const Text("刷新复习队列"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardView(WordCard card) {
    final total = _queue.length;
    final blanked = card.sentenceText.replaceFirst(card.surface, "＿＿＿");
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Text("第 ${_index + 1} / $total 张", style: const TextStyle(fontSize: 13, color: kMuted)),
              const Spacer(),
              Text("本组剩余 ${total - _index} 张", style: const TextStyle(fontSize: 13, color: kMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (_index + 1) / total,
              minHeight: 6,
              backgroundColor: kLine,
              color: kAccent,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kLine),
                ),
                child: _flipped ? _backFace(card) : _frontFace(card, blanked),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_flipped) _ratingBar() else const Text("点击卡片查看释义", style: TextStyle(fontSize: 13, color: kMuted)),
        ],
      ),
    );
  }

  Widget _frontFace(WordCard card, String blanked) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("正面 · 填一填", style: TextStyle(fontSize: 12, color: kMuted)),
        const SizedBox(height: 24),
        Text(blanked, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, height: 1.9, fontFamily: "SimSun", color: kInk)),
        const SizedBox(height: 16),
        Text("《${card.lessonTitle}》", style: const TextStyle(fontSize: 13, color: kMuted)),
      ],
    );
  }

  Widget _backFace(WordCard card) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("背面 · 答案", style: TextStyle(fontSize: 12, color: kMuted)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(card.surface, style: const TextStyle(fontSize: 44, fontFamily: "SimSun", color: kInk)),
            const SizedBox(width: 10),
            if (card.pos.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kPale, borderRadius: BorderRadius.circular(20)),
                child: Text(card.pos, style: const TextStyle(fontSize: 12, color: kAccent)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(card.gloss, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, height: 1.5, color: kInk)),
        const SizedBox(height: 18),
        const Text("例句", style: TextStyle(fontSize: 12, color: kMuted)),
        const SizedBox(height: 6),
        Text(card.sentenceText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.7, fontFamily: "SimSun", color: kInk)),
        const SizedBox(height: 10),
        Text("《${card.lessonTitle}》", style: const TextStyle(fontSize: 12, color: kMuted)),
      ],
    );
  }

  Widget _ratingBar() {
    const labels = ["忘记", "模糊", "记得", "简单"];
    const colors = [kAccent, Color(0xFFA97E4E), kGreen, Color(0xFF3E6A98)];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colors[i], minimumSize: const Size.fromHeight(52)),
                onPressed: () => _rate(i),
                child: Text(labels[i], style: const TextStyle(fontSize: 15)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
