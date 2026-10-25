#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Android simge, bildirim simgesi ve açılış ekranı kaynaklarını üretir.

    python3 tool/generate_android_assets.py

Şekil, renkler ve oranlar iOS tarafıyla ortak: lotus `lotus.py`'den, ikon
zemini `generate_icon.py`'den, açılış ekranı renkleri
`generate_launch_image.py`'den geliyor. Böylece iki platformda ikon ve
açılış ekranı aynı çiçek, aynı tonlar.

Üretilenler (android/app/src/main/res):
  mipmap-anydpi-v26/ic_launcher.xml   uyarlanabilir simge (+ tek renkli)
  mipmap-*/ic_launcher_foreground.png lotus, 108 dp tuval, 72 dp görünür alan
  mipmap-*/ic_launcher_monochrome.png Android 13 temalı simge
  mipmap-*/ic_launcher.png            eski başlatıcılar için yuvarlak kare
  drawable/ic_launcher_background.xml ikonun degrade zemini
  drawable-*/ic_stat_nilu.png         bildirim simgesi (beyaz siluet)
  drawable(-night)-*/launch_mark.png  açılış işareti, 120 dp genişlik
  values(-night)/colors.xml           açılış zemini
"""

import os

from PIL import Image, ImageDraw

from generate_icon import BG_BOTTOM, BG_TOP, PETAL, PETAL_SIDE
from generate_icon import build as build_icon
from generate_launch_image import NIGHT_900, PLUM_700, ROSE_200, SAND_50, SIDE_ALPHA, WIDTH_PT
from lotus import lotus_polygons

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

DENSITIES = {"mdpi": 1.0, "hdpi": 1.5, "xhdpi": 2.0, "xxhdpi": 3.0, "xxxhdpi": 4.0}
SS = 4


def _hex(rgb):
    return "#{:02X}{:02X}{:02X}".format(*rgb)


def _write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def _save(img, folder, name):
    path = os.path.join(RES, folder, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG", optimize=True)


def lotus_layer(canvas_px, content_px, side, middle, side_alpha=255):
    """Ortalanmış lotus (RGBA). `content_px`: lotusun çizildiği kare.

    `lotus_polygons` çiçeği kendi tuvalinin içinde ikondaki oranla
    yerleştiriyor; o tuval burada görünür alana denk geliyor.
    """
    big = canvas_px * SS
    inner = content_px * SS
    off = (big - inner) / 2
    sides, mid = lotus_polygons(inner)
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for poly in sides:
        d.polygon([(x + off, y + off) for x, y in poly], fill=side + (side_alpha,))
    d.polygon([(x + off, y + off) for x, y in mid], fill=middle + (255,))
    return img.resize((canvas_px, canvas_px), Image.LANCZOS)


def adaptive_icon():
    # Uyarlanabilir simge: 108 dp tuval, maske ortadaki 72 dp'yi gösteriyor.
    # iOS ikonunun tamamı o 72 dp'ye denk geliyor; lotus aynı oranda kalıyor.
    for folder, k in DENSITIES.items():
        canvas = round(108 * k)
        visible = round(72 * k)
        _save(lotus_layer(canvas, visible, PETAL_SIDE, PETAL), f"mipmap-{folder}", "ic_launcher_foreground.png")
        # Temalı simge: sistem tek renge boyuyor; derinlik saydamlıkla.
        white = (255, 255, 255)
        _save(lotus_layer(canvas, visible, white, white, SIDE_ALPHA), f"mipmap-{folder}",
              "ic_launcher_monochrome.png")
        # Eski başlatıcılar (API 26 altı yok ama bazı yerler PNG'yi okuyor):
        # iOS ikonunun yuvarlatılmış hâli.
        size = round(48 * k)
        icon = build_icon().resize((size * SS, size * SS), Image.LANCZOS).convert("RGBA")
        mask = Image.new("L", icon.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, icon.size[0] - 1, icon.size[1] - 1],
                                               radius=icon.size[0] * 0.22, fill=255)
        icon.putalpha(mask)
        _save(icon.resize((size, size), Image.LANCZOS), f"mipmap-{folder}", "ic_launcher.png")

    _write(os.path.join(RES, "mipmap-anydpi-v26", "ic_launcher.xml"), """<?xml version="1.0" encoding="utf-8"?>
