# -*- coding: utf-8 -*-
import os, re, time, urllib.request, xml.etree.ElementTree as ET

DL = r"D:\dev\downloads"
os.makedirs(DL, exist_ok=True)

FLUTTER_URL = "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.8-stable.zip"
FLUTTER_ZIP = os.path.join(DL, "flutter_windows_3.47.8-stable.zip")


def sizeof_fmt(n):
    return "%.1f MB" % (n / 2 ** 20)


def download(url, path, label):
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=60) as r:
            total = int(r.headers.get("Content-Length") or 0)
    except Exception as e:
        print("HEAD FAIL", label, e, flush=True)
        total = 0
    have = os.path.getsize(path) if os.path.exists(path) else 0
    if total and have >= total:
        print("SKIP", label, sizeof_fmt(have), flush=True)
        return path
    headers = {"User-Agent": "Mozilla/5.0"}
    mode = "wb"
    if have and total and have < total:
        headers["Range"] = "bytes=%d-" % have
        mode = "ab"
        print("RESUME", label, "from", sizeof_fmt(have), flush=True)
    req = urllib.request.Request(url, headers=headers)
    t0 = time.time()
    last = -5
    with urllib.request.urlopen(req, timeout=120) as r, open(path, mode) as f:
        if mode == "wb":
            total = int(r.headers.get("Content-Length") or 0)
        while True:
            chunk = r.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
            have += len(chunk)
            pct = int(have * 100 / total) if total else 0
            if pct >= last + 5:
                last = pct
                speed = have / max(0.001, time.time() - t0) / 2 ** 20
                print("  %s %3d%%  %s / %s  %.1f MB/s" % (label, pct, sizeof_fmt(have), sizeof_fmt(total), speed), flush=True)
    print("DONE", label, sizeof_fmt(os.path.getsize(path)), flush=True)
    return path


def find_cmdline_tools():
    url = "https://dl.google.com/android/repository/repository2-1.xml"
    data = urllib.request.urlopen(url, timeout=60).read().decode("utf-8", "ignore")
    urls = re.findall(r"<url>(commandlinetools-win-[^<]+)</url>", data)
    if not urls:
        raise SystemExit("cmdline-tools url not found")
    def build_no(u):
        m = re.search(r"(\d+)_latest", u)
        return int(m.group(1)) if m else 0
    urls = sorted(set(urls), key=build_no)
    return "https://dl.google.com/android/repository/" + urls[-1], urls[-1]


if __name__ == "__main__":
    print("=== Flutter SDK ===", flush=True)
    download(FLUTTER_URL, FLUTTER_ZIP, "flutter")
    print("=== Android cmdline-tools ===", flush=True)
    ct_url, ct_name = find_cmdline_tools()
    print("cmdline-tools:", ct_name, flush=True)
    download(ct_url, os.path.join(DL, ct_name), "cmdline-tools")
    print("ALL DONE", flush=True)
