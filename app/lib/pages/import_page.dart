import "dart:io";

import "package:flutter/material.dart";

import "../services/android_file_picker.dart";
import "../services/content_importer.dart";
import "../services/imported_content_store.dart";
import "../theme.dart";

class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("导入内容包", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
      body: const ImportContentBody(),
    );
  }
}

class ImportContentBody extends StatefulWidget {
  const ImportContentBody({super.key});

  @override
  State<ImportContentBody> createState() => _ImportContentBodyState();
}

class _ImportContentBodyState extends State<ImportContentBody> {
  List<File> _files = const <File>[];
  bool _scanning = true;

  @override
  void initState() {
    super.initState();
    ImportedContentStore.instance.load();
    _scan();
  }

  void _scan() {
    setState(() {
      _files = ImportedContentStore.instance.scanPackFiles();
      _scanning = false;
    });
  }

  Future<void> _import(File file) async {
    try {
      final result = ContentImporter.importFile(file);
      if (!mounted) {
        return;
      }
      setState(_scan);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("导入成功"),
          content: Text(
            "版本：${result.contentVersion}\n篇目：${result.lessonCount} 篇\n句子：${result.sentenceCount} 句\n校验：通过",
            style: const TextStyle(height: 1.6),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("好"))],
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text("导入失败"),
          content: Text("$error"),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("好"))],
        ),
      );
    }
  }

  Future<void> _pickAndImport() async {
    try {
      final picked = await AndroidFilePicker.pickContentPack();
      if (picked == null) {
        return;
      }
      final result = ContentImporter.importBytes(picked.bytes);
      if (!mounted) {
        return;
      }
      setState(_scan);
      await _showSuccess(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _showError(error);
    }
  }

  Future<void> _showSuccess(ImportResult result) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("导入成功"),
        content: Text(
          "版本：${result.contentVersion}\n篇目：${result.lessonCount} 篇\n句子：${result.sentenceCount} 句\n校验：通过",
          style: const TextStyle(height: 1.6),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("好"))],
      ),
    );
  }

  Future<void> _showError(Object error) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("导入失败"),
        content: Text("$error"),
        actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("好"))],
      ),
    );
  }

  void _openFolder() {
    final dir = ImportedContentStore.instance.importsDir;
    dir.createSync(recursive: true);
    if (Platform.isWindows) {
      Process.run("explorer.exe", [dir.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dir = ImportedContentStore.instance.importsDir;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        const Text("导入内容包", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kInk)),
        const SizedBox(height: 6),
        const Text("把 .wyc 内容包放到下面的文件夹，然后点导入。导入会叠加到内置内容上，同 id 的篇目会被覆盖。", style: TextStyle(fontSize: 13, height: 1.6, color: kMuted)),
        if (Platform.isAndroid) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _pickAndImport,
            icon: const Icon(Icons.folder_open),
            label: const Text("从手机选择 .wyc 文件"),
          ),
          const SizedBox(height: 8),
          const Text(
            "微信里的文件请先点右上角「…」→「保存到手机」，再在这里选择（通常在「下载/Downloads」目录）。",
            style: TextStyle(fontSize: 11, height: 1.5, color: kMuted),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("内容包文件夹", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 6),
              SelectableText(dir.path, style: const TextStyle(fontSize: 12, color: kMuted)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  if (Platform.isWindows)
                    OutlinedButton.icon(onPressed: _openFolder, icon: const Icon(Icons.folder_open, size: 18), label: const Text("打开文件夹")),
                  OutlinedButton.icon(onPressed: _scan, icon: const Icon(Icons.refresh, size: 18), label: const Text("重新扫描")),
                ],
              ),
              if (!Platform.isWindows)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("安卓：通过 USB/文件管理器把 .wyc 放进该应用私有目录（后续会改成系统文件选择器）。", style: TextStyle(fontSize: 11, color: kMuted)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_scanning)
          const Center(child: CircularProgressIndicator())
        else if (_files.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
            child: const Text("文件夹里还没有 .wyc 文件", style: TextStyle(fontSize: 13, color: kMuted)),
          )
        else
          for (final file in _files)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: kLine)),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, color: kAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(file.uri.pathSegments.last, style: const TextStyle(fontSize: 14, color: kInk), overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text("${(file.lengthSync() / 1024).toStringAsFixed(1)} KB", style: const TextStyle(fontSize: 11, color: kMuted)),
                      ],
                    ),
                  ),
                  FilledButton(onPressed: () => _import(file), child: const Text("导入")),
                ],
              ),
            ),
        const SizedBox(height: 10),
        if (ImportedContentStore.instance.packs.isNotEmpty) ...[
          const Text("已导入", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 8),
          for (final pack in ImportedContentStore.instance.packs)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEEF3EE), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Text("版本 ${pack.contentVersion} · ${pack.lessons.length} 篇 · ${pack.checksum.replaceFirst("sha256:", "").substring(0, 10)}…", style: const TextStyle(fontSize: 12, color: kGreen)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => ImportedContentStore.instance.removePack(pack)),
                    child: const Text("移除", style: TextStyle(color: kMuted)),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
