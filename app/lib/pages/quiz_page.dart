import "package:flutter/material.dart";

import "../data/content_repository.dart";
import "../models/lesson.dart";
import "../services/quiz_builder.dart";
import "../services/imported_content_store.dart";
import "../services/stats_store.dart";
import "../services/wrong_store.dart";
import "../theme.dart";

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, this.previewLessons, this.wrongOnly = false});

  /// 仅用于界面预览/测试；为空时从 assets 加载。
  final List<Lesson>? previewLessons;

  /// 仅重练错题本中的题。
  final bool wrongOnly;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Lesson> _lessons = const <Lesson>[];
  List<QuizQuestion> _questions = const <QuizQuestion>[];
  final List<QuizQuestion> _wrong = <QuizQuestion>[];
  int _index = 0;
  int _correct = 0;
  String? _selected;
  bool _started = false;
  bool _finished = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final preview = widget.previewLessons;
    if (preview != null) {
      _lessons = preview;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final lessons = await ContentRepository.loadAll();
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<QuizQuestion> _customQuestions() {
    final imported = ImportedContentStore.instance;
    imported.load();
    final titles = {for (final lesson in _lessons) lesson.id: lesson.title};
    final result = <QuizQuestion>[];
    for (final question in imported.allQuestions) {
      if (question.options.length < 2) {
        continue;
      }
      result.add(QuizQuestion(
        surface: question.surface,
        gloss: question.answer,
        sentenceText: question.sentence,
        lessonTitle: titles[question.lessonId] ?? "课内",
        options: question.options,
        analysis: question.analysis,
      ));
    }
    return result;
  }

  void _start() {
    List<QuizQuestion> source;
    if (widget.wrongOnly) {
      source = buildQuizFromWrongs(WrongStore.instance.items, _lessons, count: 10);
    } else {
      final custom = _customQuestions();
      final auto = buildQuiz(_lessons, count: 10);
      source = <QuizQuestion>[...custom, ...auto];
      source.shuffle();
      if (source.length > 10) {
        source = source.take(10).toList();
      }
    }
    setState(() {
      _questions = source;
      _index = 0;
      _correct = 0;
      _wrong.clear();
      _selected = null;
      _started = true;
      _finished = false;
    });
  }

  void _select(String option) {
    if (_selected != null) {
      return;
    }
    final q = _questions[_index];
    setState(() {
      _selected = option;
      if (option == q.gloss) {
        _correct += 1;
      } else {
        _wrong.add(q);
        WrongStore.instance.add(WrongWord(
          surface: q.surface,
          gloss: q.gloss,
          lessonTitle: q.lessonTitle,
          sentenceText: q.sentenceText,
          wrongAt: DateTime.now().millisecondsSinceEpoch,
        ));
      }
    });
  }

  void _next() {
    setState(() {
      if (_index + 1 >= _questions.length) {
        _finished = true;
        StatsStore.instance.recordQuiz(total: _questions.length, correctAnswers: _correct);
      } else {
        _index += 1;
        _selected = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("刷题", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_started
              ? _introView()
              : _finished
                  ? _resultView()
                  : _questionView(),
    );
  }

  Widget _introView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note, size: 64, color: kAccent),
            const SizedBox(height: 16),
            Text(widget.wrongOnly ? "错题重练" : "词义选择", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 8),
            Text(
              widget.wrongOnly
                  ? "从错题本抽 ${WrongStore.instance.items.length} 道题重练"
                  : "从 ${_lessons.length} 篇课文中抽 10 道题，检验字词掌握",
              style: const TextStyle(fontSize: 14, color: kMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _lessons.isEmpty || (widget.wrongOnly && WrongStore.instance.items.isEmpty) ? null : _start,
              child: const Text("开始练习"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionView() {
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
          child: LinearProgressIndicator(
            value: (_index + 1) / _questions.length,
            minHeight: 6,
            backgroundColor: kLine,
            color: kAccent,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: kLine)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("《${q.lessonTitle}》", style: const TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 10),
              _sentenceRich(q),
              const SizedBox(height: 18),
              Text("「${q.surface}」在句中的意思是？", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final option in q.options) ...[
          _optionButton(q, option),
          const SizedBox(height: 10),
        ],
        if (_selected != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: (Color(0xFFEEF3EE)), borderRadius: BorderRadius.circular(16)),
            child: Text(
              q.analysis.isNotEmpty ? "解析：${q.analysis}" : "正确释义：${q.gloss}",
              style: const TextStyle(fontSize: 14, height: 1.5, color: kGreen),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _next, child: Text(_index + 1 >= _questions.length ? "查看结果" : "下一题")),
        ],
      ],
    );
  }

  Widget _sentenceRich(QuizQuestion q) {
    final text = q.sentenceText;
    final index = text.indexOf(q.surface);
    if (index < 0) {
      return Text(text, style: const TextStyle(fontSize: 20, height: 1.8, fontFamily: "SimSun", color: kInk));
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 20, height: 1.8, fontFamily: "SimSun", color: kInk),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: q.surface,
            style: const TextStyle(color: kAccent, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
          ),
          TextSpan(text: text.substring(index + q.surface.length)),
        ],
      ),
    );
  }

  Widget _optionButton(QuizQuestion q, String option) {
    var background = kCard;
    var border = kLine;
    var textColor = kInk;
    if (_selected != null) {
      if (option == q.gloss) {
        background = const Color(0xFFEEF3EE);
        border = kGreen;
        textColor = kGreen;
      } else if (option == _selected) {
        background = const Color(0xFFF7E4DF);
        border = kAccent;
        textColor = kAccent;
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
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(option, style: TextStyle(fontSize: 15, color: textColor)),
        ),
      ),
    );
  }

  Widget _resultView() {
    final total = _questions.length;
    final accuracy = total == 0 ? 0 : (_correct * 100 / total).round();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.emoji_events_outlined, size: 72, color: kAccent),
        const SizedBox(height: 12),
        Text("完成 $total 题", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kInk)),
        const SizedBox(height: 6),
        Text("答对 $_correct 题 · 正确率 $accuracy%", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: kMuted)),
        const SizedBox(height: 24),
        if (_wrong.isNotEmpty) ...[
          const Text("错题", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 10),
          for (final q in _wrong)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${q.surface}：${q.gloss}", style: const TextStyle(fontSize: 15, color: kInk)),
                  const SizedBox(height: 4),
                  Text("《${q.lessonTitle}》 ${q.sentenceText}", style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
        ] else
          const Text("全部答对，太棒了", textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: kGreen)),
        const SizedBox(height: 20),
        FilledButton(onPressed: _start, child: const Text("再来一组")),
      ],
    );
  }
}
