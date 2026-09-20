#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Marka lotusunun geometrisi — tek kaynak.

Aynı çiçek iki yerde çiziliyor: uygulama ikonu (`generate_icon.py`) ve
açılış ekranı işareti (`generate_launch_image.py`). Eğriler önce yalnızca
ikon betiğinde duruyordu; ikincisi eklenirken kopyalanmak yerine buraya
alındı, çünkü kopyalanan bir şekil er geç ikiye ayrılır ve iki farklı
çiçek ortaya çıkar.

Renkler burada **yok**: ikon kendi degrade zeminini, açılış ekranı ise
paletin marka tonunu kullanıyor. Ortak olan yalnızca biçim.
"""

import math


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


def lotus_polygons(canvas):
    """Kare tuvale ortalanmış lotus.

    `(yan_yapraklar, orta_yaprak)` döner. Yan yapraklar önce, orta yaprak
    en üste çizilmeli: üst üste binen yapraklar çiçeğe derinlik veriyor.
    """
    cx = canvas / 2
    base_y = canvas * 0.62          # yaprakların birleştiği nokta
    h = canvas * 0.34               # orta yaprak yüksekliği
    w = canvas * 0.105              # orta yaprak yarı genişliği

    side = [place(petal(w * s, h * s), a, cx, base_y)
            for a, s in ((-58, 0.80), (58, 0.80), (-30, 0.90), (30, 0.90))]
    middle = place(petal(w, h), 0, cx, base_y)

    polys = center(side + [middle], canvas)
    return polys[:-1], polys[-1]
