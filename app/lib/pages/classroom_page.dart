import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../models/lesson.dart";
import "../theme.dart";

class ClassroomPage extends StatefulWidget {
  const ClassroomPage({super.key, required this.lesson, this.previewIndex = 0});

  final Lesson lesson;
  final int previewIndex;

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> {
  late int _index;
  bool _showGloss = false;
  bool _showTranslation = false;
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    final total = widget.lesson.sentences.length;
    _index = total == 0 ? 0 : widget.previewIndex.clamp(0, total - 1);
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _go(int delta) {
    final total = widget.lesson.sentences.length;
    final next = (_index + delta).clamp(0, total - 1);
    if (next != _index) {
      setState(() {
        _index = next;
        _showGloss = false;
        _showTranslation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final total = lesson.sentences.length;
    final sentence = lesson.sentences[_index];
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    return Scaffold(
      backgroundColor: kPaper,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.pageDown) {
            _go(1);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.pageUp) {
            _go(-1);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.space) {
            setState(() => _showGloss = !_showGloss);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.keyT) {
            setState(() => _showTranslation = !_showTranslation);
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(lesson.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kInk, fontFamily: "SimSun")),
                    const SizedBox(width: 10),
                    Text(lesson.author, style: const TextStyle(fontSize: 14, color: kMuted)),
                    const Spacer(),
                    Text("第 ${_index + 1} / $total 句", style: const TextStyle(fontSize: 14, color: kMuted)),
                    const SizedBox(width: 16),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("退出 (Esc)")),
                  ],
                ),
                const Divider(color: kLine),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (lesson.sentences.length > 1)
                            Text(
                              _index > 0 ? "上一句：${lesson.sentences[_index - 1].text}" : "",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, height: 1.8, color: Color(0xFFB8B2A6), fontFamily: "SimSun"),
                            ),
                          const SizedBox(height: 18),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(fontSize: 54, height: 1.8, color: kInk, fontFamily: "SimSun"),
                              children: _buildSpans(sentence),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          if (_showTranslation)
                            Text(sentence.translation, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, height: 1.7, color: kMuted)),
                          if (_showGloss && sentence.tokens.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final token in sentence.tokens)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(color: kPale, borderRadius: BorderRadius.circular(20)),
                                    child: Text("${token.surface}：${token.gloss}", style: const TextStyle(fontSize: 18, color: kInk)),
                                  ),
                              ],
                            ),
                          ],
                          if (_index < lesson.sentences.length - 1) ...[
                            const SizedBox(height: 18),
                            Text(
                              "下一句：${lesson.sentences[_index + 1].text}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18, height: 1.8, color: Color(0xFFB8B2A6), fontFamily: "SimSun"),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(color: kLine),
                Row(
                  children: [
                    IconButton(onPressed: _index == 0 ? null : () => _go(-1), icon: const Icon(Icons.chevron_left, size: 32)),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _index >= total - 1 ? null : () => _go(1), icon: const Icon(Icons.chevron_right, size: 32)),
                    const Spacer(),
                    const Text(
                      "← → 翻句    空格 注释    T 译文    Esc 退出",
                      style: TextStyle(fontSize: 13, color: kMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildSpans(Sentence sentence) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final token in sentence.tokens) {
      final index = sentence.text.indexOf(token.surface, cursor);
      if (index < 0) {
        continue;
      }
      if (index > cursor) {
        spans.add(TextSpan(text: sentence.text.substring(cursor, index)));
      }
      final recognizer = TapGestureRecognizer()..onTap = () => _showWord(token);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: token.surface,
        recognizer: recognizer,
        style: const TextStyle(
          color: kAccent,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: Color(0x99C4553B),
        ),
      ));
      cursor = index + token.surface.length;
    }
    if (cursor < sentence.text.length) {
      spans.add(TextSpan(text: sentence.text.substring(cursor)));
    }
    return spans;
  }

  void _showWord(Token token) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCard,
        title: Text(token.surface, style: const TextStyle(fontSize: 36, fontFamily: "SimSun", color: kInk)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (token.pos.isNotEmpty) Text(token.pos, style: const TextStyle(fontSize: 13, color: kAccent)),
            const SizedBox(height: 8),
            Text(token.gloss, style: const TextStyle(fontSize: 22, height: 1.5, color: kInk)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("知道了")),
        ],
      ),
    );
  }
}
