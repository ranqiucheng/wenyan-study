import urllib.request
for u in ["https://github.com/git-for-windows/git/releases/latest",
          "https://npmmirror.com/mirrors/git-for-windows/",
          "https://mirrors.tuna.tsinghua.edu.cn/github-release/git-for-windows/git/"]:
    try:
        req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"})
        r = urllib.request.urlopen(req, timeout=30)
        print("OK", r.status, u)
    except Exception as e:
        print("FAIL", u, e)
