# -*- coding: utf-8 -*-
import os, shutil, time, zipfile

DL = r"D:\dev\downloads"
FLUTTER_ZIP = os.path.join(DL, "flutter_windows_3.47.8-stable.zip")
CT_ZIP = os.path.join(DL, "commandlinetools-win-16111833_latest.zip")
DEV = r"D:\dev"
ANDROID = os.path.join(DEV, "android-sdk")

os.makedirs(DEV, exist_ok=True)
os.makedirs(ANDROID, exist_ok=True)

t0 = time.time()
if os.path.exists(os.path.join(DEV, "flutter", "bin", "flutter.bat")):
    print("flutter already extracted")
else:
    print("extracting flutter ...", flush=True)
    with zipfile.ZipFile(FLUTTER_ZIP) as z:
        z.extractall(DEV)
    print("flutter extracted in %.1fs" % (time.time() - t0), flush=True)

ct_tmp = os.path.join(ANDROID, "_ct_tmp")
if os.path.exists(os.path.join(ANDROID, "cmdline-tools", "latest", "bin", "sdkmanager.bat")):
    print("cmdline-tools already extracted")
else:
    print("extracting cmdline-tools ...", flush=True)
    if os.path.exists(ct_tmp):
        shutil.rmtree(ct_tmp)
    with zipfile.ZipFile(CT_ZIP) as z:
        z.extractall(ct_tmp)
    inner = os.path.join(ct_tmp, "cmdline-tools")
    dest = os.path.join(ANDROID, "cmdline-tools", "latest")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.move(inner, dest)
    shutil.rmtree(ct_tmp, ignore_errors=True)
    print("cmdline-tools extracted", flush=True)

print("flutter.bat:", os.path.exists(os.path.join(DEV, "flutter", "bin", "flutter.bat")))
print("sdkmanager.bat:", os.path.exists(os.path.join(ANDROID, "cmdline-tools", "latest", "bin", "sdkmanager.bat")))
