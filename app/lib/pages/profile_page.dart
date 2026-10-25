import "package:flutter/material.dart";

import "../services/card_store.dart";
import "../services/stats_store.dart";
import "../services/wrong_store.dart";
import "../theme.dart";
import "import_page.dart";
import "quiz_page.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("我", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([CardStore.instance, WrongStore.instance, StatsStore.instance]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  _statCard("复习卡", "${CardStore.instance.total}"),
                  const SizedBox(width: 12),
                  _statCard("待复习", "${CardStore.instance.dueCount}"),
                  const SizedBox(width: 12),
                  _statCard("错题", "${WrongStore.instance.count}"),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _statCard("今日复习", "${StatsStore.instance.reviews}"),
                  const SizedBox(width: 12),
                  _statCard("今日刷题", "${StatsStore.instance.questions}"),
                  const SizedBox(width: 12),
                  _statCard("正确率", "${StatsStore.instance.accuracy}%"),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text("错题本", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
                  const Spacer(),
                  if (WrongStore.instance.items.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const QuizPage(wrongOnly: true)),
                      ),
                      icon: const Icon(Icons.replay, size: 18),
                      label: const Text("重练错题"),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (WrongStore.instance.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("还没有错题，去「练」里做一组题吧", style: TextStyle(fontSize: 14, color: kMuted)),
                )
              else
                for (final word in WrongStore.instance.items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: kLine)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${word.surface}  ${word.gloss}", style: const TextStyle(fontSize: 15, color: kInk)),
                        const SizedBox(height: 4),
                        Text("《${word.lessonTitle}》 ${word.sentenceText}", style: const TextStyle(fontSize: 12, color: kMuted)),
                      ],
                    ),
                  ),
              const SizedBox(height: 24),
              const Text("内容", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file, color: kAccent),
                title: const Text("导入内容包", style: TextStyle(fontSize: 15, color: kInk)),
                subtitle: const Text("从 .wyc 文件导入或更新篇目", style: TextStyle(fontSize: 12, color: kMuted)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ImportPage())),
              ),
              const Divider(color: kLine),
              const Text("设置", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline, color: kAccent),
                title: const Text("清空学习数据", style: TextStyle(fontSize: 15, color: kInk)),
                subtitle: const Text("复习卡、错题本会全部删除", style: TextStyle(fontSize: 12, color: kMuted)),
                onTap: () => _confirmClear(context),
              ),
              const Divider(color: kLine),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline, color: kMuted),
                title: Text("文言研习 v0.1.16", style: TextStyle(fontSize: 15, color: kInk)),
                subtitle: Text("离线版 · 内容 3 篇示例", style: TextStyle(fontSize: 12, color: kMuted)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kAccent)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("清空学习数据？"),
        content: const Text("复习卡和错题本会被删除，学习记录无法恢复。"),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("取消")),
          TextButton(
            onPressed: () {
              CardStore.instance.clear();
              WrongStore.instance.clear();
              Navigator.of(dialogContext).pop();
            },
            child: const Text("清空", style: TextStyle(color: kAccent)),
          ),
        ],
      ),
    );
  }
}
