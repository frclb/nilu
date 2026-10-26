# -*- coding: utf-8 -*-
"""Mağaza görsellerinin çizim parçaları: renkler, yazı, şekiller, cihazlar.

Kompozisyon `store_screenshots.py`'de; burada yalnızca yeniden kullanılan
yapı taşları var.
"""

import math
import os
import shutil

import numpy as np
from fontTools.ttLib import TTFont
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

from lotus import lotus_polygons

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, "assets", "fonts")

# ---------------------------------------------------------------------------
# Palet — lib/design_system/app_palette.dart ile aynı tonlar.
# ---------------------------------------------------------------------------
PLUM900 = (0x3A, 0x02, 0x2C)
PLUM700 = (0x54, 0x19, 0x42)
PLUM600 = (0x61, 0x18, 0x46)
PLUM300 = (0xFF, 0xAE, 0xDE)
BERRY = (0xB0, 0x27, 0x51)
BERRY_LIGHT = (0xE0, 0x4D, 0x74)
BACKGROUND = (0xFB, 0xF7, 0xF6)
ROSE50 = (0xFF, 0xF0, 0xF6)
LAVENDER = (0xE9, 0xD5, 0xFF)
FLOW = (0xE1, 0x1D, 0x48)
FERTILE = (0xF4, 0x72, 0xB6)
OVULATION = (0x7C, 0x3A, 0xED)
FOLLICULAR = (0x05, 0x96, 0x69)
LUTEAL = (0xD9, 0x77, 0x06)
FRAME = (0x17, 0x10, 0x15)
FRAME_EDGE = (0x4B, 0x3C, 0x46)
DEEP = (0x22, 0x00, 0x1A)  # panoramanın en koyu yeri
WHITE = (255, 255, 255)

# Başlıktaki vurgulu kelimenin degradesi: plum300 → pembe → şeftali.
HIGHLIGHT = ((0xFF, 0xAE, 0xDE), (0xFF, 0x8F, 0xB8), (0xFF, 0xC8, 0xA8))

# Evre renkleri, uygulamadaki halkanın sırasıyla (28 günlük bir döngü).
PHASES = [FLOW] * 5 + [FOLLICULAR] * 8 + [FERTILE] * 5 + [OVULATION] + [FERTILE] + [LUTEAL] * 8

# ---------------------------------------------------------------------------
# Yazı: Pillow'un temel düzeni GPOS kerning'i uygulamıyor ("AV", "Yo",
# "Tu" araları açılıyor). Büyük başlıkta göze batıyor; çiftler yazı tipinin
# kendi tablosundan okunup elle uygulanıyor.
# ---------------------------------------------------------------------------


class Kerning:
    def __init__(self, path):
        font = TTFont(path)
        self.cmap = font.getBestCmap()
        self.upem = font["head"].unitsPerEm
        self.subtables = []
        if "GPOS" not in font:
            return
        gpos = font["GPOS"].table
        ids = set()
        for record in gpos.FeatureList.FeatureRecord:
            if record.FeatureTag == "kern":
                ids.update(record.Feature.LookupListIndex)
        for index in sorted(ids):
            lookup = gpos.LookupList.Lookup[index]
            for sub in lookup.SubTable:
                if lookup.LookupType == 9:
                    if sub.ExtensionLookupType != 2:
                        continue
                    sub = sub.ExtSubTable
                elif lookup.LookupType != 2:
                    continue
                self.subtables.append(self._resolver(sub))

    @staticmethod
    def _x(value):
        return getattr(value, "XAdvance", 0) or 0 if value is not None else 0

    def _resolver(self, sub):
        coverage = {g: i for i, g in enumerate(sub.Coverage.glyphs)}
        if sub.Format == 1:
            sets = {}
            for g, i in coverage.items():
                sets[g] = {r.SecondGlyph: self._x(r.Value1) for r in sub.PairSet[i].PairValueRecord}

            def find(a, b):
                if a not in sets:
                    return None
                return sets[a].get(b)

            return find
        first = sub.ClassDef1.classDefs
        second = sub.ClassDef2.classDefs
        rows = sub.Class1Record

        def find(a, b):
            if a not in coverage:
                return None
            return self._x(rows[first.get(a, 0)].Class2Record[second.get(b, 0)].Value1)

        return find

    def pair(self, a, b):
        ga, gb = self.cmap.get(ord(a)), self.cmap.get(ord(b))
        if ga is None or gb is None:
            return 0
        for find in self.subtables:
            value = find(ga, gb)
            if value is not None:
                return value
        return 0


