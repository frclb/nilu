# -*- coding: utf-8 -*-
"""App Store ekran görüntülerini kurar.

Kareler tek bir yatay degradeden kesiliyor: mağazada kaydırırken zemin
kesintisiz akıyor, set tek bir şey gibi okunuyor. Başlıklar uygulamanın
kendi yazı tipleriyle — Fraunces başlık, Inter alt satır — yani mağazadaki
ses uygulamanınkiyle aynı.

Ham kareler simülatörden alınıyor:

    xcrun simctl io <device> screenshot scratch/shots/<cihaz>_<ekran>.png

`<ekran>` aşağıdaki `frames` listesindeki anahtar olmalı; sıra oradaki
anlatıyı izliyor (anla -> kaydet -> gör -> öğren -> derinleş).

Ham kareyi almadan önce durum çubuğunu sabitleyin, yoksa her görüntüde
başka bir saat ve pil çıkar:

    xcrun simctl status_bar <device> override --time "9:41" \
      --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3

**Reklam bandına dikkat.** Kütüphane ve makale ekranlarında `AdBanner` var
ve gerçek AdMob kimlikleri bağlanana kadar üstünde "Test mode" yazıyor.
Telefonda liste uzun olduğu için bant ilk ekranda görünmüyor; tablette
geniş düzen yüzünden görünüyor ve o kare sete alınamaz.

Çalıştırma:
    python3 tool/store_screenshots.py phone 1320 2868
    python3 tool/store_screenshots.py pad   2064 2752
"""
import os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = '/Users/furkan/Desktop/RCApp'
FR = os.path.join(ROOT, 'assets/fonts/Fraunces-Bold.ttf')
IN = os.path.join(ROOT, 'assets/fonts/Inter-Medium.ttf')

# Degradenin durakları — koyudan erik'e, hep aynı ailede.
STOPS = [(0x24, 0x0F, 0x1C), (0x3E, 0x1B, 0x33), (0x55, 0x24, 0x43), (0x6B, 0x2F, 0x55)]
CREAM = (0xFB, 0xF8, 0xF5)
ROSE  = (0xF0, 0xCD, 0xD5)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def stop_at(t):
    """Degradenin t (0..1) konumundaki rengi."""
    n = len(STOPS) - 1
    i = min(int(t * n), n - 1)
    return lerp(STOPS[i], STOPS[i + 1], t * n - i)


def panel(w, h, index, count):
    """Kareyi zemin degradesiyle doldurur (yatayda süreklilik, dikeyde derinlik)."""
    img = Image.new('RGB', (w, h))
    px = img.load()
    for x in range(w):
        # Yatay konum: bütün setin içindeki yeri
        t = (index * w + x) / (count * w - 1)
        top = stop_at(t)
        # Dikeyde hafifçe koyulaşıyor: tek renk düz durur.
        bot = tuple(round(c * 0.72) for c in top)
        for y in range(h):
            px[x, y] = lerp(top, bot, y / (h - 1))
    return img


def glow(img, cx, cy, r, color, strength=70):
    """Cihazın arkasına yumuşak ışık."""
    layer = Image.new('RGB', img.size, (0, 0, 0))
    ImageDraw.Draw(layer).ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(r * 0.45))
    return Image.blend(img, Image.blend(img, layer, 1.0), strength / 255)


def rounded(im, radius):
    mask = Image.new('L', (im.width * 2, im.height * 2), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, im.width * 2 - 1, im.height * 2 - 1], radius=radius * 2, fill=255)
    mask = mask.resize(im.size, Image.LANCZOS)
    out = im.convert('RGBA')
    out.putalpha(mask)
    return out


