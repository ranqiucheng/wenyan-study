# -*- coding: utf-8 -*-
"""生成方案文档用的低保真界面草案（Pillow）。"""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
os.makedirs(OUT, exist_ok=True)

SIMSUN = r"C:\Windows\Fonts\simsun.ttc"
MSYH = r"C:\Windows\Fonts\msyh.ttc"
MSYHBD = r"C:\Windows\Fonts\msyhbd.ttc"

INK = (31, 35, 40)
MUTED = (107, 111, 118)
PAPER = (251, 247, 239)
CARD = (255, 255, 255)
ACCENT = (196, 85, 59)
GREEN = (79, 122, 103)
LINE = (232, 224, 208)
PALE = (243, 227, 211)


def font(path, size):
    return ImageFont.truetype(path, size, index=0)


def rr(d, box, radius=16, fill=None, outline=None, width=2):
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def txt(d, xy, s, f, fill=INK, anchor="la", spacing=8):
    d.multiline_text(xy, s, font=f, fill=fill, anchor=anchor, spacing=spacing)


def status_bar(d, w):
    d.text((28, 16), "9:41", font=font(MSYHBD, 28), fill=INK)
    for i in range(4):
        d.rectangle((w - 150 + i * 12, 34 - i * 4, w - 143 + i * 12, 40), fill=INK)
    rr(d, (w - 90, 20, w - 40, 42), radius=6, outline=INK, width=2)
    d.rectangle((w - 46, 27, w - 42, 35), fill=INK)


