import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../models/custom_question.dart";
import "../models/lesson.dart";
import "../services/teacher_store.dart";
import "../theme.dart";
import "classroom_page.dart";
import "reading_page.dart";

class TeacherEditorPage extends StatelessWidget {
  const TeacherEditorPage({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TeacherStore.instance,
      builder: (context, _) {
        final applied = TeacherStore.instance.apply(lesson);
        final reviewed = TeacherStore.instance.reviewedFor(lesson.id) || lesson.reviewed;
        return Scaffold(
          appBar: AppBar(
            title: Text("${lesson.title} · 编辑", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            actions: [
              Row(
                children: [
                  Text(reviewed ? "已校对" : "待校对", style: TextStyle(fontSize: 12, color: reviewed ? kGreen : kAccent)),
                  Switch(
                    value: reviewed,
                    activeColor: kGreen,
                    onChanged: (value) => TeacherStore.instance.setReviewed(lesson.id, value),
                  ),
                ],
              ),
              IconButton(
                tooltip: "课堂模式",
                icon: const Icon(Icons.co_present_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ClassroomPage(lesson: applied)),
                ),
              ),
              IconButton(
                tooltip: "预览学生端",
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ReadingPage(lesson: applied)),
                ),
              ),
            ],
          ),
          body: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              final key = event.logicalKey;
              if (HardwareKeyboard.instance.isControlPressed) {
                if (key == LogicalKeyboardKey.keyP) {
                  _preview(context, applied);
                  return KeyEventResult.handled;
                }
                if (key == LogicalKeyboardKey.keyK) {
                  _classroom(context, applied);
                  return KeyEventResult.handled;
                }
                if (key == LogicalKeyboardKey.enter) {
                  TeacherStore.instance.setReviewed(lesson.id, !reviewed);
                  return KeyEventResult.handled;
                }
              }
              if (key == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Text("${lesson.author} · ${lesson.source} · ${lesson.volume}", style: const TextStyle(fontSize: 12, color: kMuted)),
              if (lesson.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(lesson.summary, style: const TextStyle(fontSize: 13, height: 1.6, color: kMuted)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text("点词条改词性/释义；新增词条会自动进入刷题题库。快捷键：Ctrl+Enter 校对，Ctrl+P 预览，Ctrl+K 课堂。", style: TextStyle(fontSize: 12, height: 1.5, color: kMuted)),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _addSentence(context, applied),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("新增句子"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < applied.sentences.length; i++) _sentenceCard(context, applied, i),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _sentenceCard(BuildContext context, Lesson applied, int sentenceIndex) {
    final sentence = applied.sentences[sentenceIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("第 ${sentence.order} 句", style: const TextStyle(fontSize: 11, color: kMuted)),
              const Spacer(),
              IconButton(
                tooltip: "新增词条",
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.playlist_add, size: 18, color: kMuted),
                onPressed: () => _addToken(context, applied, sentence),
              ),
              IconButton(
                tooltip: "出题",
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.quiz_outlined, size: 18, color: kMuted),
                onPressed: () => _addQuestion(context, applied, sentence),
              ),
              IconButton(
                tooltip: "删除本句",
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18, color: kMuted),
                onPressed: () => _deleteSentence(context, applied, sentence),
              ),
              IconButton(
                tooltip: "编辑译文",
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.translate, size: 18, color: kMuted),
                onPressed: () => _editTranslation(context, sentence),
              ),
            ],
          ),
          Text(sentence.text, style: const TextStyle(fontSize: 20, height: 1.8, fontFamily: "SimSun", color: kInk)),
          const SizedBox(height: 6),
          Text("译文：${sentence.translation}", style: const TextStyle(fontSize: 13, height: 1.6, color: kMuted)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < sentence.tokens.length; i++)
                _tokenChip(context, applied, sentence, i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tokenChip(BuildContext context, Lesson applied, Sentence sentence, int index) {
    final token = sentence.tokens[index];
    final edited = TeacherStore.instance.hasTokenEdit(applied.id, sentence.id, index);
    return ActionChip(
      backgroundColor: edited ? kPale : kCard,
      side: BorderSide(color: edited ? kAccent : kLine),
      label: Text(
        "${token.surface} · ${token.gloss}",
        style: TextStyle(fontSize: 12, color: edited ? kAccent : kInk),
      ),
      onPressed: () => _editToken(context, applied, sentence, index, token),
    );
  }

  Future<void> _addQuestion(BuildContext context, Lesson applied, Sentence sentence) async {
    final surfaceController = TextEditingController(text: sentence.tokens.isNotEmpty ? sentence.tokens.first.surface : "");
    final answerController = TextEditingController(text: sentence.tokens.isNotEmpty ? sentence.tokens.first.gloss : "");
    final d1 = TextEditingController();
    final d2 = TextEditingController();
    final d3 = TextEditingController();
    final analysisController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("新增题目（词义选择）"),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(sentence.text, style: const TextStyle(fontSize: 15, fontFamily: "SimSun")),
                const SizedBox(height: 12),
                TextField(controller: surfaceController, decoration: const InputDecoration(labelText: "加点词")),
                const SizedBox(height: 10),
                TextField(controller: answerController, decoration: const InputDecoration(labelText: "正确释义")),
                const SizedBox(height: 10),
                TextField(controller: d1, decoration: const InputDecoration(labelText: "干扰项 1")),
                const SizedBox(height: 10),
                TextField(controller: d2, decoration: const InputDecoration(labelText: "干扰项 2")),
                const SizedBox(height: 10),
                TextField(controller: d3, decoration: const InputDecoration(labelText: "干扰项 3")),
                const SizedBox(height: 10),
                TextField(controller: analysisController, maxLines: 2, decoration: const InputDecoration(labelText: "解析（可选）")),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("取消")),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text("保存")),
        ],
      ),
    );
    final answer = answerController.text.trim();
    final surface = surfaceController.text.trim();
    final options = <String>[answer, d1.text.trim(), d2.text.trim(), d3.text.trim()]
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (saved == true && answer.isNotEmpty && options.length >= 2) {
      TeacherStore.instance.addQuestion(CustomQuestion(
        id: "q_${DateTime.now().millisecondsSinceEpoch}",
        lessonId: applied.id,
        sentence: sentence.text,
        surface: surface,
        answer: answer,
        options: options,
        analysis: analysisController.text.trim(),
      ));
    }
    surfaceController.dispose();
    answerController.dispose();
    d1.dispose();
    d2.dispose();
    d3.dispose();
    analysisController.dispose();
  }

  Future<void> _deleteSentence(BuildContext context, Lesson applied, Sentence sentence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("删除本句？"),
        content: Text(sentence.text),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("取消")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kAccent),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text("删除"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      TeacherStore.instance.deleteSentence(applied, sentence.id);
    }
  }

  void _preview(BuildContext context, Lesson applied) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReadingPage(lesson: applied)));
  }

  void _classroom(BuildContext context, Lesson applied) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ClassroomPage(lesson: applied)));
  }

  Future<void> _addSentence(BuildContext context, Lesson applied) async {
    final textController = TextEditingController();
    final translationController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("新增句子"),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: textController, maxLines: 2, decoration: const InputDecoration(labelText: "原文")),
              const SizedBox(height: 12),
              TextField(controller: translationController, maxLines: 2, decoration: const InputDecoration(labelText: "译文")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("取消")),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text("添加")),
        ],
      ),
    );
    final text = textController.text.trim();
    final translation = translationController.text.trim();
    textController.dispose();
    translationController.dispose();
    if (result == true && text.isNotEmpty) {
      TeacherStore.instance.addSentence(applied, text: text, translation: translation);
    }
  }

  Future<void> _addToken(BuildContext context, Lesson applied, Sentence sentence) async {
    final surfaceController = TextEditingController();
    final posController = TextEditingController(text: "名词");
    final glossController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("新增词条"),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: surfaceController, decoration: const InputDecoration(labelText: "词（必须是本句中的连续文字）")),
              const SizedBox(height: 10),
              TextField(controller: posController, decoration: const InputDecoration(labelText: "词性")),
              const SizedBox(height: 10),
              TextField(controller: glossController, decoration: const InputDecoration(labelText: "释义")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("取消")),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text("添加")),
        ],
      ),
    );
    final surface = surfaceController.text.trim();
    final pos = posController.text.trim();
    final gloss = glossController.text.trim();
    surfaceController.dispose();
    posController.dispose();
    glossController.dispose();
    if (result != true || surface.isEmpty || gloss.isEmpty) {
      return;
    }
    if (!sentence.text.contains(surface)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("词必须出现在本句原文中")));
      }
      return;
    }
    TeacherStore.instance.addToken(applied, sentence.id, surface: surface, pos: pos, gloss: gloss);
  }

  Future<void> _editToken(BuildContext context, Lesson applied, Sentence sentence, int index, Token token) async {
    final posController = TextEditingController(text: token.pos);
    final glossController = TextEditingController(text: token.gloss);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("编辑「${token.surface}」"),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: posController, decoration: const InputDecoration(labelText: "词性")),
              const SizedBox(height: 12),
              TextField(controller: glossController, decoration: const InputDecoration(labelText: "释义")),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              TeacherStore.instance.deleteToken(applied, sentence.id, index);
            },
            child: const Text("删除词条", style: TextStyle(color: kAccent)),
          ),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("取消")),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(<String, String>{
              "pos": posController.text.trim(),
              "gloss": glossController.text.trim(),
            }),
            child: const Text("保存"),
          ),
        ],
      ),
    );
    posController.dispose();
    glossController.dispose();
    if (result == null) {
      return;
    }
    TeacherStore.instance.setToken(
      lessonId: applied.id,
      sentenceId: sentence.id,
      index: index,
      pos: result["pos"] ?? "",
      gloss: result["gloss"] ?? "",
    );
  }

  Future<void> _editTranslation(BuildContext context, Sentence sentence) async {
    final controller = TextEditingController(text: sentence.translation);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("编辑整句译文"),
        content: SizedBox(
          width: 420,
          child: TextField(controller: controller, maxLines: 4, decoration: const InputDecoration(hintText: "输入译文")),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("取消")),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text("保存"),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) {
      return;
    }
    TeacherStore.instance.setTranslation(lessonId: lesson.id, sentenceId: sentence.id, text: result);
  }
}