def wrap(draw, text, font, max_w):
    words, lines, cur = text.split(), [], ''
    for word in words:
        trial = f'{cur} {word}'.strip()
        if draw.textlength(trial, font=font) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def build(shot_path, out_path, index, count, headline, subline, size):
    W, H = size
    canvas = panel(W, H, index, count)

    shot = Image.open(shot_path).convert('RGB')
    # Cihaz karenin %78'i; altı taşarak kesiliyor — mağaza setlerinin dili.
    # Tablette gövde daha kare olduğu için biraz daha dar tutuluyor, yoksa
    # başlığa yer kalmıyor.
    dw = round(W * (0.72 if H / W < 1.6 else 0.78))
    dh = round(shot.height * dw / shot.width)
    shot = shot.resize((dw, dh), Image.LANCZOS)

    dx = (W - dw) // 2
    dy = round(H * 0.335)

    canvas = glow(canvas, W // 2, dy + dh // 3, round(W * 0.62), (0x8E, 0x45, 0x71), 60)

    # Gölge
    radius = round(dw * 0.085)
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [dx, dy + 18, dx + dw, dy + dh], radius=radius, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(38))
    canvas = Image.alpha_composite(canvas.convert('RGBA'), shadow)

    device = rounded(shot, radius)
    canvas.alpha_composite(device, (dx, dy))

    # İnce kenar: cam hissi
    edge = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(edge).rounded_rectangle(
        [dx, dy, dx + dw, dy + dh], radius=radius,
        outline=(255, 255, 255, 46), width=max(2, W // 660))
    canvas = Image.alpha_composite(canvas, edge)

    draw = ImageDraw.Draw(canvas)
    title_size = round(W * 0.073)
    sub_size = round(W * 0.034)
    f_title = ImageFont.truetype(FR, title_size)
    f_sub = ImageFont.truetype(IN, sub_size)

    margin = round(W * 0.09)
    y = round(H * 0.085)
    for line in wrap(draw, headline, f_title, W - margin * 2):
        draw.text((W / 2, y), line, font=f_title, fill=CREAM, anchor='ma')
        y += round(title_size * 1.18)

    y += round(H * 0.012)
    for line in wrap(draw, subline, f_sub, W - margin * 2):
        draw.text((W / 2, y), line, font=f_sub, fill=ROSE + (215,), anchor='ma')
        y += round(sub_size * 1.45)

    canvas.convert('RGB').save(out_path, 'PNG')
    return out_path


# Anlatı her dilde aynı: anla -> kaydet -> gör -> öğren -> derinleş.
# Hitap biçimi uygulamanın çeviri dosyalarını izliyor: de/es/fr senli,
# tr ve pt sizli konuşuyor.
ORDER = ['home', 'log', 'calendar', 'insights', 'library']

CAPTIONS = {
    'tr': {
        'home':     ('Döngünü bir bakışta anla', 'Bugün kaçıncı gündesin, sırada ne var'),
        'log':      ('Nasıl hissettiğini kaydet', 'Akış, belirti, ağrı — birkaç dokunuşta'),
        'calendar': ('Takvimde yerini gör', 'Geçmiş günler ve önündeki tahminler'),
        'insights': ('Örüntüler kendini gösterir', 'Döngü uzunluğun ve belirtilerinin seyri'),
        'library':  ('Bilgi, kaynağıyla birlikte', 'NHS ve Office on Women’s Health referanslı'),
    },
    'en': {
        'home':     ('Understand your cycle at a glance', 'Which day you’re on, and what comes next'),
        'log':      ('Log how you feel', 'Flow, symptoms, pain — in a few taps'),
        'calendar': ('See where you are', 'Past days and the predictions ahead'),
        'insights': ('Patterns start to show', 'Your cycle length and how symptoms track'),
        'library':  ('Knowledge, with its sources', 'Referenced to NHS and Office on Women’s Health'),
    },
    'de': {
        'home':     ('Deinen Zyklus auf einen Blick', 'An welchem Tag du bist und was kommt'),
        'log':      ('Halte fest, wie du dich fühlst', 'Blutung, Symptome, Schmerz — mit wenigen Tipps'),
        'calendar': ('Sieh, wo du gerade stehst', 'Vergangene Tage und die kommenden Prognosen'),
        'insights': ('Muster werden sichtbar', 'Deine Zykluslänge und der Verlauf der Symptome'),
        'library':  ('Wissen mit Quellenangabe', 'Mit Verweis auf NHS und Office on Women’s Health'),
    },
    'es': {
        'home':     ('Entiende tu ciclo de un vistazo', 'En qué día estás y qué viene después'),
        'log':      ('Anota cómo te sientes', 'Flujo, síntomas, dolor — en unos toques'),
        'calendar': ('Mira dónde estás', 'Días pasados y las predicciones por venir'),
        'insights': ('Los patrones se revelan', 'La duración de tu ciclo y el curso de tus síntomas'),
        'library':  ('Información con sus fuentes', 'Con referencias al NHS y a Office on Women’s Health'),
    },
    'fr': {
        'home':     ('Comprends ton cycle d’un coup d’œil', 'Le jour où tu en es et ce qui suit'),
        'log':      ('Note comment tu te sens', 'Flux, symptômes, douleur — en quelques touches'),
        'calendar': ('Vois où tu en es', 'Les jours passés et les prévisions à venir'),
        'insights': ('Les tendances se dessinent', 'La durée de ton cycle et l’évolution des symptômes'),
        'library':  ('Le savoir, avec ses sources', 'Références NHS et Office on Women’s Health'),
    },
    'pt': {
        'home':     ('Compreenda o seu ciclo num relance', 'Em que dia está e o que vem a seguir'),
        'log':      ('Registe como se sente', 'Fluxo, sintomas, dor — em poucos toques'),
        'calendar': ('Veja onde está', 'Dias passados e as previsões à frente'),
        'insights': ('Os padrões revelam-se', 'A duração do seu ciclo e o curso dos sintomas'),
        'library':  ('Informação com as fontes', 'Com referências ao NHS e a Office on Women’s Health'),
    },
}


if __name__ == '__main__':
    S = os.path.dirname(os.path.abspath(__file__))
    device = sys.argv[1]
    W, H = int(sys.argv[2]), int(sys.argv[3])
    lang = sys.argv[4] if len(sys.argv) > 4 else 'tr'
    frames = [(k,) + CAPTIONS[lang][k] for k in ORDER]
    # Yalnızca elde olan kareler; degradenin akışı onlara göre bölünüyor ki
    # eksik bir kare zeminde boşluk bırakmasın.
    src_dir = f'{S}/shots' if lang == 'tr' else f'{S}/shots_{lang}'
    out_dir = f'{S}/store/{lang}'
    os.makedirs(out_dir, exist_ok=True)
    available = [f for f in frames if os.path.exists(f'{src_dir}/{device}_{f[0]}.png')]
    for i, (key, head, sub) in enumerate(available):
        out = f'{out_dir}/{device}_{i + 1}_{key}.png'
        build(f'{src_dir}/{device}_{key}.png', out, i, len(available), head, sub, (W, H))
        print(f'  {os.path.basename(out)}')