<!-- tool/generate_android_assets.py üretiyor. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
""")
    _write(os.path.join(RES, "drawable", "ic_launcher_background.xml"), f"""<?xml version="1.0" encoding="utf-8"?>
<!-- tool/generate_android_assets.py üretiyor. iOS ikonuyla aynı degrade. -->
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <gradient
        android:angle="270"
        android:startColor="{_hex(BG_TOP)}"
        android:endColor="{_hex(BG_BOTTOM)}"
        android:type="linear" />
</shape>
""")


def notification_icon():
    # Bildirim simgesi: 24 dp, yalnızca alfa (sistem boyuyor). Renkli ikon
    # Android 5+ durum çubuğunda beyaz bir kare olarak görünür.
    white = (255, 255, 255)
    for folder, k in DENSITIES.items():
        canvas = round(24 * k)
        # Lotus kendi tuvalinin yarısı genişliğinde; 38 dp tuval → ~19 dp
        # çiçek, 24 dp'nin içinde iki yanda ~2,5 dp pay.
        _save(lotus_layer(canvas, round(38 * k), white, white, SIDE_ALPHA), f"drawable-{folder}",
              "ic_stat_nilu.png")


def launch_screen():
    # iOS açılış ekranıyla aynı: zemin uygulamanın arka planı, ortada 120 dp
    # genişliğinde lotus; koyu temada koyu zemin ve açık işaret.
    for night, mark_rgb in ((False, PLUM_700), (True, ROSE_200)):
        for folder, k in DENSITIES.items():
            width = round(WIDTH_PT * k)
            layer = lotus_layer(width * 2, width * 2, mark_rgb, mark_rgb, SIDE_ALPHA)
            layer = layer.crop(layer.getbbox())
            h = round(layer.size[1] * width / layer.size[0])
            mark = layer.resize((width, h), Image.LANCZOS)
            _save(mark, f"drawable{'-night' if night else ''}-{folder}", "launch_mark.png")

    for night, rgb in ((False, SAND_50), (True, NIGHT_900)):
        _write(os.path.join(RES, "values-night" if night else "values", "colors.xml"), f"""<?xml version="1.0" encoding="utf-8"?>
<!-- tool/generate_android_assets.py üretiyor. -->
<resources>
    <color name="launch_background">{_hex(rgb)}</color>
</resources>
""")

    launch = """<?xml version="1.0" encoding="utf-8"?>
<!-- tool/generate_android_assets.py üretiyor. Android 11 ve öncesi;
     12+ values-v31/styles.xml'deki sistem açılış ekranını kullanıyor. -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/launch_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/launch_mark" />
    </item>
</layer-list>
"""
    _write(os.path.join(RES, "drawable", "launch_background.xml"), launch)
    _write(os.path.join(RES, "drawable-v21", "launch_background.xml"), launch)

    # Android 12+: sistem açılış ekranı simgeyi 288 dp tuvalin ortasındaki
    # 192 dp'lik daireye kırpıyor; 120 dp'lik işaret oraya sığıyor (lotus
    # kendi tuvalinin ~%46'sı: 258 dp tuval → ~120 dp çiçek).
    for night, mark_rgb in ((False, PLUM_700), (True, ROSE_200)):
        for folder, k in DENSITIES.items():
            canvas = round(288 * k)
            layer = lotus_layer(canvas, round(WIDTH_PT * k * 2.15), mark_rgb, mark_rgb, SIDE_ALPHA)
            _save(layer, f"drawable{'-night' if night else ''}-{folder}", "splash_mark.png")


if __name__ == "__main__":
    adaptive_icon()
    notification_icon()
    launch_screen()
    print(f"yazıldı: {os.path.relpath(RES, ROOT)}")
