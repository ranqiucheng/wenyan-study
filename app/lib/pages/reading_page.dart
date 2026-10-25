import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

import "../models/lesson.dart";
import "../services/card_store.dart";
import "../services/settings_store.dart";
import "../theme.dart";

class ReadingPage extends StatefulWidget {
  const ReadingPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  bool _showGloss = false;
  final Set<String> _revealed = <String>{};
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    SettingsStore.instance.load();
    SettingsStore.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    SettingsStore.instance.removeListener(_onSettingsChanged);
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  void _resetRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _resetRecognizers();
    final lesson = widget.lesson;
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: "字号与行距",
            icon: const Icon(Icons.text_fields),
            onPressed: _showReadingSettings,
          ),
          IconButton(
            tooltip: "收集本篇生词",
            icon: const Icon(Icons.playlist_add),
            onPressed: () {
              final added = CardStore.instance.addAllFromLesson(widget.lesson);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(added > 0 ? "已收集 $added 个生词，去「背」里复习" : "本篇生词已全部收集")),
              );
            },
          ),
          IconButton(
            tooltip: _showGloss ? "隐藏注释" : "注释常显",
            icon: Icon(_showGloss ? Icons.visibility_off_outlined : Icons.subtitles_outlined),
            onPressed: () => setState(() => _showGloss = !_showGloss),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
        children: [
          Text(lesson.title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, fontFamily: "SimSun", color: kInk)),
          const SizedBox(height: 6),
          Text("${lesson.author} · ${lesson.source} · ${lesson.volume}", style: const TextStyle(fontSize: 13, color: kMuted)),
          if (lesson.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(lesson.summary, style: const TextStyle(fontSize: 13, height: 1.6, color: kMuted)),
          ],
          const SizedBox(height: 14),
          const Divider(color: kLine, height: 1),
          const SizedBox(height: 20),
          for (final sentence in lesson.sentences) _buildSentence(context, sentence),
          const SizedBox(height: 4),
          const Text("点字词看注释 · 长按句子看翻译", style: TextStyle(fontSize: 12, color: kMuted)),
        ],
      ),
    );
  }

  Widget _buildSentence(BuildContext context, Sentence sentence) {
    final revealed = _revealed.contains(sentence.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => setState(() => _revealed.add(sentence.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: SettingsStore.instance.fontSize,
                  height: SettingsStore.instance.lineHeight,
                  color: kInk,
                  fontFamily: "SimSun",
                ),
                children: _buildSpans(sentence),
              ),
            ),
            if (revealed) ...[
              const SizedBox(height: 8),
              Text(sentence.translation, style: const TextStyle(fontSize: 14, height: 1.6, color: kMuted)),
            ],
          ],
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
      final recognizer = TapGestureRecognizer()..onTap = () => _showWord(token, sentence);
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
      if (_showGloss && token.gloss.isNotEmpty) {
        spans.add(TextSpan(
          text: "〔${token.gloss}〕",
          style: const TextStyle(fontSize: 14, height: 1.4, color: kMuted, decoration: TextDecoration.none),
        ));
      }
      cursor = index + token.surface.length;
    }
    if (cursor < sentence.text.length) {
      spans.add(TextSpan(text: sentence.text.substring(cursor)));
    }
    return spans;
  }

  void _showReadingSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("阅读设置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 16),
              Text("字号  ${SettingsStore.instance.fontSize.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, color: kMuted)),
              Slider(
                value: SettingsStore.instance.fontSize,
                min: 18,
                max: 30,
                divisions: 12,
                activeColor: kAccent,
                onChanged: (value) {
                  SettingsStore.instance.setFontSize(value);
                  setSheetState(() {});
                },
              ),
              Text("行距  ${SettingsStore.instance.lineHeight.toStringAsFixed(1)}", style: const TextStyle(fontSize: 13, color: kMuted)),
              Slider(
                value: SettingsStore.instance.lineHeight,
                min: 1.4,
                max: 2.4,
                divisions: 10,
                activeColor: kAccent,
                onChanged: (value) {
                  SettingsStore.instance.setLineHeight(value);
                  setSheetState(() {});
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text("完成"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWord(Token token, Sentence sentence) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(color: kLine, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(token.surface, style: const TextStyle(fontSize: 40, fontFamily: "SimSun", color: kInk)),
                  const SizedBox(width: 12),
                  if (token.pos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: kPale, borderRadius: BorderRadius.circular(20)),
                      child: Text(token.pos, style: const TextStyle(fontSize: 12, color: kAccent)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              const Text("释义", style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 4),
              Text(token.gloss, style: const TextStyle(fontSize: 20, height: 1.5, color: kInk)),
              const SizedBox(height: 18),
              const Text("例句", style: TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 4),
              Text(sentence.text, style: const TextStyle(fontSize: 16, height: 1.6, fontFamily: "SimSun", color: kInk)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final index = sentence.tokens.indexOf(token);
                    final added = CardStore.instance.addFromToken(
                      lesson: widget.lesson,
                      sentence: sentence,
                      token: token,
                      index: index,
                    );
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(added ? "已加入复习卡，去「背」里复习" : "这个词已在复习卡中")),
                    );
                  },
                  child: const Text("加入复习卡"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
