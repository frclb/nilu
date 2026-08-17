#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Uygulama ikonunu üretir: assets/icon/app_icon.png (1024x1024).

Marka: AppColors.primaryLight (#551B26) zemin üzerine açık pembe lotus.
Onboarding ekranındaki lotus motifiyle aynı dili konuşur.

Çalıştırma:
    python3 tool/generate_icon.py
Ardından:
    dart run flutter_launcher_icons
"""

import math
import os

from PIL import Image, ImageDraw

SIZE = 1024
SS = 4  # supersampling — kenarları yumuşatmak için 4x çizip küçültüyoruz
C = SIZE * SS

# Marka renkleri (lib/design_system/app_colors.dart ile aynı)
BG_TOP = (107, 34, 49)      # #6B2231 — primaryLight'ın açık tonu
BG_BOTTOM = (46, 13, 21)    # #2E0D15 — derin bordo
PETAL = (251, 207, 232)     # #FBCFE8 — AppColors.primaryDark
PETAL_SIDE = (226, 166, 194)  # yan yapraklar için biraz koyu ton


def cubic(p0, p1, p2, p3, steps=120):
    """Kübik bezier eğrisini noktalara böler."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = (u ** 3 * p0[0] + 3 * u * u * t * p1[0]
             + 3 * u * t * t * p2[0] + t ** 3 * p3[0])
        y = (u ** 3 * p0[1] + 3 * u * u * t * p1[1]
             + 3 * u * t * t * p2[1] + t ** 3 * p3[1])
        pts.append((x, y))
    return pts


def petal(width, height):
    """Tabanı orijinde, yukarı doğru uzanan yaprak konturu.

    Matematik koordinatlarında (y yukarı): taban (0,0), uç (0, height).
    """
    base = (0.0, 0.0)
    apex = (0.0, height)
    right = cubic(base, (width, height * 0.18), (width * 0.72, height * 0.72), apex)
    left = cubic(apex, (-width * 0.72, height * 0.72), (-width, height * 0.18), base)
    return right + left


def place(points, angle_deg, pivot_x, pivot_y):
    """Yaprağı tabanından döndürür ve ekran koordinatlarına çevirir."""
    a = math.radians(angle_deg)
    cos_a, sin_a = math.cos(a), math.sin(a)
    out = []
    for x, y in points:
        rx = x * cos_a - y * sin_a
        ry = x * sin_a + y * cos_a
        out.append((pivot_x + rx, pivot_y - ry))  # ekranda y aşağı
    return out


def center(polygons, canvas):
    """Tüm şekli tuvale ortalar."""
    xs = [p[0] for poly in polygons for p in poly]
    ys = [p[1] for poly in polygons for p in poly]
    dx = canvas / 2 - (min(xs) + max(xs)) / 2
    dy = canvas / 2 - (min(ys) + max(ys)) / 2
    return [[(x + dx, y + dy) for x, y in poly] for poly in polygons]


def build():
    img = Image.new("RGB", (C, C), BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    # Dikey degrade zemin
    for y in range(C):
        t = y / (C - 1)
        col = tuple(int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3))
        draw.line([(0, y), (C, y)], fill=col)

    cx = C / 2
    base_y = C * 0.62          # yaprakların birleştiği nokta
    h = C * 0.34               # orta yaprak yüksekliği
    w = C * 0.105              # orta yaprak yarı genişliği

    side = [place(petal(w * s, h * s), a, cx, base_y)
            for a, s in ((-58, 0.80), (58, 0.80), (-30, 0.90), (30, 0.90))]
    middle = place(petal(w, h), 0, cx, base_y)

    polys = center(side + [middle], C)
    for poly in polys[:-1]:
        draw.polygon(poly, fill=PETAL_SIDE)
    draw.polygon(polys[-1], fill=PETAL)

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