class Face:
    """Bir yazı tipi dosyası; her boyut için önbellekli."""

    def __init__(self, filename):
        self.path = os.path.join(FONTS, filename)
        self.kerning = Kerning(self.path)
        self._sizes = {}

    def at(self, size):
        size = int(round(size))
        if size not in self._sizes:
            self._sizes[size] = ImageFont.truetype(self.path, size)
        return self._sizes[size]

    def layout(self, text, size, tracking=0.0):
        """Her harfin x konumu ve satır genişliği."""
        font = self.at(size)
        xs, x = [], 0.0
        for i, ch in enumerate(text):
            xs.append(x)
            x += font.getlength(ch) + tracking * size
            if i + 1 < len(text):
                x += self.kerning.pair(ch, text[i + 1]) * size / self.kerning.upem
        if text:
            x -= tracking * size
        return xs, x

    def width(self, text, size, tracking=0.0):
        return self.layout(text, size, tracking)[1]

    def draw(self, draw, x, baseline, text, size, fill, tracking=0.0):
        font = self.at(size)
        xs, _ = self.layout(text, size, tracking)
        for ch, dx in zip(text, xs):
            draw.text((x + dx, baseline), ch, font=font, fill=fill, anchor="ls")

    def fit(self, lines, size, max_width, tracking=0.0):
        """En geniş satır sığana kadar küçültülmüş boyut."""
        widest = max(self.width(line, size, tracking) for line in lines)
        return size if widest <= max_width else size * max_width / widest


SERIF = Face("Newsreader-Medium.ttf")
SERIF_BOLD = Face("Newsreader-SemiBold.ttf")
SANS_BOLD = Face("PlusJakartaSans-ExtraBold.ttf")
SANS = Face("PlusJakartaSans-SemiBold.ttf")
SANS_STRONG = Face("PlusJakartaSans-Bold.ttf")


def status_font(size):
    """iOS durum çubuğu saati: SF Pro Semibold; yoksa uygulamanın yazısı."""
    path = "/System/Library/Fonts/SFNS.ttf"
    if not os.path.exists(path):
        return SANS.at(size)
    font = ImageFont.truetype(path, int(round(size)))
    font.set_variation_by_axes([100, 18, 400, 590])
    return font


# ---------------------------------------------------------------------------
# Çizim yardımcıları
# ---------------------------------------------------------------------------

SS = 3  # şekil maskeleri için örnekleme katı: kenarlar yumuşak kalsın


def rounded_mask(size, radius):
    w, h = size
    big = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        [0, 0, w * SS - 1, h * SS - 1], radius=radius * SS, fill=255
    )
    return big.resize((w, h), Image.LANCZOS)


def shape_layer(size, painter):
    """`painter(draw, ss)` ile örneklemeli çizilmiş bir maske."""
    w, h = size
    big = Image.new("L", (w * SS, h * SS), 0)
    painter(ImageDraw.Draw(big), SS)
    return big.resize((w, h), Image.LANCZOS)


