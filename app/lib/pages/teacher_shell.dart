import "dart:io";

import "package:flutter/material.dart";

import "../data/content_repository.dart";
import "../models/lesson.dart";
import "../services/app_storage.dart";
import "../services/content_exporter.dart";
import "../services/save_dialog.dart";
import "../services/teacher_store.dart";
import "../theme.dart";
import "import_page.dart";
import "teacher_editor_page.dart";

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key, this.previewLessons});

  /// 仅用于界面预览/测试；为空时从 assets 加载。
  final List<Lesson>? previewLessons;

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  List<Lesson> _lessons = const <Lesson>[];
  bool _loading = true;
  int _nav = 0;
  int _filter = 0;
  File? _lastExport;

  @override
  void initState() {
    super.initState();
    TeacherStore.instance.load();
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TeacherStore.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("文言研习 · 老师端", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                tooltip: "刷新内容",
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text("学生端"),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _nav,
                      onDestinationSelected: (value) => setState(() => _nav = value),
                      labelType: NavigationRailLabelType.all,
                      selectedIconTheme: const IconThemeData(color: kAccent),
                      selectedLabelTextStyle: const TextStyle(color: kAccent, fontSize: 12, fontFamily: "Microsoft YaHei"),
                      unselectedIconTheme: const IconThemeData(color: kMuted),
                      unselectedLabelTextStyle: const TextStyle(color: kMuted, fontSize: 12, fontFamily: "Microsoft YaHei"),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.menu_book_outlined),
                          selectedIcon: Icon(Icons.menu_book),
                          label: Text("篇目"),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.archive_outlined),
                          selectedIcon: Icon(Icons.archive),
                          label: Text("导出"),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.upload_file_outlined),
                          selectedIcon: Icon(Icons.upload_file),
                          label: Text("导入"),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1, color: kLine),
                    Expanded(child: _nav == 0 ? _lessonList() : (_nav == 1 ? _exportPage() : const ImportContentBody())),
                  ],
                ),
        );
      },
    );
  }

  Widget _lessonList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Text("内容编辑", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kInk)),
        const SizedBox(height: 6),
        const Text("修改会自动保存到本机；导出内容包后学生端才会看到。", style: TextStyle(fontSize: 13, color: kMuted)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () => _createLesson(context),
              icon: const Icon(Icons.add),
              label: const Text("新增篇目"),
            ),
            OutlinedButton.icon(
              onPressed: () => _markAllReviewed(context),
              icon: const Icon(Icons.done_all),
              label: const Text("全部标记已校对"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            ChoiceChip(
              label: const Text("全部"),
              selected: _filter == 0,
              onSelected: (_) => setState(() => _filter = 0),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("待校对"),
              selected: _filter == 1,
              onSelected: (_) => setState(() => _filter = 1),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text("已校对"),
              selected: _filter == 2,
              onSelected: (_) => setState(() => _filter = 2),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final lesson in _visibleLessons())
          _lessonCard(lesson, TeacherStore.instance.baseLessonsWithCreated(_lessons)),
      ],
    );
  }

  Widget _lessonCard(Lesson lesson, List<Lesson> all) {
    final edits = TeacherStore.instance.editCountForLesson(lesson.id);
    final reviewed = TeacherStore.instance.reviewedFor(lesson.id) || lesson.reviewed;
    return Material(
      color: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: kLine)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => TeacherEditorPage(lesson: lesson)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: kInk, fontFamily: "SimSun")),
                    const SizedBox(height: 4),
                    Text("${lesson.author} · ${lesson.source} · ${lesson.volume}", style: const TextStyle(fontSize: 12, color: kMuted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(reviewed ? "已校对" : "待校对", reviewed ? kGreen : kAccent, reviewed ? const Color(0xFFEEF3EE) : kPale),
                        _chip("修改 $edits 处", kMuted, const Color(0xFFF4F1EA)),
                        _chip("${lesson.sentences.length} 句", kMuted, const Color(0xFFF4F1EA)),
                        if (TeacherStore.instance.isCreated(lesson.id))
                          _chip("自建", kAccent, kPale),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: "上移",
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_upward, size: 18, color: kMuted),
                onPressed: () => TeacherStore.instance.moveLesson(all, lesson.id, -1),
              ),
              IconButton(
                tooltip: "下移",
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_downward, size: 18, color: kMuted),
                onPressed: () => TeacherStore.instance.moveLesson(all, lesson.id, 1),
              ),
              IconButton(
                tooltip: "删除篇目",
                icon: const Icon(Icons.delete_outline, color: kMuted),
                onPressed: () => _deleteLesson(context, lesson),
              ),
              const Icon(Icons.chevron_right, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }

  List<Lesson> _visibleLessons() {
    final all = TeacherStore.instance.baseLessonsWithCreated(_lessons);
    if (_filter == 0) return all;
    return all.where((lesson) {
      final reviewed = TeacherStore.instance.reviewedFor(lesson.id) || lesson.reviewed;
      return _filter == 1 ? !reviewed : reviewed;
    }).toList();
  }

  Future<void> _createLesson(BuildContext context) async {
    final title = TextEditingController();
    final author = TextEditingController();
    final source = TextEditingController(text: "自建篇目");
    final volume = TextEditingController(text: "必修上册");
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("新增篇目"),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: "篇名")),
              const SizedBox(height: 10),
              TextField(controller: author, decoration: const InputDecoration(labelText: "作者")),
              const SizedBox(height: 10),
              TextField(controller: source, decoration: const InputDecoration(labelText: "出处")),
              const SizedBox(height: 10),
              TextField(controller: volume, decoration: const InputDecoration(labelText: "册次")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("取消")),
          FilledButton(
            onPressed: () {
              if (title.text.trim().isEmpty) {
                return;
              }
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text("创建"),
          ),
        ],
      ),
    );
    if (result == true) {
      final lesson = TeacherStore.instance.createLesson(
        title: title.text.trim(),
        author: author.text.trim(),
        source: source.text.trim(),
        volume: volume.text.trim(),
      );
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => TeacherEditorPage(lesson: lesson)),
        );
      }
    }
    title.dispose();
    author.dispose();
    source.dispose();
    volume.dispose();
  }

  Future<void> _markAllReviewed(BuildContext context) async {
    final lessons = TeacherStore.instance.baseLessonsWithCreated(_lessons);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("全部标记已校对？"),
        content: Text("将把 ${lessons.length} 篇全部标记为已校对。"),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text("取消")),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text("确认")),
        ],
      ),
    );
    if (confirmed == true) {
      TeacherStore.instance.markAllReviewed(lessons);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("已全部标记为已校对")));
      }
    }
  }

  Future<void> _deleteLesson(BuildContext context, Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("删除这篇？"),
        content: Text("《${lesson.title}》将从列表和导出内容中移除。"),
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
      TeacherStore.instance.deleteLesson(lesson.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已删除《${lesson.title}》")));
      }
    }
  }

  Widget _chip(String text, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _exportPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Text("导出内容包", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kInk)),
        const SizedBox(height: 6),
        const Text("把当前所有编辑合并成 .wyc 内容包，发给学生导入后生效。", style: TextStyle(fontSize: 13, color: kMuted)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: kLine)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("将导出 ${TeacherStore.instance.baseLessonsWithCreated(_lessons).length} 篇", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 6),
              const Text("包含全部篇目、译文与词条释义；manifest 带版本号和 SHA-256 校验。", style: TextStyle(fontSize: 12, height: 1.6, color: kMuted)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _lessons.isEmpty ? null : _export,
                icon: const Icon(Icons.archive_outlined),
                label: const Text("导出 .wyc"),
              ),
            ],
          ),
        ),
        if (_lastExport != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFEEF3EE), borderRadius: BorderRadius.circular(18), border: Border.all(color: kGreen)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("已导出：${_lastExport!.path}", style: const TextStyle(fontSize: 12, height: 1.5, color: kGreen)),
                const SizedBox(height: 6),
                Text("大小 ${(_lastExport!.lengthSync() / 1024).toStringAsFixed(1)} KB", style: const TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 12),
                if (Platform.isWindows)
                  OutlinedButton.icon(
                    onPressed: () => Process.run("explorer.exe", [_lastExport!.parent.path]),
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text("打开所在文件夹"),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _export() async {
    try {
      final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r"[^0-9]"), "").substring(0, 14);
      final picked = await SaveDialog.pickSavePath(suggestedName: "wenyan-content-$stamp.wyc");
      if (picked == null) {
        return;
      }
      var path = picked;
      if (!path.toLowerCase().endsWith(".wyc")) {
        path = "$path.wyc";
      }
      final applied = TeacherStore.instance.applyAll(_lessons).toList();
      final file = ContentExporter.exportTo(lessons: applied, file: File(path), questions: TeacherStore.instance.questions);
      setState(() => _lastExport = file);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("已导出：${file.path}")));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("导出失败：$error")));
    }
  }
}
