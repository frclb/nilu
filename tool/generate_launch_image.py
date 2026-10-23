#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Açılış ekranı varlıklarını üretir (ios/Runner/Assets.xcassets).

Flutter'ın şablonundan gelen açılış ekranı iki şeyi yanlış yapıyordu:
görsel 1x1 saydam bir yer tutucuydu (Xcode her derlemede "default
placeholder icon" diye uyarıyordu) ve zemin storyboard'a **sabit beyaz**
yazılmıştı. Karanlık modda uygulama önce beyaz patlayıp sonra koyuya
geçiyordu; açık temada bile zemin uygulamanınkinden (#FBF8F5) farklıydı.

Buradaki kural: açılış ekranı uygulamanın ilk karesine benzemeli. Zemin
`AppTokens.background`, işaret ise markanın o parlaklıktaki tonu.

Çalıştırma:
    python3 tool/generate_launch_image.py
"""

import json
import os

from PIL import Image, ImageDraw

from lotus import lotus_polygons

# lib/design_system/app_palette.dart ile aynı olmalı; `launch_screen_test.dart`
# ikisini karşılaştırıyor.
SAND_50 = (0xFB, 0xF7, 0xF6)   # AppPalette.sand50   — açık temada zemin
NIGHT_900 = (0x15, 0x0E, 0x12)  # AppPalette.night900 — koyu temada zemin
PLUM_700 = (0x54, 0x19, 0x42)   # AppPalette.plum700  — açık temada marka
ROSE_200 = (0xFB, 0xCF, 0xE8)   # AppPalette.rose200  — koyu temada işaret

# Koyu temada işaret neden `plum300` değil:
#
# İşaretin yan yaprakları %75 saydam çiziliyor. `plum300` gece zeminine
# karışınca #9A788C'ye düşüyor ve biraz sönük duruyordu; `rose200` aynı
# yerde #B99EA5 veriyor — daha canlı, hâlâ pembe. Zemine karşı kontrast da
# 7.86:1'den 12.90:1'e çıkıyor.
#
# `rose50` denendi ve elendi: kontrastı en yüksek (16.67:1) ama yan
# yaprakların doygunluğu %6'ya iniyor, yani işaret gri okunuyor — markanın
# oturması gereken anda rengini kaybediyor.

# İşaretin genişliği (pt). Storyboard görseli kendi doğal boyutunda
# ortalıyor, yani PNG'nin boyutu ekrandaki boyutudur.
WIDTH_PT = 120

# Yan yapraklar biraz geri çekiliyor. İkonda bu, yaprakların farklı pembe
# tonlarıyla yapılıyor; tek renkli işarette aynı derinlik saydamlıkla.
SIDE_ALPHA = 191  # %75

SS = 2048  # maskeyi büyük çizip küçültüyoruz — kenarlar yumuşasın

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets")
IMAGESET = os.path.join(ASSETS, "LaunchImage.imageset")
COLORSET = os.path.join(ASSETS, "LaunchBackground.colorset")

DARK = [{"appearance": "luminosity", "value": "dark"}]


def mark_mask():
    """Lotusu tek kanallı maske olarak çizer, sınırlarına kırpar."""
    mask = Image.new("L", (SS, SS), 0)
    draw = ImageDraw.Draw(mask)
    side, middle = lotus_polygons(SS)
    for poly in side:
        draw.polygon(poly, fill=SIDE_ALPHA)
    draw.polygon(middle, fill=255)
    return mask.crop(mask.getbbox())


def write_images(mask):
    mw, mh = mask.size
    entries = []
    for prefix, rgb, appearances in (
        ("LaunchImage", PLUM_700, None),
        ("LaunchImageDark", ROSE_200, DARK),
    ):
        for scale in (1, 2, 3):
            tw = WIDTH_PT * scale
            th = max(1, round(mh * tw / mw))
            m = mask.resize((tw, th), Image.LANCZOS)
            img = Image.new("RGBA", (tw, th), rgb + (0,))
            img.putalpha(m)
            name = f"{prefix}{'' if scale == 1 else f'@{scale}x'}.png"
            img.save(os.path.join(IMAGESET, name))
            entry = {"idiom": "universal", "filename": name, "scale": f"{scale}x"}
            if appearances:
                entry["appearances"] = appearances
            entries.append(entry)
            print(f"  {name:26s} {tw}x{th}")
    return entries


def components(rgb):
    return {
        "color-space": "srgb",
        "components": {
            "red": f"0x{rgb[0]:02X}",
            "green": f"0x{rgb[1]:02X}",
            "blue": f"0x{rgb[2]:02X}",
            "alpha": "1.000",
        },
    }


def write_json(path, payload):
    with open(path, "w") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")
    print(f"  {os.path.relpath(path, ROOT)}")


if __name__ == "__main__":
    os.makedirs(IMAGESET, exist_ok=True)
    os.makedirs(COLORSET, exist_ok=True)

    info = {"version": 1, "author": "xcode"}

    images = write_images(mark_mask())
    write_json(os.path.join(IMAGESET, "Contents.json"),
               {"images": images, "info": info})
    write_json(os.path.join(COLORSET, "Contents.json"), {
        "colors": [
            {"idiom": "universal", "color": components(SAND_50)},
            {"idiom": "universal", "appearances": DARK,
             "color": components(NIGHT_900)},
        ],
        "info": info,
    })
