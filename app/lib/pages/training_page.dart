import "package:flutter/material.dart";

import "../data/training_repository.dart";
import "../models/training.dart";
import "../theme.dart";

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  late Future<List<TrainingCategory>> _future;

  @override
  void initState() {
    super.initState();
    _future = TrainingRepository.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("词义训练", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      body: FutureBuilder<List<TrainingCategory>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("训练题库加载失败：${snapshot.error}", style: const TextStyle(color: kMuted)));
          }
          final categories = snapshot.data ?? const <TrainingCategory>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Text("古今异义 · 一词多义 · 熟词生义", style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 6),
              const Text("专项突破", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kInk)),
              const SizedBox(height: 16),
              for (final category in categories)
                _categoryCard(context, category),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryCard(BuildContext context, TrainingCategory category) {
    final icon = switch (category.id) {
      "shuoci" => Icons.lightbulb_outline,
      "yici" => Icons.account_tree_outlined,
      _ => Icons.compare_arrows,
    };
    final color = switch (category.id) {
      "shuoci" => const Color(0xFFA97E4E),
      "yici" => const Color(0xFF3E6A98),
      _ => kGreen,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: kLine)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => TrainingCategoryPage(category: category)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
                      const SizedBox(height: 4),
                      Text(category.description, style: const TextStyle(fontSize: 12, color: kMuted)),
                      const SizedBox(height: 6),
                      Text("${category.items.length} 条", style: TextStyle(fontSize: 11, color: color)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: kMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrainingCategoryPage extends StatelessWidget {
  const TrainingCategoryPage({super.key, required this.category});

  final TrainingCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          TextButton.icon(
            onPressed: category.items.isEmpty
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => TrainingQuizPage(category: category)),
                    ),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text("自测"),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        itemCount: category.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = category.items[index];
          return Material(
            color: kCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kLine)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDetail(context, item),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kInk, fontFamily: "SimSun")),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.example, style: const TextStyle(fontSize: 13, color: kMuted), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.source, style: const TextStyle(fontSize: 11, color: kMuted)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, TrainingItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${item.word} · ${item.source}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 10),
            Text(item.example, style: const TextStyle(fontSize: 16, height: 1.7, fontFamily: "SimSun", color: kInk)),
            const SizedBox(height: 14),
            if (category.id == "shuoci") ...[
              Text("常见义：${item.familiar}", style: const TextStyle(fontSize: 14, height: 1.6, color: kMuted)),
              Text("文中义：${item.contextual}", style: const TextStyle(fontSize: 16, height: 1.6, color: kAccent)),
            ] else if (category.id == "gujin") ...[
              Text("古义：${item.ancient}", style: const TextStyle(fontSize: 16, height: 1.6, color: kAccent)),
              Text("今义：${item.modern}", style: const TextStyle(fontSize: 14, height: 1.6, color: kMuted)),
            ] else
              for (var i = 0; i < item.senses.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    "${i == item.answerIndex ? "▶ " : "· "}${item.senses[i].gloss}　${item.senses[i].example}",
                    style: TextStyle(fontSize: 14, height: 1.5, color: i == item.answerIndex ? kAccent : kInk),
                  ),
                ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text("知道了"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainingQuestion {
  final String stem;
  final String word;
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  _TrainingQuestion({
    required this.stem,
    required this.word,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });
}

class TrainingQuizPage extends StatefulWidget {
  const TrainingQuizPage({super.key, required this.category});

  final TrainingCategory category;

  @override
  State<TrainingQuizPage> createState() => _TrainingQuizPageState();
}

class _TrainingQuizPageState extends State<TrainingQuizPage> {
  late final List<_TrainingQuestion> _questions;
  int _index = 0;
  int _correct = 0;
  String? _selected;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_TrainingQuestion> _buildQuestions() {
    final items = List<TrainingItem>.of(widget.category.items)..shuffle();
    final limited = items.take(10).toList();
    final result = <_TrainingQuestion>[];
    for (final item in limited) {
      if (widget.category.id == "shuoci") {
        final options = <String>{item.contextual, item.familiar};
        for (final other in items) {
          if (options.length >= 4) break;
          if (other.contextual.isNotEmpty) options.add(other.contextual);
        }
        final list = options.toList()..shuffle();
        result.add(_TrainingQuestion(
          stem: item.example,
          word: item.word,
          question: "「${item.word}」在句中的意思是？",
          options: list,
          answer: item.contextual,
          explanation: "常见义：${item.familiar}；文中义：${item.contextual}",
        ));
      } else if (widget.category.id == "gujin") {
        final options = <String>{item.ancient, item.modern};
        for (final other in items) {
          if (options.length >= 4) break;
          if (other.ancient.isNotEmpty) options.add(other.ancient);
        }
        final list = options.toList()..shuffle();
        result.add(_TrainingQuestion(
          stem: item.example,
          word: item.word,
          question: "「${item.word}」的古义是？",
          options: list,
          answer: item.ancient,
          explanation: "古义：${item.ancient}；今义：${item.modern}",
        ));
      } else {
        final senses = item.senses;
        if (senses.isEmpty) continue;
        final answer = senses[item.answerIndex.clamp(0, senses.length - 1)].gloss;
        final options = <String>{answer};
        for (final sense in senses) {
          if (options.length >= 4) break;
          options.add(sense.gloss);
        }
        for (final other in items) {
          if (options.length >= 4) break;
          for (final sense in other.senses) {
            options.add(sense.gloss);
          }
        }
        final list = options.toList()..shuffle();
        result.add(_TrainingQuestion(
          stem: item.example,
          word: item.word,
          question: "「${item.word}」在句中的意思是？",
          options: list,
          answer: answer,
          explanation: senses.map((s) => "${s.gloss}：${s.example}").join("\n"),
        ));
      }
    }
    return result;
  }

  void _select(String option) {
    if (_selected != null) return;
    final q = _questions[_index];
    setState(() {
      _selected = option;
      if (option == q.answer) _correct += 1;
    });
  }

  void _next() {
    setState(() {
      if (_index + 1 >= _questions.length) {
        _finished = true;
      } else {
        _index += 1;
        _selected = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.category.title} · 自测", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      body: _finished ? _resultView() : _questionView(),
    );
  }

  Widget _questionView() {
    if (_questions.isEmpty) {
      return const Center(child: Text("题库为空", style: TextStyle(color: kMuted)));
    }
    final q = _questions[_index];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            Text("第 ${_index + 1} / ${_questions.length} 题", style: const TextStyle(fontSize: 13, color: kMuted)),
            const Spacer(),
            Text("答对 $_correct 题", style: const TextStyle(fontSize: 13, color: kGreen)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(value: (_index + 1) / _questions.length, minHeight: 6, backgroundColor: kLine, color: kAccent),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q.stem, style: const TextStyle(fontSize: 18, height: 1.8, fontFamily: "SimSun", color: kInk)),
              const SizedBox(height: 12),
              Text(q.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final option in q.options) ...[
          _optionButton(q, option),
          const SizedBox(height: 10),
        ],
        if (_selected != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFEEF3EE), borderRadius: BorderRadius.circular(14)),
            child: Text(q.explanation, style: const TextStyle(fontSize: 13, height: 1.6, color: kGreen)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _next, child: Text(_index + 1 >= _questions.length ? "查看结果" : "下一题")),
        ],
      ],
    );
  }

  Widget _optionButton(_TrainingQuestion q, String option) {
    var background = kCard;
    var border = kLine;
    var color = kInk;
    if (_selected != null) {
      if (option == q.answer) {
        background = const Color(0xFFEEF3EE);
        border = kGreen;
        color = kGreen;
      } else if (option == _selected) {
        background = const Color(0xFFF7E4DF);
        border = kAccent;
        color = kAccent;
      }
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _selected == null ? () => _select(option) : null,
        child: Align(alignment: Alignment.centerLeft, child: Text(option, style: TextStyle(fontSize: 15, color: color))),
      ),
    );
  }

  Widget _resultView() {
    final total = _questions.length;
    final accuracy = total == 0 ? 0 : (_correct * 100 / total).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 64, color: kAccent),
            const SizedBox(height: 12),
            Text("完成 $total 题", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 6),
            Text("答对 $_correct 题 · 正确率 $accuracy%", style: const TextStyle(fontSize: 14, color: kMuted)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text("返回")),
          ],
        ),
      ),
    );
  }
}
