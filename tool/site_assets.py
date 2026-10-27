#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sitenin görselleri ve yazı tipleri (site/assets/ altına).

Ekranlar mağaza görselleriyle aynı ham kaynaktan, aynı çerçeve ve şeritle
çiziliyor; site mağazadaki görünümün devamı gibi duruyor:

    flutter test test/gallery/store_screens_test.dart --dart-define=STORE=true
    python3 tool/site_assets.py

Çıktı depoda tutuluyor: sitenin derlemesi (tool/build_site.dart, CI'daki
Pages işi) Flutter'ın ekran testine ve Python'a ihtiyaç duymasın.

    screens/<dil>/<ekran>.webp   çerçeveli iPhone, saydam zemin
    screens/<dil>/ring.webp      ana ekranın halka kartı (ekrandan taşan büyütme)
    og/<dil>.jpg                 bağlantı önizlemesi, 1200×630
    hero-wide.jpg, hero-tall.jpg kahraman alanının zemini: koyu erik, ipek şerit
    fonts/*.woff2                Newsreader ve Plus Jakarta Sans, Latin alt kümesi

Apple Sağlık ekranı (health_sync) bilerek yok: simgesinin lisansı uygulamanın
içiyle sınırlı.
"""

import math
import os
import shutil
import sys

from fontTools import subset
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import store_kit as K  # noqa: E402
import store_screenshots as S  # noqa: E402

OUT = os.path.join(K.ROOT, "site", "assets")

# Sayfadaki sırayla. Sitede telefonlar 260–340 CSS pikseli; 600 piksellik
# ekran 2× ekranlarda keskin kalıyor.
SHOTS = ("home", "calendar", "log_entry", "insights", "assistant", "pregnancy_home", "privacy_security")
SCREEN_W = 600

FONTS = (
    "Newsreader-Medium.ttf",
    "PlusJakartaSans-Regular.ttf",
    "PlusJakartaSans-SemiBold.ttf",
    "PlusJakartaSans-Bold.ttf",
)
# Altı dilin harfleri (Türkçe ı/İ/ğ/ş dahil Latin-1 + Latin Genişletilmiş-A)
# ve tipografik noktalama.
UNICODES = "U+0000-00FF,U+0100-017F,U+0218-021B,U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212"


def save_webp(img, *parts):
    path = os.path.join(OUT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "WEBP", quality=82, method=6)
    return path


def save_jpeg(img, *parts, quality=82):
    path = os.path.join(OUT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.convert("RGB").save(path, "JPEG", quality=quality, optimize=True, progressive=True)
    return path


def screens(lang):
    for shot in SHOTS:
        screen, _ = S.load_raw("iphone", lang, shot)
        save_webp(K.Framed("iphone", screen, SCREEN_W).image, "screens", lang, f"{shot}.webp")

    # Halka kartı, mağazadaki ilk paneldeki büyütmenin aynısı. Sayfada
    # telefonun önüne taşıyor.
    screen, meta = S.load_raw("iphone", lang, "home")
    crop = screen.crop(S.callout_box(screen, meta, S.SPECS["home"]))
    card, _ = K.callout_card(crop, 560, 34)
    save_webp(card, "screens", lang, "ring.webp")


def og_image(lang):
    """Mağazanın başlık görseli (21:9) ortadan 1200×630'a kırpılmış."""
    img = S.header(lang)
    w = round(img.size[0] * 630 / img.size[1])
    img = img.resize((w, 630), Image.LANCZOS)
    x = (w - 1200) // 2
    save_jpeg(img.crop((x, 0, x + 1200, 630)), "og", f"{lang}.jpg", quality=86)


def hero(name, size, ribbon_y, wave, glows):
    w, h = size
    canvas = S.dark_canvas(size, [((w * x, h * y), h * r, color, a) for (x, y), r, color, a in glows])
    K.lotus_watermark(canvas, (w * 0.86, h * 0.26), min(w, h) * 0.55, K.PLUM300, 0.04)
    S.backdrop_silk(canvas, lambda x: h * ribbon_y + h * 0.045 * math.sin(2 * math.pi * x / wave + 0.4),
                    h * 0.05, wave * 0.8, 0.4, dot=round(min(w, h) * 0.016), line_unit=wave * 1.05)
    save_jpeg(canvas, name, quality=80)


def fonts():
    os.makedirs(os.path.join(OUT, "fonts"), exist_ok=True)
    for name in FONTS:
        out = os.path.join(OUT, "fonts", name.replace(".ttf", ".woff2"))
        subset.main([
            os.path.join(K.FONTS, name),
            f"--unicodes={UNICODES}",
            "--layout-features=kern,liga,calt,ccmp,locl,mark,mkmk,case,lnum,tnum",
            "--flavor=woff2",
            f"--output-file={out}",
        ])
    for lic in ("Newsreader-OFL.txt", "PlusJakartaSans-OFL.txt"):
        shutil.copy(os.path.join(K.FONTS, lic), os.path.join(OUT, "fonts", lic))


def main():
    for lang in S.LANGS:
        screens(lang)
        og_image(lang)
        print(f"{lang}: tamam")
    hero("hero-wide.jpg", (2400, 1300), 0.90, 1700, [
        ((0.70, 0.40), 0.75, K.BERRY_LIGHT, 0.50),
        ((0.10, 0.10), 0.85, K.OVULATION, 0.26),
        ((0.92, 0.95), 0.80, K.FERTILE, 0.22),
        ((0.45, 1.05), 0.55, K.PLUM600, 0.50),
    ])
    hero("hero-tall.jpg", (1200, 2100), 0.74, 1300, [
        ((0.70, 0.62), 0.45, K.BERRY_LIGHT, 0.50),
        ((0.10, 0.08), 0.50, K.OVULATION, 0.26),
        ((0.90, 0.95), 0.45, K.FERTILE, 0.22),
        ((0.40, 1.02), 0.35, K.PLUM600, 0.50),
    ])
    fonts()
    total = sum(os.path.getsize(os.path.join(d, f)) for d, _, fs in os.walk(OUT) for f in fs)
    print(f"site/assets: {total / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