def glow(canvas, center, radius, color, alpha):
    """Yumuşak renk ışığı. Küçük tuvalde çizilip büyütülüyor: hızlı ve pürüzsüz."""
    w, h = canvas.size
    k = 8
    small = Image.new("L", (max(1, w // k), max(1, h // k)), 0)
    cx, cy = center[0] / k, center[1] / k
    r = radius / k
    ImageDraw.Draw(small).ellipse([cx - r, cy - r, cx + r, cy + r], fill=int(255 * alpha))
    small = small.filter(ImageFilter.GaussianBlur(r * 0.55))
    mask = small.resize((w, h), Image.BICUBIC)
    canvas.paste(Image.new("RGB", (w, h), color), (0, 0), mask)


def vertical_gradient(size, top, bottom):
    w, h = size
    column = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        column.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return column.resize((w, h))


def lotus_watermark(canvas, center, size, color, alpha):
    """Arka planda belli belirsiz marka çiçeği."""
    size = int(size)
    side, middle = lotus_polygons(size * SS)
    big = Image.new("L", (size * SS, size * SS), 0)
    d = ImageDraw.Draw(big)
    for poly in side + [middle]:
        d.polygon(poly, fill=int(255 * alpha))
    mask = big.resize((size, size), Image.LANCZOS)
    canvas.paste(
        Image.new("RGB", (size, size), color),
        (int(center[0] - size / 2), int(center[1] - size / 2)),
        mask,
    )


def lotus_mark(size, side_color=PLUM300, middle_color=ROSE50):
    """Saydam zeminli lotus (RGBA)."""
    size = int(size)
    side, middle = lotus_polygons(size * SS)
    img = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for poly in side:
        d.polygon(poly, fill=side_color + (255,))
    d.polygon(middle, fill=middle_color + (255,))
    return img.resize((size, size), Image.LANCZOS)


# ---------------------------------------------------------------------------
# Durum çubukları. Ölçüler simülatördeki iPhone 17 Pro Max'ten (3×) alındı;
# glifler çizilerek üretiliyor, Apple'ın görseli depoda tutulmuyor.
# ---------------------------------------------------------------------------


def _ios_glyphs(draw, ox, oy, k, color, signal=True):
    """Sinyal, Wi-Fi ve pil. (ox, oy) grubun sol üstü; k = piksel/pt × SS.

    `signal=False`: Wi-Fi'li iPad; grup sinyalin genişliği kadar kısalıyor.
    """
    if not signal:
        ox -= 30 * k

    def r(x0, y0, x1, y1, rad, fill):
        draw.rounded_rectangle(
            [ox + x0 * k, oy + y0 * k, ox + x1 * k, oy + y1 * k], radius=rad * k, fill=fill
        )

    # Sinyal: 4 çubuk, 3,67 pt geniş, 6 pt aralık; tabanlar hizalı.
    for i, top in enumerate((11.7, 9.3, 6.3, 3.3) if signal else ()):
        x = 3 + i * 6
        r(x, top, x + 3.67, 16.7, 1.1, color)

    # Wi-Fi: tabandaki noktadan açılan üç yay, ±45°. Yaylar halka dilimi
    # olarak çiziliyor; uçları yuvarlak.
    cx, cy = ox + 41.7 * k, oy + 16.9 * k
    for inner, outer in ((0, 4.6), (6.0, 9.4), (10.8, 14.2)):
        if inner == 0:
            draw.pieslice(
                [cx - outer * k, cy - outer * k, cx + outer * k, cy + outer * k],
                start=225, end=315, fill=color,
            )
            continue
        cap = (outer - inner) / 2 * k
        mid = (inner + outer) / 2 * k
        # Yuvarlak uç yayın içinde kalsın diye dilim biraz kısa.
        sweep = math.degrees(cap / mid)
        a0, a1 = 225 + sweep, 315 - sweep
        steps = 64
        ring = [(cx + outer * k * math.cos(math.radians(a0 + (a1 - a0) * i / steps)),
                 cy + outer * k * math.sin(math.radians(a0 + (a1 - a0) * i / steps)))
                for i in range(steps + 1)]
        ring += [(cx + inner * k * math.cos(math.radians(a1 - (a1 - a0) * i / steps)),
                  cy + inner * k * math.sin(math.radians(a1 - (a1 - a0) * i / steps)))
                 for i in range(steps + 1)]
        draw.polygon(ring, fill=color)
        for a in (a0, a1):
            px = cx + mid * math.cos(math.radians(a))
            py = cy + mid * math.sin(math.radians(a))
            draw.ellipse([px - cap, py - cap, px + cap, py + cap], fill=color)

    # Pil: gri çerçeve, dolu gövde, uçta küçük çıkıntı.
    grey = int(color * 0.4)
    r(59, 3, 87.3, 17, 4.3, grey)
    r(60.2, 4.2, 86.1, 15.8, 3.4, 0)
    r(61.4, 5.4, 84.9, 14.6, 2.6, color)
    r(88.3, 7.7, 90, 12.3, 0.8, grey)


def ios_phone_status(screen, ratio, ink=(0, 0, 0)):
    """iPhone durum çubuğu ve Dynamic Island; ekran görüntüsüne çizilir.

    `ink`: saat ve simgelerin rengi; koyu duvar kâğıdında beyaz.
    """
    w = screen.size[0]
    pt = ratio

    def paint(d, ss):
        k = pt * ss
        # Dynamic Island: 125 × 36,7 pt, üstten 14 pt.
        d.rounded_rectangle(
            [(w / pt / 2 - 62.5) * k, 14 * k, (w / pt / 2 + 62.5) * k, 50.3 * k],
            radius=18.35 * k, fill=255,
        )

    island = shape_layer(screen.size, paint)
    screen.paste((0, 0, 0), (0, 0), island)

    # Glifler alfa maskesi olarak; gri tonlar maskedeki ara değerler.
    def glyphs(d, ss):
        _ios_glyphs(d, (w / pt - 130.7) * pt * ss, 22 * pt * ss, pt * ss, 255)

    mask = shape_layer(screen.size, glyphs)
    screen.paste(ink, (0, 0), mask)

    d = ImageDraw.Draw(screen)
    font = status_font(18 * pt)
    d.text((82.8 * pt, 39 * pt), "9:41", font=font, fill=ink, anchor="ms")


def ios_pad_status(screen, ratio, ink=(0, 0, 0)):
    """iPad durum çubuğu: solda saat, sağda Wi-Fi ve pil."""
    w = screen.size[0]
    pt = ratio
    scale = 0.82  # iPad glifleri telefonunkinden küçük

    def glyphs(d, ss):
        k = pt * ss * scale
        ox = (w / pt - 22 - 90 * scale) * pt * ss
        oy = 4.5 * pt * ss
        _ios_glyphs(d, ox, oy, k, 255, signal=False)

    mask = shape_layer(screen.size, glyphs)
    screen.paste(ink, (0, 0), mask)
    d = ImageDraw.Draw(screen)
    font = status_font(15 * pt)
    d.text((24 * pt, 17.5 * pt), "9:41", font=font, fill=ink, anchor="ls")


def android_status(screen, ratio, camera=True, ink=(0x1D, 0x1B, 0x20)):
    """Android durum çubuğu: solda saat, sağda Wi-Fi, sinyal, pil.

    `ink`: simge ve saat rengi; koyu duvar kâğıdında açık.
    """
    w = screen.size[0]
    dp = ratio
    bar = 40 if camera else 28
    cy = bar / 2

    def paint(d, ss):
        k = dp * ss
        right = w / dp - 20
        # Pil: dikey, dolu.
        d.rounded_rectangle([(right - 8) * k, (cy - 8) * k, right * k, (cy + 8) * k], radius=1.6 * k, fill=255)
        d.rectangle([(right - 5.5) * k, (cy - 9.5) * k, (right - 2.5) * k, (cy - 8) * k], fill=255)
        # Sinyal: dik üçgen.
        sx = right - 14
        d.polygon([((sx) * k, (cy - 7.5) * k), (sx * k, (cy + 7.5) * k), ((sx - 15) * k, (cy + 7.5) * k)], fill=255)
        # Wi-Fi: dolu çeyrek daire.
        wx = sx - 21 - 9
        d.pieslice([(wx - 9) * k, (cy - 6) * k, (wx + 9) * k, (cy + 12) * k], start=225, end=315, fill=255)
        if camera:
            d.ellipse([(w / dp / 2 - 6.5) * k, (cy - 6.5) * k, (w / dp / 2 + 6.5) * k, (cy + 6.5) * k], fill=255)

    mask = shape_layer(screen.size, paint)
    screen.paste(ink, (0, 0), mask)
    if camera:
        # Kamera deliği siyah, simgeler koyu gri.
        def hole(d, ss):
            k = dp * ss
            d.ellipse([(w / dp / 2 - 6.5) * k, (cy - 6.5) * k, (w / dp / 2 + 6.5) * k, (cy + 6.5) * k], fill=255)

        screen.paste((0, 0, 0), (0, 0), shape_layer(screen.size, hole))
    d = ImageDraw.Draw(screen)
    d.text((24 * dp, (cy + 5) * dp), "9:41", font=roboto(14 * dp), fill=ink, anchor="ls")




# ---------------------------------------------------------------------------
# Flutter SDK'dan gelen yazı tipleri: Material simgeleri ve Roboto.
# ---------------------------------------------------------------------------


def _flutter_fonts():
    flutter = shutil.which("flutter")
    if not flutter:
        return None
    root = os.path.dirname(os.path.dirname(os.path.realpath(flutter)))
    path = os.path.join(root, "bin", "cache", "artifacts", "material_fonts")
    return path if os.path.isdir(path) else None


_MATERIAL = _flutter_fonts()


def roboto(size):
    """Android durum çubuğu saati; Roboto yoksa uygulamanın yazısı."""
    if _MATERIAL and os.path.exists(os.path.join(_MATERIAL, "Roboto-Medium.ttf")):
        return ImageFont.truetype(os.path.join(_MATERIAL, "Roboto-Medium.ttf"), int(round(size)))
    return SANS.at(size)


# Material simgeleri — kod noktaları Flutter'ın `Icons` sınıfından.
ICON_NO_ACCOUNTS = "\ue431"
ICON_SHIELD = "\uf379"
ICON_LOCK = "\ue3ae"


def icon_font(size):
    if not _MATERIAL:
        raise SystemExit("Material simge yazı tipi bulunamadı (flutter PATH'te mi?)")
    return ImageFont.truetype(os.path.join(_MATERIAL, "MaterialIcons-Regular.otf"), int(round(size)))


# ---------------------------------------------------------------------------
# Doku, degrade, zengin yazı
# ---------------------------------------------------------------------------


def grain(img, amount=7.0, seed=11):
    """İnce film greni: düz degradeler "dijital" görünmesin."""
    tile = 512
    rng = np.random.default_rng(seed)
    noise = rng.normal(128, amount, (tile, tile)).clip(0, 255).astype("uint8")
    tile_img = Image.fromarray(noise, "L")
    w, h = img.size
    layer = Image.new("L", (w, h))
    for y in range(0, h, tile):
        for x in range(0, w, tile):
            layer.paste(tile_img, (x, y))
    return ImageChops.overlay(img.convert("RGB"), layer.convert("RGB"))


def horizontal_gradient(size, stops):
    """Eşit aralıklı renk duraklarıyla yatay degrade."""
    w, h = size
    row = Image.new("RGB", (max(2, w), 1))
    n = len(stops) - 1
    for x in range(max(2, w)):
        t = x / max(1, w - 1) * n
        i = min(int(t), n - 1)
        f = t - i
        a, b = stops[i], stops[i + 1]
        row.putpixel((x, 0), tuple(int(a[k] + (b[k] - a[k]) * f) for k in range(3)))
    return row.resize((w, h))


def parse_marked(line):
    """"Döngünü *bir bakışta* gör" → [(metin, vurgulu mu), …]."""
    parts = line.split("*")
    return [(part, i % 2 == 1) for i, part in enumerate(parts) if part]


def marked_width(face, line, size, tracking=0.0):
    return face.width(line.replace("*", ""), size, tracking)


def draw_marked(canvas, face, x, baseline, line, size, color, stops=HIGHLIGHT):
    """Bir satır yazı; `*…*` arası degradeyle. Kerning satırın tamamında."""
    plain = line.replace("*", "")
    flags = []
    on = False
    for ch in line:
        if ch == "*":
            on = not on
            continue
        flags.append(on)
    font = face.at(size)
    xs, total = face.layout(plain, size)
    d = ImageDraw.Draw(canvas)
    mask = None
    for ch, dx, hl in zip(plain, xs, flags):
        if hl:
            if mask is None:
                mask = Image.new("L", canvas.size, 0)
            ImageDraw.Draw(mask).text((x + dx, baseline), ch, font=font, fill=255, anchor="ls")
        else:
            d.text((x + dx, baseline), ch, font=font, fill=color, anchor="ls")
    if mask is not None:
        box = mask.getbbox()
        if box:
            grad = horizontal_gradient((box[2] - box[0], box[3] - box[1]), stops)
            canvas.paste(grad, box[:2], mask.crop(box))
    return total


def fit_marked(face, lines, size, max_width):
    widest = max(marked_width(face, line, size) for line in lines)
    return size if widest <= max_width else size * max_width / widest


# ---------------------------------------------------------------------------
# Gölge, cam, döndürme
# ---------------------------------------------------------------------------


def shadow(canvas, mask, pos, strength=0.55, blur=0.05, drop=0.035, color=(0x12, 0x00, 0x0E)):
    """Yumuşak gölge: maske bulanıklaştırılıp aşağı kaydırılıyor."""
    w, h = mask.size
    radius = max(w, h) * blur
    pad = int(radius * 3)
    small = 4
    layer = Image.new("L", ((w + 2 * pad) // small + 1, (h + 2 * pad) // small + 1), 0)
    layer.paste(mask.resize((max(1, w // small), max(1, h // small))).point(lambda v: int(v * strength)),
                (pad // small, pad // small))
    layer = layer.filter(ImageFilter.GaussianBlur(radius / small))
    layer = layer.resize((w + 2 * pad, h + 2 * pad), Image.BICUBIC)
    canvas.paste(color, (int(pos[0] - pad), int(pos[1] - pad + max(w, h) * drop)), layer)


def rotate_point(point, size_before, size_after, angle):
    """`Image.rotate(angle, expand=True)` sonrası bir noktanın yeni yeri."""
    a = math.radians(angle)
    dx = point[0] - size_before[0] / 2
    dy = point[1] - size_before[1] / 2
    return (
        size_after[0] / 2 + math.cos(a) * dx + math.sin(a) * dy,
        size_after[1] / 2 - math.sin(a) * dx + math.cos(a) * dy,
    )


def glass(canvas, box, radius, tint=WHITE, alpha=0.14, border=0.30, blur=28):
    """Buzlu cam: arkası bulanık, üstü yarı saydam, ince kenarlı."""
    x0, y0, x1, y1 = [int(round(v)) for v in box]
    w, h = x1 - x0, y1 - y0
    mask = rounded_mask((w, h), radius)
    behind = canvas.crop((x0, y0, x1, y1)).filter(ImageFilter.GaussianBlur(blur))
    canvas.paste(behind, (x0, y0), mask)
    canvas.paste(tint, (x0, y0), mask.point(lambda v: int(v * alpha)))
    edge = max(2, int(h * 0.025))
    inner = Image.new("L", (w, h), 0)
    inner.paste(rounded_mask((w - 2 * edge, h - 2 * edge), max(1, radius - edge)), (edge, edge))
    ring = ImageChops.subtract(mask, inner)
    canvas.paste(WHITE, (x0, y0), ring.point(lambda v: int(v * border)))


# ---------------------------------------------------------------------------
# Cihaz çerçeveleri: titanyum kenar, siyah çerçeve, yan düğmeler.
# ---------------------------------------------------------------------------

# ratio: ham ekranın piksel oranı; radius: ekran köşesi (pt);
# bezel/rim: ekran genişliğinin oranı; buttons: (taraf, başlangıç, bitiş)
# yüksekliğin oranı olarak.
DEVICES = {
    "iphone": dict(
        ratio=3, radius=55, bezel=0.026, rim=0.011, metal=((0xC9, 0xBC, 0xC4), (0x5A, 0x4B, 0x55)),
        buttons=(("l", 0.165, 0.205), ("l", 0.245, 0.315), ("l", 0.335, 0.405), ("r", 0.27, 0.38)),
        status=ios_phone_status,
    ),
    "ipad": dict(
        ratio=2, radius=18, bezel=0.028, rim=0.008, metal=((0xC2, 0xB8, 0xBE), (0x5E, 0x52, 0x5A)),
        buttons=(("t", 0.80, 0.88), ("r", 0.10, 0.16), ("r", 0.17, 0.23)),
        status=ios_pad_status,
    ),
    "android": dict(
        ratio=3, radius=30, bezel=0.022, rim=0.010, metal=((0x6E, 0x66, 0x6C), (0x24, 0x1E, 0x23)),
        buttons=(("r", 0.20, 0.30), ("r", 0.33, 0.38)),
        status=android_status,
    ),
    "android_tablet": dict(
        ratio=2, radius=18, bezel=0.030, rim=0.007, metal=((0x6E, 0x66, 0x6C), (0x24, 0x1E, 0x23)),
        buttons=(("t", 0.12, 0.20), ("r", 0.12, 0.18)),
        status=lambda s, r: android_status(s, r, camera=False),
    ),
}


class Framed:
    """Çerçeveli cihaz: görüntü (RGBA), gölge maskesi ve ekranın yeri."""

    def __init__(self, device, screen, screen_width):
        spec = DEVICES[device]
        self.scale = screen_width / screen.size[0]
        sw, sh = int(round(screen_width)), int(round(screen.size[1] * self.scale))
        bezel = max(5, int(round(sw * spec["bezel"])))
        rim = max(3, int(round(sw * spec["rim"])))
        button = max(3, int(round(sw * 0.009)))
        radius = spec["radius"] * spec["ratio"] * self.scale
        body_w, body_h = sw + 2 * (bezel + rim), sh + 2 * (bezel + rim)
        pad = button
        img = Image.new("RGBA", (body_w + 2 * pad, body_h + 2 * pad), (0, 0, 0, 0))

        light, dark = spec["metal"]
        metal = vertical_gradient((body_w + 2 * pad, body_h + 2 * pad), light, dark)
        # Kenara çapraz bir parıltı: düz gri yerine metal gibi dursun.
        glint = horizontal_gradient(metal.size, (dark, light, dark, light, dark))
        metal = Image.blend(metal, glint, 0.35)

        # Yan düğmeler gövdenin dışına taşıyor.
        knobs = Image.new("L", img.size, 0)
        kd = ImageDraw.Draw(knobs)
        for side, a, b in spec["buttons"]:
            if side in "lr":
                y0, y1 = pad + body_h * a, pad + body_h * b
                x0 = 0 if side == "l" else pad + body_w - button
                kd.rounded_rectangle([x0, y0, x0 + button * 2, y1], radius=button, fill=255)
            else:
                x0, x1 = pad + body_w * a, pad + body_w * b
                kd.rounded_rectangle([x0, 0, x1, button * 2], radius=button, fill=255)
        img.paste(metal, (0, 0), knobs)

        body = rounded_mask((body_w, body_h), radius + bezel + rim)
        img.paste(metal.crop((pad, pad, pad + body_w, pad + body_h)), (pad, pad), body)
        inner_r = radius + bezel
        inner = rounded_mask((body_w - 2 * rim, body_h - 2 * rim), inner_r)
        img.paste((0x0B, 0x07, 0x0A, 255), (pad + rim, pad + rim), inner)
        # Metalin iç kenarında ince ışık.
        hl = Image.new("L", (body_w - 2 * rim, body_h - 2 * rim), 0)
        hl_inner = rounded_mask((body_w - 2 * rim - 4, body_h - 2 * rim - 4), inner_r - 2)
        hl.paste(inner, (0, 0))
        hl.paste(0, (2, 2), hl_inner)
        img.paste((255, 255, 255, 255), (pad + rim, pad + rim), hl.point(lambda v: int(v * 0.18)))

        self.screen_origin = (pad + rim + bezel, pad + rim + bezel)
        inner_screen = screen.resize((sw, sh), Image.LANCZOS)
        img.paste(inner_screen, self.screen_origin, rounded_mask((sw, sh), radius))

        self.image = img
        self.mask = Image.new("L", img.size, 0)
        self.mask.paste(body, (pad, pad))
        self.mask = ImageChops.lighter(self.mask, knobs)

    def to_canvas(self, raw_point):
        """Ham ekrandaki bir piksel → çerçeveli görüntüdeki yeri."""
        return (
            self.screen_origin[0] + raw_point[0] * self.scale,
            self.screen_origin[1] + raw_point[1] * self.scale,
        )


def place_device(canvas, framed, center, angle, shadow_strength=0.6):
    """Cihazı döndürüp merkezine yerleştirir; ham→tuval eşlemesini döndürür."""
    img, mask = framed.image, framed.mask
    before = img.size
    if angle:
        img = img.rotate(angle, resample=Image.BICUBIC, expand=True)
        mask = mask.rotate(angle, resample=Image.BICUBIC, expand=True)
    pos = (center[0] - img.size[0] / 2, center[1] - img.size[1] / 2)
    shadow(canvas, mask, pos, strength=shadow_strength)
    canvas.paste(img, (int(round(pos[0])), int(round(pos[1]))), img)

    def mapper(raw_point):
        p = framed.to_canvas(raw_point)
        q = rotate_point(p, before, img.size, angle)
        return (pos[0] + q[0], pos[1] + q[1])

    return mapper


def callout_card(crop, width, radius, border_alpha=0.65):
    """Ekrandan büyütülmüş öğe: yuvarlak köşe, ince açık kenar."""
    scale = width / crop.size[0]
    w, h = int(round(width)), int(round(crop.size[1] * scale))
    img = crop.resize((w, h), Image.LANCZOS).convert("RGBA")
    mask = rounded_mask((w, h), radius)
    edge = max(2, int(w * 0.004))
    inner = Image.new("L", (w, h), 0)
    inner.paste(rounded_mask((w - 2 * edge, h - 2 * edge), max(1, radius - edge)), (edge, edge))
    ring = ImageChops.subtract(mask, inner)
    img.paste((255, 255, 255, 255), (0, 0), ring.point(lambda v: int(v * border_alpha)))
    img.putalpha(mask)
    return img, mask
