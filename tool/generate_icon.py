#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Uygulama ikonunu üretir: assets/icon/app_icon.png (1024x1024).

Koyu erik degrade zemin üzerine açık pembe lotus. Şeklin kendisi
`lotus.py` içinde; açılış ekranı işareti de aynı eğrileri kullanıyor.

Çalıştırma:
    python3 tool/generate_icon.py
Ardından:
    dart run flutter_launcher_icons
"""

import os

from PIL import Image, ImageDraw

from lotus import lotus_polygons

SIZE = 1024
SS = 4  # supersampling — kenarları yumuşatmak için 4x çizip küçültüyoruz
C = SIZE * SS

# DİKKAT: bu tonlar paletten ÖNCEKİ markadan kalma. `123301b` ("Tasarım
# sistemini yeniden kur: sıcak erik paleti") marka rengini #551B26'dan
# plum700'e (#6B2F55) taşıdı ama bu betiğe ve üretilmiş PNG'lere hiç
# dokunmadı. Yani ana ekrandaki ikon, uygulamanın bugünkü eriğinden biraz
# farklı bir erik.
#
# Düzeltmek ikonun görünüşünü değiştirir, o yüzden kendiliğinden yapılmadı.
# Palete hizalamak için: BG_TOP/BG_BOTTOM'ı plum700'ün ton aralığına,
# PETAL'ı plum300'e (#C79BB4) çekip
#     python3 tool/generate_icon.py && dart run flutter_launcher_icons
BG_TOP = (107, 34, 49)      # #6B2231
BG_BOTTOM = (46, 13, 21)    # #2E0D15
PETAL = (251, 207, 232)     # #FBCFE8
PETAL_SIDE = (226, 166, 194)  # yan yapraklar için biraz koyu ton


def build():
    img = Image.new("RGB", (C, C), BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    # Dikey degrade zemin
    for y in range(C):
        t = y / (C - 1)
        col = tuple(int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3))
        draw.line([(0, y), (C, y)], fill=col)

    side, middle = lotus_polygons(C)
    for poly in side:
        draw.polygon(poly, fill=PETAL_SIDE)
    draw.polygon(middle, fill=PETAL)

    return img.resize((SIZE, SIZE), Image.LANCZOS)


if __name__ == "__main__":
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(root, "assets", "icon")
    os.makedirs(out_dir, exist_ok=True)

    icon = build()
    path = os.path.join(out_dir, "app_icon.png")
    icon.save(path, "PNG")
    print(f"yazildi: {path} ({icon.size[0]}x{icon.size[1]})")

    # Android adaptive icon foreground: şeffaf zemin, güvenli alana sığacak ölçek
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    inner = icon.resize((int(SIZE * 0.62), int(SIZE * 0.62)), Image.LANCZOS).convert("RGBA")
    # Zemini şeffaflaştır: degrade zemin yerine yalnızca lotus kalsın
    mask = Image.new("L", inner.size, 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([0, 0, inner.size[0] - 1, inner.size[1] - 1], fill=255)
    fg.paste(inner, ((SIZE - inner.size[0]) // 2, (SIZE - inner.size[1]) // 2), mask)
    fg_path = os.path.join(out_dir, "app_icon_foreground.png")
    fg.save(fg_path, "PNG")
    print(f"yazildi: {fg_path}")