def nav_bar(d, w, h, active=0):
    rr(d, (0, h - 120, w, h), radius=0, fill=CARD)
    d.line((0, h - 120, w, h - 120), fill=LINE, width=2)
    labels = ["读", "背", "练", "我"]
    for i, lab in enumerate(labels):
        cx = int(w * (0.125 + i * 0.25))
        color = ACCENT if i == active else MUTED
        if i == 0:
            d.rectangle((cx - 18, h - 92, cx + 18, h - 60), outline=color, width=3)
            d.line((cx, h - 92, cx, h - 60), fill=color, width=2)
        elif i == 1:
            d.rectangle((cx - 20, h - 92, cx + 2, h - 62), outline=color, width=3)
            d.rectangle((cx - 2, h - 88, cx + 20, h - 58), fill=PAPER, outline=color, width=3)
        elif i == 2:
            d.polygon([(cx - 18, h - 60), (cx - 6, h - 92), (cx + 8, h - 60)], outline=color, width=3)
            d.line((cx - 16, h - 70, cx + 4, h - 70), fill=color, width=3)
        else:
            d.ellipse((cx - 12, h - 94, cx + 12, h - 70), outline=color, width=3)
            d.arc((cx - 20, h - 74, cx + 20, h - 44), 200, 340, fill=color, width=3)
        txt(d, (cx, h - 40), lab, font(MSYHBD, 26), fill=color, anchor="mm")
    if active == 0:
        rr(d, (w // 8 - 18, h - 126, w // 8 + 18, h - 120), radius=3, fill=ACCENT)


def reading_page():
    w, h = 780, 1688
    img = Image.new("RGB", (w, h), PAPER)
    d = ImageDraw.Draw(img)
    status_bar(d, w)

    d.line((64, 86, 96, 100), fill=INK, width=4)
    d.line((64, 114, 96, 100), fill=INK, width=4)
    txt(d, (124, 66), "劝学", font(SIMSUN, 54), fill=INK)
    txt(d, (124, 128), "荀子 · 高中课标篇目", font(MSYH, 26), fill=MUTED)
    rr(d, (596, 66, 730, 128), radius=31, fill=CARD, outline=LINE, width=2)
    txt(d, (618, 82), "注释", font(MSYH, 26), fill=MUTED)
    d.ellipse((694, 88, 714, 108), outline=MUTED, width=3)
    d.line((64, 152, w - 64, 152), fill=LINE, width=2)

    lines = [
        "君子曰：学不可以已。",
        "青，取之于蓝，而青于蓝；",
        "冰，水为之，而寒于水。",
        "木直中绳，輮以为轮，",
        "其曲中规。",
    ]
    y = 240
    body = font(SIMSUN, 46)
    for idx, line in enumerate(lines):
        if idx == 0:
            x = 64
            prefix = "君子曰：学不可以"
            d.text((x, y), prefix, font=body, fill=INK)
            xw = d.textlength(prefix, font=body)
            ww = d.textlength("已", font=body)
            rr(d, (x + xw - 4, y - 6, x + xw + ww + 4, y + 62), radius=8, fill=PALE)
            d.text((x + xw, y), "已", font=body, fill=INK)
            d.line((x + xw, y + 58, x + xw + ww, y + 58), fill=ACCENT, width=4)
            rr(d, (x + xw + ww + 18, y + 6, x + xw + ww + 142, y + 50), radius=22, fill=ACCENT)
            txt(d, (x + xw + ww + 80, y + 28), "点我", font(MSYHBD, 22), fill=CARD, anchor="mm")
        else:
            d.text((64, y), line, font=body, fill=INK)
        y += 96

    txt(d, (64, 840), "长按句子可看整句翻译 · 右上角可切换注释常显", font(MSYH, 24), fill=MUTED)

    rr(d, (0, 1080, w, h - 120), radius=42, fill=CARD)
    d.line((0, 1080, w, 1080), fill=LINE, width=2)
    rr(d, (w // 2 - 32, 1108, w // 2 + 32, 1118), radius=5, fill=LINE)

    txt(d, (64, 1150), "已", font(SIMSUN, 62), fill=INK)
    txt(d, (150, 1172), "yǐ", font(MSYH, 32), fill=MUTED)
    rr(d, (232, 1160, 316, 1204), radius=22, fill=PALE)
    txt(d, (274, 1182), "动词", font(MSYH, 24), fill=ACCENT, anchor="mm")
    rr(d, (330, 1160, 414, 1204), radius=22, fill=(238, 243, 238))
    txt(d, (372, 1182), "高频", font(MSYH, 24), fill=GREEN, anchor="mm")

    txt(d, (64, 1250), "① 停止     ② 已经     ③ 太、过分", font(MSYH, 36), fill=INK)
    txt(d, (64, 1322), "例句", font(MSYHBD, 24), fill=MUTED)
    d.text((140, 1314), "学不可以", font=font(SIMSUN, 34), fill=INK)
    xw2 = d.textlength("学不可以", font(SIMSUN, 34))
    xw3 = d.textlength("学不可以已", font(SIMSUN, 34))
    rr(d, (140 + xw2 - 2, 1310, 140 + xw3 + 2, 1354), radius=6, fill=PALE)
    d.text((140 + xw2, 1314), "已", font=font(SIMSUN, 34), fill=ACCENT)
    txt(d, (64, 1378), "点击义项可查看该义项下的其他例句", font(MSYH, 22), fill=MUTED)

    rr(d, (64, 1430, w - 64, 1520), radius=24, fill=ACCENT)
    txt(d, (w // 2, 1475), "加入复习卡", font(MSYHBD, 34), fill=CARD, anchor="mm")

    nav_bar(d, w, h, active=0)
    img.save(os.path.join(OUT, "01-阅读页.png"))


def flashcard():
    w, h = 780, 1688
    img = Image.new("RGB", (w, h), PAPER)
    d = ImageDraw.Draw(img)
    status_bar(d, w)

    txt(d, (48, 70), "今日复习", font(MSYHBD, 34), fill=INK)
    txt(d, (w - 48, 78), "12 / 30", font(MSYH, 28), fill=MUTED, anchor="ra")
    rr(d, (48, 122, w - 48, 134), radius=6, fill=LINE)
    rr(d, (48, 122, 48 + int((w - 96) * 0.4), 134), radius=6, fill=ACCENT)

    rr(d, (48, 190, w - 48, 790), radius=36, fill=CARD, outline=LINE, width=2)
    txt(d, (84, 220), "正面 · 填空", font(MSYH, 24), fill=MUTED)
    body = font(SIMSUN, 58)
    y = 400
    d.text((84, y), "学不可以", font=body, fill=INK)
    xw = d.textlength("学不可以", font=body)
    rr(d, (84 + xw + 8, y + 28, 84 + xw + 72, y + 33), radius=3, fill=LINE)
    d.text((84 + xw + 86, y), "。", font=body, fill=INK)
    txt(d, (w // 2, 560), "《劝学》", font(MSYH, 26), fill=MUTED, anchor="mm")
    txt(d, (w // 2, 700), "点卡片翻面", font(MSYH, 26), fill=MUTED, anchor="mm")

    rr(d, (48, 830, w - 48, 1190), radius=36, fill=CARD, outline=LINE, width=2)
    txt(d, (84, 860), "背面 · 答案", font(MSYH, 24), fill=MUTED)
    txt(d, (w // 2, 950), "已  yǐ", font(SIMSUN, 52), fill=INK, anchor="mm")
    txt(d, (w // 2, 1020), "① 停止   ② 已经   ③ 太、过分", font(MSYH, 28), fill=INK, anchor="mm")
    txt(d, (w // 2, 1100), "例句：学不可以已", font(SIMSUN, 30), fill=ACCENT, anchor="mm")

    labels = [("忘记", ACCENT), ("模糊", (169, 126, 78)), ("记得", GREEN), ("简单", (62, 106, 152))]
    bw = (w - 96 - 3 * 18) // 4
    for i, (lab, color) in enumerate(labels):
        x0 = 48 + i * (bw + 18)
        rr(d, (x0, 1240, x0 + bw, 1330), radius=22, fill=color)
        txt(d, (x0 + bw // 2, 1285), lab, font(MSYHBD, 28), fill=CARD, anchor="mm")
    txt(d, (w // 2, 1380), "按遗忘程度评分，算法会安排下次复习时间", font(MSYH, 22), fill=MUTED, anchor="mm")

    nav_bar(d, w, h, active=1)
    img.save(os.path.join(OUT, "02-字词卡.png"))

def classroom():
    w, h = 1280, 720
    img = Image.new("RGB", (w, h), PAPER)
    d = ImageDraw.Draw(img)

    txt(d, (60, 36), "劝学", font(MSYHBD, 22), fill=INK)
    txt(d, (160, 40), "荀子", font(MSYH, 16), fill=MUTED)
    txt(d, (w - 60, 40), "第 3 句 / 共 12 句", font(MSYH, 16), fill=MUTED, anchor="ra")
    d.line((60, 78, w - 60, 78), fill=LINE, width=2)

    lines = ["君子曰：", "学不可以已。"]
    y = 210
    body = font(SIMSUN, 64)
    for i, line in enumerate(lines):
        color = MUTED if i == 0 else INK
        d.text((120, y), line, font=body, fill=color)
        y += 110
    rr(d, (104, 296, 104 + d.textlength("学不可以已。", font=body) + 32, 400), radius=14, fill=PALE)
    d.text((120, 306), "学不可以已。", font=body, fill=INK)
    d.line((120, 392, 120 + d.textlength("学不可以已。", font=body), 392), fill=ACCENT, width=4)
    txt(d, (120, 424), "点击词语看注释", font(MSYH, 18), fill=MUTED)

    rr(d, (960, 200, 1220, 430), radius=20, fill=CARD, outline=LINE, width=2)
    txt(d, (984, 220), "已  yǐ", font(SIMSUN, 34), fill=INK)
    txt(d, (984, 276), "① 停止", font(MSYH, 22), fill=INK)
    txt(d, (984, 314), "② 已经", font(MSYH, 22), fill=MUTED)
    txt(d, (984, 352), "例句：学不可以已", font(SIMSUN, 20), fill=ACCENT)
    txt(d, (984, 394), "按空格切换注释常显", font(MSYH, 14), fill=MUTED)

    for i in range(12):
        cy = 180 + i * 30
        color = ACCENT if i == 2 else LINE
        d.ellipse((1242, cy, 1254, cy + 12), fill=color)

    d.line((60, 640, w - 60, 640), fill=LINE, width=2)
    txt(d, (60, 660), "← → 翻句    空格 显示/隐藏注释    Esc 退出课堂模式", font(MSYH, 16), fill=MUTED)
    txt(d, (w - 60, 660), "投屏建议：F11 全屏 · 字号 64pt", font(MSYH, 16), fill=MUTED, anchor="ra")
    img.save(os.path.join(OUT, "04-课堂模式.png"))


def teacher_editor():
    w, h = 1280, 800
    img = Image.new("RGB", (w, h), (243, 239, 230))
    d = ImageDraw.Draw(img)

    rr(d, (0, 0, w, 64), radius=0, fill=CARD)
    d.line((0, 64, w, 64), fill=LINE, width=2)
    rr(d, (20, 14, 56, 50), radius=12, fill=ACCENT)
    txt(d, (38, 32), "文", font(MSYHBD, 22), fill=CARD, anchor="mm")
    txt(d, (70, 20), "文言研习 · 老师端", font(MSYHBD, 20), fill=INK)
    txt(d, (70, 44), "内容编辑 / 校对 / 分发", font(MSYH, 12), fill=MUTED)
    rr(d, (1040, 16, 1122, 48), radius=16, outline=LINE, width=2)
    txt(d, (1081, 32), "预览", font(MSYH, 14), fill=INK, anchor="mm")
    rr(d, (1134, 16, 1256, 48), radius=16, fill=ACCENT)
    txt(d, (1195, 32), "导出内容包", font(MSYHBD, 14), fill=CARD, anchor="mm")

    rr(d, (0, 64, 220, h), radius=0, fill=(251, 248, 241))
    d.line((220, 64, 220, h), fill=LINE, width=2)
    items = ["篇目", "词条", "题目", "分发", "导入"]
    y = 100
    for i, it in enumerate(items):
        active = i == 0
        if active:
            rr(d, (16, y - 8, 204, y + 36), radius=12, fill=PALE)
        rr(d, (30, y, 54, y + 24), radius=6, outline=ACCENT if active else MUTED, width=2)
        txt(d, (68, y + 4), it, font(MSYHBD if active else MSYH, 17), fill=ACCENT if active else INK)
        y += 56
    rr(d, (16, 640, 204, 760), radius=14, fill=CARD, outline=LINE, width=2)
    txt(d, (32, 654), "校对进度", font(MSYH, 13), fill=MUTED)
    txt(d, (32, 676), "12 / 72 篇", font(MSYHBD, 22), fill=INK)
    rr(d, (32, 716, 188, 728), radius=6, fill=LINE)
    rr(d, (32, 716, 32 + int(156 * 12 / 72), 728), radius=6, fill=GREEN)
    txt(d, (32, 738), "今日校对 3 篇", font(MSYH, 12), fill=MUTED)

    txt(d, (244, 84), "劝学", font(MSYHBD, 30), fill=INK)
    txt(d, (244, 122), "荀子 · 高中课标 · 必修上册", font(MSYH, 13), fill=MUTED)
    rr(d, (520, 88, 590, 118), radius=15, fill=(238, 243, 238))
    txt(d, (555, 103), "已校对", font(MSYH, 12), fill=GREEN, anchor="mm")

    rr(d, (244, 156, 880, 740), radius=16, fill=CARD, outline=LINE, width=2)
    txt(d, (268, 176), "原文（点击字词进行标注）", font(MSYH, 13), fill=MUTED)
    lines = [
        "君子曰：学不可以已。",
        "青，取之于蓝，而青于蓝；",
        "冰，水为之，而寒于水。",
        "木直中绳，輮以为轮，",
        "其曲中规。",
    ]
    body = font(SIMSUN, 30)
    y = 230
    for idx, line in enumerate(lines):
        if idx == 0:
            x = 268
            prefix = "君子曰：学不可以"
            d.text((x, y), prefix, font=body, fill=INK)
            xw = d.textlength(prefix, font=body)
            ww = d.textlength("已", font=body)
            rr(d, (x + xw - 4, y - 4, x + xw + ww + 4, y + 42), radius=6, fill=PALE)
            d.rectangle((x + xw - 4, y - 4, x + xw + ww + 4, y + 42), outline=ACCENT, width=2)
            d.text((x + xw, y), "已", font=body, fill=ACCENT)
        else:
            d.text((268, y), line, font=body, fill=INK)
        y += 82
    txt(d, (268, 660), "· 选中字词后，右侧面板会显示可编辑字段", font(MSYH, 12), fill=MUTED)
    txt(d, (268, 690), "· 绿色对勾表示该词条已校对", font(MSYH, 12), fill=MUTED)

    rr(d, (896, 156, 1256, 740), radius=16, fill=CARD, outline=LINE, width=2)
    txt(d, (916, 172), "词条属性", font(MSYHBD, 15), fill=INK)
    txt(d, (916, 208), "已", font(SIMSUN, 44), fill=INK)
    txt(d, (966, 218), "yǐ", font(MSYH, 20), fill=MUTED)
    txt(d, (916, 266), "拼音", font(MSYH, 12), fill=MUTED)
    rr(d, (916, 284, 1236, 316), radius=8, fill=(249, 246, 240), outline=LINE, width=1)
    txt(d, (928, 292), "yǐ", font(MSYH, 15), fill=INK)
    txt(d, (916, 332), "词性", font(MSYH, 12), fill=MUTED)
    rr(d, (916, 350, 1010, 382), radius=10, fill=PALE)
    txt(d, (933, 358), "动词", font(MSYH, 14), fill=ACCENT)
    txt(d, (916, 398), "义项（点选可编辑）", font(MSYH, 12), fill=MUTED)
    senses = ["① 停止", "② 已经", "③ 太、过分"]
    y = 420
    for i, s in enumerate(senses):
        rr(d, (916, y, 1236, y + 42), radius=8, fill=CARD, outline=LINE, width=1)
        d.ellipse((928, y + 13, 944, y + 29), outline=GREEN if i == 0 else LINE, width=2)
        if i == 0:
            d.line((931, y + 21, 936, y + 26), fill=GREEN, width=2)
            d.line((936, y + 26, 948, y + 14), fill=GREEN, width=2)
        txt(d, (960, y + 11), s, font(MSYH, 15), fill=INK)
        y += 52
    txt(d, (916, 600), "例句", font(MSYH, 12), fill=MUTED)
    txt(d, (916, 618), "学不可以已", font(SIMSUN, 20), fill=ACCENT)
    txt(d, (916, 660), "标签", font(MSYH, 12), fill=MUTED)
    rr(d, (916, 678, 986, 706), radius=14, fill=(238, 243, 238))
    txt(d, (951, 684), "高频", font(MSYH, 12), fill=GREEN, anchor="mm")
    rr(d, (996, 678, 1096, 706), radius=14, fill=PALE)
    txt(d, (1046, 684), "120 实词", font(MSYH, 12), fill=ACCENT, anchor="mm")

    rr(d, (0, 760, w, h), radius=0, fill=CARD)
    d.line((0, 760, w, 760), fill=LINE, width=2)
    txt(d, (244, 772), "草稿已保存 10:24", font(MSYH, 12), fill=MUTED)
    txt(d, (900, 772), "内容包版本 v2026.10 · 下一步：导出并发送", font(MSYH, 12), fill=MUTED)
    img.save(os.path.join(OUT, "03-老师端编辑器.png"))


if __name__ == "__main__":
    reading_page()
    flashcard()
    teacher_editor()
    classroom()
    print("done ->", OUT)


