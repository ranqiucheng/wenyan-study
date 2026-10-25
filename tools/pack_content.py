# -*- coding: utf-8 -*-
"""把 assets/content 打包成 .wyc 内容包（ZIP + manifest + 校验和）。"""
import datetime, hashlib, json, os, zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
CONTENT = os.path.join(ROOT, "app", "assets", "content")
OUT_DIR = os.path.join(ROOT, "release")
OUT = os.path.join(OUT_DIR, "wenyan-content-2026.10-m6.wyc")


def collect():
    files = []
    for dirpath, _, filenames in os.walk(CONTENT):
        for name in filenames:
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, CONTENT).replace(os.sep, "/")
            files.append((rel, full))
    return sorted(files)


def sha256_files(files):
    h = hashlib.sha256()
    for rel, full in files:
        h.update(rel.encode("utf-8"))
        with open(full, "rb") as f:
            h.update(f.read())
    return h.hexdigest()


def main():
    files = collect()
    index = json.load(open(os.path.join(CONTENT, "index.json"), encoding="utf-8"))
    counts = {"lessons": len(index.get("lessons", [])), "sentences": 0, "tokens": 0}
    for entry in index.get("lessons", []):
        lesson = json.load(open(os.path.join(CONTENT, entry["file"]), encoding="utf-8"))
        counts["sentences"] += len(lesson.get("sentences", []))
        counts["tokens"] += sum(len(s.get("tokens", [])) for s in lesson.get("sentences", []))
    manifest = {
        "schemaVersion": 1,
        "contentVersion": index.get("contentVersion", "unknown"),
        "builtAt": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        "counts": counts,
        "checksum": "sha256:" + sha256_files(files),
        "minAppVersion": "0.1.0",
    }
    os.makedirs(OUT_DIR, exist_ok=True)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2))
        for rel, full in files:
            z.write(full, "content/" + rel)
    size = os.path.getsize(OUT)
    print("已生成:", OUT)
    print("大小: %.1f KB" % (size / 1024))
    print("manifest:", json.dumps(manifest, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
