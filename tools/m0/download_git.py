# -*- coding: utf-8 -*-
import json, os, urllib.request

DL = r"D:\dev\downloads"
os.makedirs(DL, exist_ok=True)
req = urllib.request.Request(
    "https://api.github.com/repos/git-for-windows/git/releases/latest",
    headers={"User-Agent": "wenyan-setup", "Accept": "application/vnd.github+json"},
)
rel = json.load(urllib.request.urlopen(req, timeout=60))
print("latest tag:", rel["tag_name"])
assets = rel["assets"]
for a in assets:
    print("  ", a["name"], a["size"] // 2**20, "MB")
pick = None
for a in assets:
    n = a["name"]
    if n.startswith("PortableGit-") and n.endswith("64-bit.7z.exe"):
        pick = a
        break
if pick is None:
    for a in assets:
        if a["name"].startswith("Git-") and a["name"].endswith("64-bit.exe"):
            pick = a
            break
print("picked:", pick["name"], pick["size"] // 2**20, "MB")
dest = os.path.join(DL, pick["name"])
if os.path.exists(dest) and os.path.getsize(dest) == pick["size"]:
    print("already downloaded")
else:
    req2 = urllib.request.Request(pick["browser_download_url"], headers={"User-Agent": "wenyan-setup"})
    with urllib.request.urlopen(req2, timeout=120) as r, open(dest, "wb") as f:
        while True:
            chunk = r.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
    print("downloaded", dest, os.path.getsize(dest) // 2**20, "MB")
