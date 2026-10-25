# -*- coding: utf-8 -*-
"""校验内容 JSON：字段、ID、token 顺序与文本匹配。"""
import json, os, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "app", "assets", "content")
ROOT = os.path.abspath(ROOT)
errors, warnings = [], []


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def main():
    index_path = os.path.join(ROOT, "index.json")
    if not os.path.exists(index_path):
        errors.append("找不到 index.json")
        return report()
    index = load(index_path)
    if index.get("schemaVersion") != 1:
        errors.append("index.schemaVersion 必须为 1")
    if not index.get("contentVersion"):
        errors.append("index.contentVersion 不能为空")
    entries = index.get("lessons", [])
    if not entries:
        errors.append("index.lessons 为空")
    seen, total_sent, total_tok = set(), 0, 0
    for entry in entries:
        lid = entry.get("id", "")
        if not lid:
            errors.append("lesson id 为空")
        if lid in seen:
            errors.append("lesson id 重复: " + lid)
        seen.add(lid)
        for field in ("title", "author", "volume", "file"):
            if not entry.get(field):
                errors.append(lid + " 缺少字段 " + field)
        path = os.path.join(ROOT, entry.get("file", ""))
        if not os.path.exists(path):
            errors.append(lid + " 文件不存在: " + entry.get("file", ""))
            continue
        lesson = load(path)
        if lesson.get("id") != lid:
            errors.append(lid + " 文件内 id 与 index 不一致")
        if not isinstance(lesson.get("reviewed"), bool):
            errors.append(lid + " reviewed 必须是布尔值")
        for field in ("title", "author", "source", "volume"):
            if not lesson.get(field):
                errors.append(lid + " 文件缺少字段 " + field)
        sentences = lesson.get("sentences", [])
        if not sentences:
            errors.append(lid + " 没有句子")
        seen_sent = set()
        for s in sentences:
            sid = s.get("id", "")
            if not sid:
                errors.append(lid + " 句子 id 为空")
            if sid in seen_sent:
                errors.append(lid + " 句子 id 重复: " + sid)
            seen_sent.add(sid)
            if not s.get("text"):
                errors.append(sid + " text 为空")
            if not s.get("translation"):
                errors.append(sid + " translation 为空")
            text = s.get("text", "")
            cursor = 0
            tokens = s.get("tokens", [])
            if not tokens:
                warnings.append(sid + " 没有注释词")
            for t in tokens:
                surface = t.get("surface", "")
                if not surface:
                    errors.append(sid + " token.surface 为空")
                    continue
                if not t.get("gloss"):
                    errors.append(sid + " 「" + surface + "」缺少释义")
                idx = text.find(surface, cursor)
                if idx < 0:
                    errors.append(sid + " 找不到 token「" + surface + "」（顺序需与原文一致）")
                else:
                    cursor = idx + len(surface)
            total_sent += 1
            total_tok += len(tokens)
    print("校验完成：", len(entries), "篇 /", total_sent, "句 /", total_tok, "个注释")
    return report()


def report():
    for w in warnings:
        print("WARN:", w)
    for e in errors:
        print("ERROR:", e)
    if errors:
        print("失败：", len(errors), "个错误")
        return 1
    print("通过：0 个错误")
    return 0


if __name__ == "__main__":
    sys.exit(main())
