# -*- coding: utf-8 -*-
import json, urllib.request, time, shutil, os

MIRROR = "https://storage.flutter-io.cn/flutter_infra_release/releases/releases_windows.json"
d = json.load(urllib.request.urlopen(MIRROR, timeout=60))
cur = d["current_release"]["stable"]
rel = [r for r in d["releases"] if r["hash"] == cur][0]
print("stable hash:", cur)
print("version:", rel["version"], "| archive:", rel["archive"], "| dart:", rel.get("dart_sdk_version"))
print("base_url:", d["base_url"])

u = d["base_url"] + "/" + rel["archive"]
req = urllib.request.Request(u, headers={"Range": "bytes=0-4194303"})
t0 = time.time()
data = urllib.request.urlopen(req, timeout=120).read()
dt = time.time() - t0
print("mirror first4MB: %.2fs  %.2f MB/s  got %d bytes" % (dt, len(data) / dt / 1048576, len(data)))

for drive in ["C:\\", "D:\\", "A:\\"]:
    try:
        total, used, free = shutil.disk_usage(drive)
        print(drive, "free %.1f GB / total %.1f GB" % (free / 2**30, total / 2**30))
    except Exception as e:
        print(drive, "ERR", e)
