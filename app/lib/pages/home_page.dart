import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "../data/content_repository.dart";
import "../services/imported_content_store.dart";
import "../models/lesson.dart";
import "../theme.dart";
import "teacher_shell.dart";
import "reading_page.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.loader});

  /// 可注入的内容加载器，默认从 assets 读取。
  final Future<List<Lesson>> Function()? loader;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Lesson>> _future;

  @override
  void initState() {
    super.initState();
    _future = (widget.loader ?? ContentRepository.loadAll)();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("文言研习", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        actions: [
          if (defaultTargetPlatform == TargetPlatform.windows)
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TeacherShell()),
              ),
              icon: const Icon(Icons.school_outlined, size: 18),
              label: const Text("老师端"),
            ),
          IconButton(
            tooltip: "刷新内容",
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = ContentRepository.loadAll()),
          ),
          IconButton(
            tooltip: "搜索（待实现）",
            icon: const Icon(Icons.search),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("搜索功能在 M2 实现")),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Lesson>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("内容加载失败：${snapshot.error}", style: const TextStyle(color: kMuted)));
          }
          final lessons = snapshot.data ?? const <Lesson>[];
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: lessons.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("高中文言文 · 精读", style: TextStyle(fontSize: 12, color: kMuted)),
                      const SizedBox(height: 6),
                      const Text("今天读一篇", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kInk)),
                      const SizedBox(height: 4),
                      Text("共 ${lessons.length} 篇示例内容 · 已校对", style: const TextStyle(fontSize: 12, color: kGreen)),
                    ],
                  ),
                );
              }
              final lesson = lessons[index - 1];
              return _LessonCard(
                lesson: lesson,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ReadingPage(lesson: lesson)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kInk, fontFamily: "SimSun")),
                    const SizedBox(height: 6),
                    Text("${lesson.author} · ${lesson.source} · ${lesson.volume}", style: const TextStyle(fontSize: 12, color: kMuted)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final tag in lesson.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: kPale, borderRadius: BorderRadius.circular(20)),
                            child: Text(tag, style: const TextStyle(fontSize: 11, color: kAccent)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEEF3EE), borderRadius: BorderRadius.circular(20)),
                          child: const Text("已校对", style: TextStyle(fontSize: 11, color: kGreen)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }
}
