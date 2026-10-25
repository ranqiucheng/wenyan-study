# -*- coding: utf-8 -*-
import os, subprocess, sys

SDK = r"D:\dev\android-sdk"
SDKMANAGER = os.path.join(SDK, "cmdline-tools", "latest", "bin", "sdkmanager.bat")
env = dict(os.environ)


def run(args, inp=None, timeout=3600):
    print(">>", " ".join(args), flush=True)
    p = subprocess.run(args, input=inp, capture_output=True, text=True, timeout=timeout, env=env)
    out = (p.stdout or "") + (p.stderr or "")
    tail = "\n".join(out.splitlines()[-25:])
    print(tail, flush=True)
    print("rc=", p.returncode, flush=True)
    return p.returncode


print("sdkmanager:", SDKMANAGER, os.path.exists(SDKMANAGER), flush=True)
run([SDKMANAGER, "--version"])
run([SDKMANAGER, "--licenses"], inp="y\n" * 60)
run([SDKMANAGER, "--list_installed"])
run([SDKMANAGER, "platform-tools", "platforms;android-36", "build-tools;36.0.0"])
run([SDKMANAGER, "--list_installed"])
print("DONE", flush=True)
