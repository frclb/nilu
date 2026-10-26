#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mağaza görselleri: App Store ve Google Play, altı dil.

Ham ekranlar uygulamanın kendi widget'larıyla çiziliyor; bu betik onları
markanın koyu zemininde, eğik cihazlar ve ekrandan taşan büyütmelerle
kuruyor:

    flutter test test/gallery/store_screens_test.dart --dart-define=STORE=true
    python3 tool/store_screenshots.py              # hepsi
    python3 tool/store_screenshots.py --lang tr    # tek dil

Çıktı `store_assets/` altında (git dışında, yeniden üretilebilir):

    app_store/<dil>/iphone_6_9/01_home.png        1320×2868
    app_store/<dil>/iphone_6_3/01_home.png        1206×2622  (zorunlu boyut)
    app_store/<dil>/ipad_13/01_home.png           2064×2752
    app_store/<dil>/header.jpg                    3840×1646  (21:9)
    app_store/<dil>/search_results.jpg            3840×2560  (3:2)
    google_play/<dil>/phone/01_home.png           1080×1920  (9:16)
    google_play/<dil>/tablet_10/01_home.png       1440×2560  (9:16)
    google_play/<dil>/feature_graphic.png         1024×500
    google_play/icon_512.png                      512×512

Paneller (App Store'da on, Play'de sekiz) tek bir geniş zeminden
kesiliyor: iki ipek şerit paneller arasında kıvrılıp cihazları sarıyor,
döngü halkasının boncukları şeridin üstünde akıyor; mağazada kaydırınca
görseller birbirine bağlanıyor. Tek parça görseller (başlık, arama sonucu,
öne çıkan görsel) aynı şeridi taşıyor. İki dizide de ana ekran widget'ı ve
Sağlık eşitlemesi var (iOS'ta Apple Sağlık, Android'de Health Connect).
Hiçbir çıktıda saydamlık yok.

Ölçüler ve kurallar (Ekim 2026):
  * Ekran görüntüsü boyutları — developer.apple.com/help/app-store-connect/
    reference/app-information/screenshot-specifications
  * Başlık ve arama sonucu görselleri, güvenli alanlar Apple'ın
    şablonlarından — developer.apple.com/app-store/asset-best-practices
  * Görsellerde fiyat, indirim, URL, © ve başka platform adı yok; her
    iddia uygulamada doğrulanabilir.
"""

import argparse
import json
import math
import os
import sys

from PIL import Image, ImageChops, ImageDraw

import store_kit as K

RAW = os.path.join(K.ROOT, "build", "store_raw")
OUT = os.path.join(K.ROOT, "store_assets")
LANGS = ("tr", "en", "de", "es", "fr", "pt")

# ---------------------------------------------------------------------------
# Metinler. "Sen" dili (pt-BR'de "você"), uygulamanın sesiyle aynı.
# `*…*` arası vurgulu (degrade). Her başlık iki satır: paneller arasında
# cihazlar aynı hizada dursun.
# ---------------------------------------------------------------------------

# Sıra mağazadaki sıra: ilk üçü arama sonucunda görünüyor. App Store en
# fazla on kabul ediyor.
SHOTS = (
    "home",
    "calendar",
    "privacy_security",
    "log_entry",
    "widget_home",
    "insights",
    "health_sync",
    "assistant",
    "pregnancy_home",
    "health_library",
)

# Google Play: en fazla sekiz; asistan ve kütüphane dışarıda kalıyor.
# `widget_home` ham ekran değil, widget önizleme ekranından kesilen kartlarla
# kurulan bir ana ekran (`home_screen`). `health_sync` Android'de Health
# Connect, iOS'ta Apple Sağlık ekranı.
PLAY_SHOTS = (
    "home",
    "calendar",
    "widget_home",
    "privacy_security",
    "log_entry",
    "insights",
    "pregnancy_home",
    "health_sync",
)

CAPTIONS = {
    "tr": {
        "home": ("DÖNGÜ", "Döngünü\n*bir bakışta* gör"),
        "calendar": ("TAKVİM", "Sıradaki reglin,\n*aralığıyla* birlikte"),
        "privacy_security": ("GİZLİLİK", "Verin\n*telefonunda* kalır"),
        "log_entry": ("GÜNLÜK", "Nasıl hissettiğini\n*kaydet*"),
        "insights": ("İÇGÖRÜLER", "Bedeninin\n*örüntülerini* gör"),
        "assistant": ("VERİNE SOR", "Cevaplar kendi\n*kayıtlarından*"),
        "pregnancy_home": ("GEBELİK", "Gebelikte de\n*yanında*"),
        "health_library": ("KÜTÜPHANE", "*Kaynaklı* yazılarla\nöğren"),
        "widget_home": ("WİDGET", "Döngün\n*ana ekranında*"),
        "health_sync": ("EŞİTLEME", "Health Connect ile\n*eşitle*"),
    },
    "en": {
        "home": ("CYCLE", "Your cycle\n*at a glance*"),
        "calendar": ("CALENDAR", "Your next period,\n*shown as a range*"),
        "privacy_security": ("PRIVACY", "Your data stays\n*on your phone*"),
        "log_entry": ("DAILY LOG", "Log\n*how you feel*"),
        "insights": ("INSIGHTS", "See your body’s\n*patterns*"),
        "assistant": ("ASK YOUR DATA", "Answers from\n*your own entries*"),
        "pregnancy_home": ("PREGNANCY", "With you\n*through pregnancy*"),
        "health_library": ("LIBRARY", "Learn from\n*sourced articles*"),
        "widget_home": ("WIDGET", "Your cycle\n*on your home screen*"),
        "health_sync": ("SYNC", "Sync with\n*Health Connect*"),
    },
    "de": {
        "home": ("ZYKLUS", "Dein Zyklus\n*auf einen Blick*"),
        "calendar": ("KALENDER", "Deine nächste Periode\n*als Zeitraum*"),
        "privacy_security": ("DATENSCHUTZ", "Deine Daten bleiben\n*auf deinem Handy*"),
        "log_entry": ("TAGEBUCH", "Halte fest,\n*wie es dir geht*"),
        "insights": ("AUSWERTUNGEN", "Erkenne die *Muster*\ndeines Körpers"),
        "assistant": ("FRAG DEINE DATEN", "Antworten aus\n*deinen Einträgen*"),
        "pregnancy_home": ("SCHWANGERSCHAFT", "Auch in der\n*Schwangerschaft* da"),
        "health_library": ("BIBLIOTHEK", "Lerne mit\n*belegten Artikeln*"),
        "widget_home": ("WIDGET", "Dein Zyklus auf dem\n*Startbildschirm*"),
        "health_sync": ("SYNCHRONISIERUNG", "Mit *Health Connect*\nsynchronisieren"),
    },
    "es": {
        "home": ("CICLO", "Tu ciclo\n*de un vistazo*"),
        "calendar": ("CALENDARIO", "Tu próxima regla,\n*como un rango*"),
        "privacy_security": ("PRIVACIDAD", "Tus datos se quedan\n*en tu móvil*"),
        "log_entry": ("REGISTRO", "Anota\n*cómo te sientes*"),
        "insights": ("ANÁLISIS", "Descubre los *patrones*\nde tu cuerpo"),
        "assistant": ("PREGUNTA A TUS DATOS", "Respuestas de\n*tus propios registros*"),
        "pregnancy_home": ("EMBARAZO", "También a tu lado\n*en el embarazo*"),
        "health_library": ("BIBLIOTECA", "Aprende con\n*artículos con fuentes*"),
        "widget_home": ("WIDGET", "Tu ciclo en tu\n*pantalla de inicio*"),
        "health_sync": ("SINCRONIZACIÓN", "Sincroniza con\n*Health Connect*"),
    },
    "fr": {
        "home": ("CYCLE", "Ton cycle\n*en un coup d’œil*"),
        "calendar": ("CALENDRIER", "Tes prochaines règles,\n*sur une période*"),
        "privacy_security": ("CONFIDENTIALITÉ", "Tes données restent\n*sur ton téléphone*"),
        "log_entry": ("JOURNAL", "Note\n*comment tu te sens*"),
        "insights": ("ANALYSES", "Découvre les *rythmes*\nde ton corps"),
        "assistant": ("INTERROGE TES DONNÉES", "Des réponses tirées\n*de tes saisies*"),
        "pregnancy_home": ("GROSSESSE", "À tes côtés\n*pendant la grossesse*"),
        "health_library": ("BIBLIOTHÈQUE", "Apprends avec\n*des articles sourcés*"),
        "widget_home": ("WIDGET", "Ton cycle\n*sur l’écran d’accueil*"),
        "health_sync": ("SYNCHRONISATION", "Synchronise avec\n*Health Connect*"),
    },
    "pt": {
        "home": ("CICLO", "Seu ciclo\n*num relance*"),
        "calendar": ("CALENDÁRIO", "Sua próxima menstruação\n*como um intervalo*"),
        "privacy_security": ("PRIVACIDADE", "Seus dados ficam\n*no seu celular*"),
        "log_entry": ("REGISTRO", "Anote\n*como você se sente*"),
        "insights": ("ANÁLISES", "Veja os *padrões*\ndo seu corpo"),
        "assistant": ("PERGUNTE AOS SEUS DADOS", "Respostas dos seus\n*próprios registros*"),
        "pregnancy_home": ("GRAVIDEZ", "Com você\n*também na gravidez*"),
        "health_library": ("BIBLIOTECA", "Aprenda com\n*artigos com fontes*"),
        "widget_home": ("WIDGET", "Seu ciclo\n*na tela inicial*"),
        "health_sync": ("SINCRONIZAÇÃO", "Sincronize com o\n*Health Connect*"),
    },
}

# iOS'ta farklı olan başlıklar: Sağlık paneli Apple Sağlık'ı anıyor. Ad
# uygulamadakiyle aynı: Apple'ın yönergesi "Apple Health" ve Sağlık'ın
# sistemdeki çevirisi.
APPLE_CAPTIONS = {
    "tr": {"health_sync": ("EŞİTLEME", "Apple Sağlık ile\n*eşitle*")},
    "en": {"health_sync": ("SYNC", "Sync with\n*Apple Health*")},
    "de": {"health_sync": ("SYNCHRONISIERUNG", "Mit *Apple Health*\nsynchronisieren")},
    "es": {"health_sync": ("SINCRONIZACIÓN", "Sincroniza con\n*Apple Salud*")},
    "fr": {"health_sync": ("SYNCHRONISATION", "Synchronise avec\n*Apple Santé*")},
    "pt": {"health_sync": ("SINCRONIZAÇÃO", "Sincronize com o\n*Apple Saúde*")},
}

# Gizlilik panelindeki rozetler ve arama görseli. Üçü de uygulamada
# doğrulanabilir ve iki platformda da doğru: hesap isteğe bağlı (yok değil),
# cihazdaki veri şifreli, ekran kilidi ücretsiz.
BADGES = {
    "tr": ("Hesap şart değil", "Cihazda şifreli", "Ekran kilidi ücretsiz"),
    "en": ("No account needed", "Encrypted on device", "Free app lock"),
    "de": ("Kein Konto nötig", "Auf dem Gerät verschlüsselt", "App-Sperre gratis"),
    "es": ("Sin cuenta obligatoria", "Cifrado en tu móvil", "Bloqueo gratis"),
    "fr": ("Sans compte obligatoire", "Chiffré sur l’appareil", "Verrouillage gratuit"),
    "pt": ("Sem conta obrigatória", "Criptografado no aparelho", "Bloqueio grátis"),
}
BADGE_ICONS = (K.ICON_NO_ACCOUNTS, K.ICON_SHIELD, K.ICON_LOCK)

# Ürün sayfası başlığı: tek bir fikir (Apple'ın önerisi) — alt başlığın
# kısaltılmışı.
HEADER = {
    "tr": "Döngün\n*sende* kalır",
    "en": "Your cycle\n*stays yours*",
    "de": "Dein Zyklus\n*bleibt bei dir*",
    "es": "Tu ciclo,\n*solo tuyo*",
    "fr": "Ton cycle\n*reste à toi*",
    "pt": "Seu ciclo,\n*só seu*",
}

# Arama sonucu: "ne olduğunu söyle". iPhone'da görsel ~365 pt genişlikte;
# başlık büyük, alt kısım iki rozet.
SEARCH = {
    "tr": "*Regl* ve *gebelik*\ntakibi",
    "en": "*Period* & *pregnancy*\ntracking",
    "de": "*Zyklus* und\n*Schwangerschaft*",
    "es": "Tu *regla* y tu\n*embarazo*",
    "fr": "Tes *règles* et ta\n*grossesse*",
    "pt": "*Ciclo* e *gravidez*\nno seu ritmo",
}

FEATURE = {
    "tr": "Döngün *sende* kalır",
    "en": "Your cycle *stays yours*",
    "de": "Dein Zyklus *bleibt bei dir*",
    "es": "Tu ciclo, *solo tuyo*",
    "fr": "Ton cycle *reste à toi*",
    "pt": "Seu ciclo, *só seu*",
}

# ---------------------------------------------------------------------------
# Yerleşim
# ---------------------------------------------------------------------------

# App Store'un zorunlu iPhone boyutu (Dynamic Island, orta ekran). Oranı
# 6,9" ile aynı (0,4600 / 0,4603); arayüz aynı kaldığı için küçültmek yetiyor.
IPHONE_6_3 = (1206, 2622)

# Ölçüler piksel. `screen_w` ekranın tuvaldeki genişliği; `device_top`
# cihazın (döndürülmeden önceki) üst kenarı — bütün panellerde aynı hizada.
# Tablette arayüz küçük görünüyor: büyütme daha güçlü; cihaz büyük olduğu
# için eğim ve kayma azaltılıyor (`tilt`), yoksa köşeleri tuvalden taşıyor.
LAYOUTS = {
    "iphone_6_9": dict(device="iphone", canvas=(1320, 2868), screen_w=1010, top=132,
                       chip=34, headline=150, device_top=760, zoom=1.22, shots=SHOTS),
    "ipad_13": dict(device="ipad", canvas=(2064, 2752), screen_w=1500, top=128,
                    chip=40, headline=156, device_top=770, zoom=1.55, tilt=0.4, shots=SHOTS),
    "phone": dict(device="android", canvas=(1080, 1920), screen_w=700, top=84,
                  chip=26, headline=104, device_top=540, zoom=1.22, shots=PLAY_SHOTS),
    "tablet_10": dict(device="android_tablet", canvas=(1440, 2560), screen_w=1080, top=110,
                      chip=30, headline=124, device_top=690, zoom=1.45, tilt=0.4, shots=PLAY_SHOTS),
}

# Her panelin kurgusu. angle: cihazın eğimi; shift: cihaz merkezinin yatay
# kayması; inset: büyütülen öğenin kenarlarından kırpılan pay (pt, eksi
# değer genişletir); part: öğenin hangi kısmı (oransal kutu); out:
# büyütmenin kaynağına göre kayması (tuvalin oranı); zoom: ek büyütme;
# radius: büyütülen kartın köşesi (pt), verilmezse 20. Bir yerleşimin adıyla
# verilen sözlük o yerleşimde üstteki değerleri değiştiriyor.
SPECS = {
    "home": dict(angle=-6, shift=0.07, inset=0, part=(0, 0, 1, 0.555), out=(-0.13, 0.015), zoom=1.0),
    "calendar": dict(angle=0, shift=0.0, inset=12, part=(0, 0, 1, 1), out=(0.0, 0.05), zoom=1.06),
    "privacy_security": dict(angle=5, shift=0.11, inset=-8, part=(0, 0, 1, 1), out=(-0.14, -0.005), zoom=1.0),
    "log_entry": dict(angle=-5, shift=-0.07, inset=8, part=(0, 0, 1, 1), out=(0.12, 0.02), zoom=1.0),
    "insights": dict(angle=5, shift=0.07, inset=0, part=(0, 0, 1, 1), out=(-0.13, 0.03), zoom=1.0),
    "assistant": dict(angle=0, shift=0.0, inset=0, part=(0, 0, 1, 1), out=(0.0, -0.02), zoom=1.06),
    "pregnancy_home": dict(angle=-5, shift=-0.07, inset=0, part=(0, 0, 1, 1), out=(0.13, 0.015), zoom=1.0),
    "health_library": dict(angle=5, shift=0.07, inset=12, part=(0, 0, 1, 1), out=(-0.12, 0.03), zoom=1.0),
    "widget_home": dict(angle=-5, shift=0.06, inset=0, part=(0, 0, 1, 1), out=(-0.10, 0.02), zoom=1.0,
                        radius=22, tablet_10=dict(out=(-0.02, -0.17)), ipad_13=dict(out=(-0.02, -0.17))),
    "health_sync": dict(angle=5, shift=-0.06, inset=-4, part=(0, 0, 1, 1), out=(0.10, 0.0), zoom=1.0),
}


# ---------------------------------------------------------------------------
# Ham ekranlar
# ---------------------------------------------------------------------------


def _raw(device, lang, shot):
    base = os.path.join(RAW, device, lang, shot)
    if not os.path.exists(base + ".png"):
        sys.exit(
            f"Ham ekran yok: {os.path.relpath(base, K.ROOT)}.png\n"
            "Önce: flutter test test/gallery/store_screens_test.dart --dart-define=STORE=true"
        )
    screen = Image.open(base + ".png").convert("RGB")
    with open(base + ".json", encoding="utf-8") as f:
        meta = json.load(f)
    return screen, meta


def load_raw(device, lang, shot):
    if shot == "widget_home":
        return home_screen(lang, device)
    screen, meta = _raw(device, lang, shot)
    spec = K.DEVICES[device]
    spec["status"](screen, spec["ratio"])
    return screen, meta


def wallpaper(size):
    """Ana ekranın duvar kâğıdı: canlı gül–mor degrade, ışıklar, lotus.

    Koyu panorama zemininde cihaz seçilsin diye açık ve doygun; beyaz
    widget kartları üstünde öne çıkıyor.
    """
    w, h = size
    img = K.vertical_gradient(size, (0xB8, 0x3A, 0x78), (0x3C, 0x12, 0x5A))
    _glows(img, [
        ((w * 0.85, h * 0.12), w * 0.75, K.FERTILE, 0.65),
        ((w * 0.05, h * 0.55), w * 0.80, K.OVULATION, 0.55),
        ((w * 0.95, h * 0.90), w * 0.70, (0xFF, 0xA8, 0x8C), 0.40),
        ((w * 0.30, h * 1.00), w * 0.60, K.PLUM900, 0.50),
    ])
    K.lotus_watermark(img, (w * 0.5, h * 0.72), w * 0.9, K.WHITE, 0.07)
    return K.grain(img, amount=4, seed=5)


def home_screen(lang, device):
    """Ana ekranda Nilu widget'ları: "widget" panelinin ekranı.

    Kartlar uygulamanın widget önizleme ekranından (`widgets_preview`)
    kesiliyor, yani widget'ın kendi çizimi. Yerleşim platformun ana
    ekranına göre: telefonda orta widget üstte, altında küçük widget ve
    uygulama simgesi; tablette ikisi yan yana ekranın ortasında (büyütme
    üstlerinde duruyor, ana ekrandaki hâlleri görünsün). Simge Android'de
    yuvarlak, iOS'ta yuvarlatılmış kare. Dönen meta büyütülecek kartı (orta
    widget) gösteriyor.
    """
    src, meta = _raw(device, lang, "widgets_preview")
    r = meta["ratio"]
    w, h = src.size
    screen = wallpaper((w, h))
    ios = device in ("iphone", "ipad")
    tablet = device in ("ipad", "android_tablet")

    def card(rect):
        box = tuple(int(round(v * r)) for v in rect)
        crop = src.crop(box)
        return crop, K.rounded_mask(crop.size, 22 * r)

    def put(img, mask, x, y):
        K.shadow(screen, mask, (x * r, y * r), strength=0.45, blur=0.05, drop=0.04)
        screen.paste(img, (int(round(x * r)), int(round(y * r))), mask)

    medium, medium_mask = card(meta["callout"])
    small, small_mask = card(meta["widget_small"])
    mw, mh = medium.size[0] / r, medium.size[1] / r
    sw = small.size[0] / r
    icon_pt = 64 if ios else 60
    if tablet:
        x0 = (w / r - mw - 24 - sw) / 2
        m_pos = (x0, 430)
        s_pos = (x0 + mw + 24, 430)
        icon_c = (s_pos[0] + sw / 2, 430 + mh + 70)
    else:
        # iOS'ta widget'lar Dynamic Island'ın altından başlıyor.
        m_pos = ((w / r - mw) / 2, 84 if ios else 128)
        s_pos = (m_pos[0], m_pos[1] + mh + 28)
        icon_c = (m_pos[0] + mw - sw / 2, s_pos[1] + sw / 2 - 12)
    put(medium, medium_mask, *m_pos)
    put(small, small_mask, *s_pos)

    # Uygulama simgesi ve adı.
    size = int(icon_pt * r)
    source = os.path.join(K.ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset",
                          "Icon-App-1024x1024@1x.png")
    icon = Image.open(source).convert("RGB").resize((size, size), Image.LANCZOS)
    icon_mask = K.rounded_mask((size, size), size * (0.2237 if ios else 0.5))
    ix, iy = icon_c[0] * r - size / 2, icon_c[1] * r - size / 2
    K.shadow(screen, icon_mask, (ix, iy), strength=0.4, blur=0.08, drop=0.05)
    screen.paste(icon, (int(ix), int(iy)), icon_mask)
    d = ImageDraw.Draw(screen)
    label_font = K.status_font(12 * r) if ios else K.roboto(13 * r)
    d.text((icon_c[0] * r, (icon_c[1] + icon_pt / 2 + (18 if ios else 20)) * r), "Nilu", font=label_font, fill=K.WHITE,
           anchor="mm")

    # Ana ekran çubuğu (iOS) ya da hareket çubuğu (Android).
    bw, bh, bottom = (134, 5, 8) if ios else (108, 4, 10)
    d.rounded_rectangle([(w - bw * r) / 2, h - (bottom + bh) * r, (w + bw * r) / 2, h - bottom * r],
                        radius=bh * r / 2, fill=(255, 255, 255))
    if device == "iphone":
        K.ios_phone_status(screen, r, ink=K.WHITE)
    elif device == "ipad":
        K.ios_pad_status(screen, r, ink=K.WHITE)
    else:
        K.android_status(screen, r, camera=not tablet, ink=K.WHITE)
    rect = [m_pos[0], m_pos[1], m_pos[0] + mw, m_pos[1] + mh]
    return screen, {"ratio": r, "callout": rect}


def callout_box(screen, meta, spec):
    """Büyütülecek öğenin ham ekrandaki kutusu (piksel)."""
    rect = meta.get("callout")
    if not rect:
        return None
    r = meta["ratio"]
    inset = spec["inset"] * r
    l, t, rr, b = rect[0] * r + inset, rect[1] * r, rect[2] * r - inset, rect[3] * r
    if spec["inset"] < 0:
        t, b = t + inset, b - inset
    p0, p1, p2, p3 = spec["part"]
    w, h = rr - l, b - t
    box = (l + w * p0, t + h * p1, l + w * p2, t + h * p3)
    sw, sh = screen.size
    return (max(0, box[0]), max(0, box[1]), min(sw, box[2]), min(sh, box[3]))


# ---------------------------------------------------------------------------
# Zemin: koyu marka degradesi, ışıklar, döngü ipliği, gren
# ---------------------------------------------------------------------------

_PANORAMA = {}
_FRONT = {}  # şeridin cihazların önünden geçen kısmı


def _glows(canvas, items):
    """Aynı renkteki ışıklar tek maskede: büyük tuvalde hızlı kalsın."""
    w, h = canvas.size
    k = 8
    by_color = {}
    for center, radius, color, alpha in items:
        by_color.setdefault(color, []).append((center, radius, alpha))
    for color, spots in by_color.items():
        small = Image.new("L", (w // k + 1, h // k + 1), 0)
        for (cx, cy), radius, alpha in spots:
            r = radius / k
            spot = Image.new("L", small.size, 0)
            ImageDraw.Draw(spot).ellipse([cx / k - r, cy / k - r, cx / k + r, cy / k + r],
                                         fill=int(255 * alpha))
            spot = spot.filter(K.ImageFilter.GaussianBlur(r * 0.55))
            small = K.ImageChops.lighter(small, spot)
        canvas.paste(color, (0, 0), small.resize((w, h), Image.BICUBIC))


def thread(canvas, path, dot, alpha=1.0, keep=None, cover=None):
    """Döngü ipliği: şeridin bir telinde evre renkli boncuklar, hafif ışık.

    `keep(x)`: yalnızca bu boncuklar (şeridin önde ve arkada kalan kısmı
    ayrı katmanlarda). `cover`: verilirse önde kalan katmanın saydamlık
    maskesi; boncuklar ona da işleniyor, ışık halesi çizilmiyor.
    """
    w, h = canvas.size

    # Noktaları yay uzunluğuna göre eşit aralıkla diz.
    spacing = dot * 2.1
    beads, travelled, prev = [], 0.0, path[0]
    for p in path[1:]:
        travelled += math.dist(prev, p)
        if travelled >= spacing:
            beads.append(p)
            travelled = 0.0
        prev = p
    # Renk sırası bütün iplikte aynı kalsın: süzmeden önce numaralandır.
    beads = [(i, p) for i, p in enumerate(beads) if keep is None or keep(p[0])]

    if cover is None:
        halo = Image.new("L", (w // 4 + 1, h // 4 + 1), 0)
        hd = ImageDraw.Draw(halo)
        for i, (x, y) in beads:
            r = dot * (1.6 if K.PHASES[i % len(K.PHASES)] == K.OVULATION else 1.0) * 1.9 / 4
            hd.ellipse([x / 4 - r, y / 4 - r, x / 4 + r, y / 4 + r], fill=int(120 * alpha))
        halo = halo.filter(K.ImageFilter.GaussianBlur(dot / 3))
        canvas.paste(K.PLUM300, (0, 0), halo.resize((w, h), Image.BICUBIC))

    for i, (x, y) in beads:
        color = K.PHASES[i % len(K.PHASES)]
        size = dot * (1.6 if color == K.OVULATION else 1.0)
        box = int(size * 2) + 4
        local = Image.new("L", (box * K.SS, box * K.SS), 0)
        c = box / 2 * K.SS
        rr = size / 2 * K.SS
        ImageDraw.Draw(local).ellipse([c - rr, c - rr, c + rr, c + rr], fill=int(255 * alpha))
        local = local.resize((box, box), Image.LANCZOS)
        canvas.paste(color, (int(x - box / 2), int(y - box / 2)), local)
        if cover is not None:
            cover.paste(255, (int(x - box / 2), int(y - box / 2)), local)
        # Boncuğun üstünde küçük bir parıltı: düz daire değil, ışıklı taş.
        shine = Image.new("L", (box * K.SS, box * K.SS), 0)
        sr = rr * 0.38
        sc = (c - rr * 0.3, c - rr * 0.3)
        ImageDraw.Draw(shine).ellipse([sc[0] - sr, sc[1] - sr, sc[0] + sr, sc[1] + sr], fill=int(110 * alpha))
        canvas.paste(K.WHITE, (int(x - box / 2), int(y - box / 2)), shine.resize((box, box), Image.LANCZOS))


# Şeridin renkleri: vurgunun gülleri, lavanta ve şeftali — panelden panele
# yavaşça değişiyor.
RIBBON_STOPS = ((0xFF, 0x8F, 0xB8), (0xC9, 0xA4, 0xFF), (0xFF, 0xC8, 0xA8), (0xFF, 0xAE, 0xDE),
                (0xB4, 0x8C, 0xFF), (0xFF, 0x8F, 0xB8))


def silk(size, xs, center, width, twist, phase, strands, strength, line_unit, k=2):
    """Bükülen ipek şerit: yüzey ve tel maskeleri (1/k çözünürlükte) ve teller.

    `center(x)`: şeridin orta çizgisi; `width`: yarı genişliği; `twist`:
    bir tam dönüşün boyu. Şeridin bize dönük geniş yeri parlak, kıvrılıp
    inceldiği yer soluk — düz bir bant değil, dönen bir ipek. `line_unit`:
    tel kalınlığının ölçüsü (tuval genişliği).
    """
    small = (size[0] // k + 1, size[1] // k + 1)
    lines, sheen = Image.new("L", small, 0), Image.new("L", small, 0)
    d, ds = ImageDraw.Draw(lines), ImageDraw.Draw(sheen)

    def turn(x):
        return math.cos(2 * math.pi * x / twist + phase)

    # Yüzey: dar dilimler, her biri bükülmeye göre parlak ya da soluk.
    prev = None
    for x in xs:
        c, spread = center(x), width * turn(x)
        edge = (x / k, (c - spread) / k, (c + spread) / k)
        if prev:
            light = 0.22 + 0.78 * abs(turn(x)) ** 0.8
            ds.polygon([(prev[0], prev[1]), (edge[0], edge[1]), (edge[0], edge[2]), (prev[0], prev[2])],
                       fill=int(120 * strength * light))
        prev = edge

    paths = []
    for j in range(strands):
        t = j / (strands - 1) * 2 - 1  # -1…1
        paths.append([(x, center(x) + width * turn(x) * t) for x in xs])
    for j, path in enumerate(paths):
        edge = j in (0, strands - 1)
        line_w = max(1, round(line_unit * (0.0040 if edge else 0.0016) * strength / k))
        d.line([(x / k, y / k) for x, y in path], fill=int((245 if edge else 90) * strength),
               width=line_w, joint="curve")
    return lines, sheen, paths


def silk_halo(canvas, colors, mask, radius, gain=2.6):
    """Şeridin çevresine yayılan ışık."""
    W, h = canvas.size
    halo = mask.resize((W // 8 + 1, h // 8 + 1), Image.BILINEAR)
    halo = halo.filter(K.ImageFilter.GaussianBlur(radius / 8)).point(lambda v: min(255, int(v * gain)))
    canvas.paste(colors, (0, 0), halo.resize((W, h), Image.BICUBIC))


def ribbon(canvas, w, h):
    """Paneller arasında akan ışıklı şeritler.

    Mağazada görseller yan yana, aralarında boşlukla diziliyor. İki şerit
    zıt yönde kıvrılıyor ve her panel sınırında çaprazlanıyor: biri
    bıraktığı yerden ötekinde devam ediyor, sınırdaki düğüm iki paneli
    birbirine bağlıyor. Her panelde biri cihazın arkasından yukarı
    kıvrılıyor, öteki aşağıda cihazın önünden geçiyor — şerit cihazları
    sarıyor. Önden arkaya geçiş panel sınırında, yani görünmeyen yerde.
    Başlık bandına çıkmıyor: yazının okunurluğu bozulmasın.

    Arkada kalan kısım `canvas`a çiziliyor; önde kalan (renk, saydamlık)
    tam genişlikte döndürülüyor, panel cihazdan sonra üstüne basıyor.
    """
    W = canvas.size[0]
    n = round(W / w)
    k = 2  # yarım çözünürlükte çiz, büyüt: hızlı ve yumuşak
    # Aşağı inen (öndeki) kıvrım cihazın en altından, ekranın kesildiği
    # yerden geçiyor: arayüzün yazılarını örtmesin.
    mid, rise, dip = h * 0.66, h * 0.20, h * 0.27
    xs = range(int(-w * 0.1), int(W + w * 0.1), 4)

    def center(sign):
        def at(x):
            # Sınırlarda (x = i·w) orta yükseklik: iki şerit burada kesişiyor.
            s = sign * math.sin(math.pi * x / w) * (1 + 0.12 * math.sin(2 * math.pi * x / (0.83 * w)))
            return mid + s * (dip if s > 0 else rise)
        return at

    # A: çift panellerde aşağı iniyor (önde), tek panellerde yukarı
    # (arkada); B tersi. Önde yüzey daha saydam: altındaki arayüz okunsun.
    a_lines, a_sheen, a_paths = silk((W, h), xs, center(1), h * 0.065, 1.35 * w, 0.5, 7, 1.0, w, k)
    b_lines, b_sheen, _ = silk((W, h), xs, center(-1), h * 0.038, 1.1 * w, 2.0, 5, 0.7, w, k)
    a, b = ImageChops.lighter(a_lines, a_sheen), ImageChops.lighter(b_lines, b_sheen)

    def see_through(lines, sheen):
        return ImageChops.lighter(lines, sheen.point(lambda v: int(v * 0.6)))

    a_front, b_front = see_through(a_lines, a_sheen), see_through(b_lines, b_sheen)
    even = Image.new("L", a.size, 0)
    de = ImageDraw.Draw(even)
    for i in range(0, n, 2):
        de.rectangle([i * w / k, 0, (i + 1) * w / k - 1, a.size[1]], fill=255)
    odd = ImageChops.invert(even)
    mul = ImageChops.multiply
    front = ImageChops.lighter(mul(a_front, even), mul(b_front, odd)).resize((W, h), Image.BICUBIC)
    back = ImageChops.lighter(mul(a, odd), mul(b, even)).resize((W, h), Image.BICUBIC)

    colors = K.horizontal_gradient((W // 8, 1), RIBBON_STOPS).resize((W, h))
    silk_halo(canvas, colors, ImageChops.lighter(a, b), w * 0.025)
    canvas.paste(colors, (0, 0), back)

    # A'nın orta telinde döngünün boncukları: marka imzası şeritle birlikte
    # akıyor, şerit öndeyken boncuklar da önde.
    path = a_paths[len(a_paths) // 2]
    dot = w * 0.014
    thread(canvas, path, dot, alpha=0.95, keep=lambda x: int(x // w) % 2 == 1)
    thread(colors, path, dot, alpha=0.95, keep=lambda x: int(x // w) % 2 == 0, cover=front)
    return colors, front


def backdrop_silk(canvas, center, width, twist, phase, dot, line_unit):
    """Tek parça görsellerde şerit: bütünüyle cihazların arkasında.

    `center(x)`: orta çizgi; ölçüler ribbon'daki gibi.
    """
    w, h = canvas.size
    k = 1 if w <= 1200 else 2
    lines, sheen, paths = silk((w, h), range(-w // 20, w + w // 20, 2), center, width, twist, phase, 7, 0.85,
                               line_unit, k)
    mask = ImageChops.lighter(lines, sheen)
    mask = mask.crop((0, 0, w, h)) if k == 1 else mask.resize((w, h), Image.BICUBIC)
    colors = K.horizontal_gradient((max(2, w // 4), 1), RIBBON_STOPS[:3]).resize((w, h))
    silk_halo(canvas, colors, mask, w * 0.02, gain=1.5)
    canvas.paste(colors, (0, 0), mask)
    thread(canvas, paths[len(paths) // 2], dot)


def panorama(layout_name):
    """Panellerin ortak zemini; panel başına bir dilim."""
    if layout_name in _PANORAMA:
        return _PANORAMA[layout_name]
    layout = LAYOUTS[layout_name]
    w, h = layout["canvas"]
    n = len(layout["shots"])
    W = w * n
    canvas = K.vertical_gradient((W, h), K.PLUM700, K.DEEP)
    items = []
    for i in range(n):
        items.append((((i + (0.85 if i % 2 == 0 else 0.15)) * w, h * 0.07), w * 0.9, K.BERRY_LIGHT, 0.55))
        items.append((((i + 0.5) * w, h * 1.0), w * 0.95, K.FERTILE, 0.22))
        items.append(((i * w, h * (0.40 + 0.12 * (i % 3))), w * 0.6, K.OVULATION, 0.30))
        items.append((((i + 0.5) * w, h * 0.42), w * 0.55, K.PLUM600, 0.45))
        # Şeridin panel sınırını geçtiği yerde ışık: kesik değil, köprü.
        items.append(((i * w, h * 0.66), w * 0.42, K.BERRY_LIGHT, 0.40))
    _glows(canvas, items)
    for i in range(0, n, 3):
        K.lotus_watermark(canvas, ((i + 0.92) * w, h * 0.30), w * 0.75, K.PLUM300, 0.045)
    colors, front = ribbon(canvas, w, h)
    canvas = K.grain(canvas, amount=6)
    _PANORAMA[layout_name] = [canvas.crop((i * w, 0, (i + 1) * w, h)) for i in range(n)]
    _FRONT[layout_name] = [(colors.crop((i * w, 0, (i + 1) * w, h)), front.crop((i * w, 0, (i + 1) * w, h)))
                           for i in range(n)]
    return _PANORAMA[layout_name]


def dark_canvas(size, seed_glows):
    """Tek parça koyu zemin (başlık, arama, öne çıkan görsel için)."""
    canvas = K.vertical_gradient(size, K.PLUM700, K.DEEP)
    _glows(canvas, seed_glows)
    return K.grain(canvas, amount=6)


# ---------------------------------------------------------------------------
# Yazı blokları
# ---------------------------------------------------------------------------


def chip(canvas, center_x, top, text, size):
    """Cam etiket: nokta + aralıklı büyük harf. Alt kenarını döndürür."""
    tracking = 0.16
    tw = K.SANS_BOLD.width(text, size, tracking)
    dot = size * 0.45
    pad_x, height = size * 1.1, size * 2.3
    width = pad_x * 2 + dot + size * 0.6 + tw
    x0 = center_x - width / 2
    K.glass(canvas, (x0, top, x0 + width, top + height), height / 2, alpha=0.12, border=0.32, blur=20)
    d = ImageDraw.Draw(canvas)
    cy = top + height / 2
    d.ellipse([x0 + pad_x, cy - dot / 2, x0 + pad_x + dot, cy + dot / 2], fill=K.PLUM300)
    K.SANS_BOLD.draw(d, x0 + pad_x + dot + size * 0.6, cy + size * 0.36, text, size, (255, 236, 246), tracking)
    return top + height


def brand(canvas, center_x, top, size, left=False):
    """Lotus + "Nilu": ilk panelin ve başlık görselinin imzası.

    `left`: `center_x` sol kenar sayılır.
    """
    mark = K.lotus_mark(size * 2.2)
    mark = mark.crop(mark.getbbox())  # çiçeğin çevresindeki boşluk
    mark = mark.resize((int(mark.size[0] * size * 0.95 / mark.size[1]), int(size * 0.95)), Image.LANCZOS)
    word_w = K.SERIF_BOLD.width("Nilu", size)
    gap = size * 0.28
    total = mark.size[0] + gap + word_w
    x0 = center_x if left else center_x - total / 2
    canvas.paste(mark, (int(x0), int(top + size * 0.02)), mark)
    d = ImageDraw.Draw(canvas)
    K.SERIF_BOLD.draw(d, x0 + mark.size[0] + gap, top + size * 0.92, "Nilu", size, K.WHITE)
    return top + size * 1.25


def headline(canvas, center_x, top, text, size, max_width, face=None):
    """Vurgulu, ortalı başlık. Alt kenarını döndürür."""
    face = face or K.SERIF_BOLD
    lines = text.split("\n")
    size = K.fit_marked(face, lines, size, max_width)
    line_h = size * 1.04
    baseline = top + size * 0.86
    for line in lines:
        lw = K.marked_width(face, line, size)
        K.draw_marked(canvas, face, center_x - lw / 2, baseline, line, size, K.WHITE)
        baseline += line_h
    return baseline - line_h + size * 0.26


def badge_width(text, size):
    height = size * 2.6
    return height * 0.16 + height * 0.68 + size * 0.7 + K.SANS_STRONG.width(text, size) + size * 1.2


def badge(canvas, x, y, text, icon, size, dark=False):
    """Cam rozet: degrade daire içinde simge + yazı. Genişliğini döndürür.

    `dark`: açık renkli ekranın üstüne binerken koyu cam — beyaz yazı okunsun.
    """
    height = size * 2.6
    icon_d = height * 0.68
    pad = (height - icon_d) / 2
    tw = K.SANS_STRONG.width(text, size)
    width = pad + icon_d + size * 0.7 + tw + size * 1.2
    if dark:
        K.glass(canvas, (x, y, x + width, y + height), height / 2, tint=K.PLUM900, alpha=0.82,
                border=0.30, blur=24)
    else:
        K.glass(canvas, (x, y, x + width, y + height), height / 2, alpha=0.16, border=0.34, blur=24)
    circle = K.rounded_mask((int(icon_d), int(icon_d)), icon_d / 2)
    grad = K.horizontal_gradient((int(icon_d), int(icon_d)), (K.FERTILE, K.BERRY_LIGHT, K.BERRY))
    canvas.paste(grad, (int(x + pad), int(y + pad)), circle)
    d = ImageDraw.Draw(canvas)
    d.text((x + pad + icon_d / 2, y + height / 2), icon, font=K.icon_font(icon_d * 0.56),
           fill=K.WHITE, anchor="mm")
    K.SANS_STRONG.draw(d, x + pad + icon_d + size * 0.7, y + height / 2 + size * 0.36, text, size, K.WHITE)
    return width


# ---------------------------------------------------------------------------
# Paneller
# ---------------------------------------------------------------------------


def place_callout(canvas, screen, meta, spec, mapper, framed, zoom, text_bottom):
    """Ekrandaki öğeyi büyütüp cihazın üstüne taşırır."""
    box = callout_box(screen, meta, spec)
    if box is None:
        return None
    w, h = canvas.size
    crop = screen.crop(tuple(int(round(v)) for v in box))
    width = (box[2] - box[0]) * framed.scale * zoom * spec["zoom"]
    width = min(width, w * 0.94)
    radius = spec.get("radius", 20) * meta["ratio"] * framed.scale * zoom
    card, mask = K.callout_card(crop, width, radius)
    cx, cy = mapper(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2))
    cx += spec["out"][0] * w
    cy += spec["out"][1] * h
    x0 = min(max(cx - card.size[0] / 2, w * 0.03), w * 0.97 - card.size[0])
    y0 = max(cy - card.size[1] / 2, text_bottom + h * 0.02)
    K.shadow(canvas, mask, (x0, y0), strength=0.7, blur=0.06, drop=0.05)
    canvas.paste(card, (int(round(x0)), int(round(y0))), card)
    return (x0, y0, x0 + card.size[0], y0 + card.size[1])


def panel(lang, layout_name, index, shot):
    layout = LAYOUTS[layout_name]
    spec = dict(SPECS[shot], **SPECS[shot].get(layout_name, {}))
    canvas = panorama(layout_name)[index].copy()
    w, h = canvas.size

    # Yazı: ilk panelde marka imzası, diğerlerinde cam etiket.
    captions = CAPTIONS[lang]
    if layout["device"] in ("iphone", "ipad"):
        captions = captions | APPLE_CAPTIONS[lang]
    overline, text = captions[shot]
    if index == 0:
        y = brand(canvas, w / 2, layout["top"], layout["chip"] * 2.5)
    else:
        y = chip(canvas, w / 2, layout["top"], overline, layout["chip"])
    text_bottom = headline(canvas, w / 2, y + layout["chip"] * 1.1, text, layout["headline"], w * 0.88)

    # Cihaz.
    device = layout["device"]
    screen, meta = load_raw(device, lang, shot)
    framed = K.Framed(device, screen, layout["screen_w"])
    fh = framed.image.size[1]
    tilt = layout.get("tilt", 1.0)
    center = (w / 2 + spec["shift"] * w * tilt, layout["device_top"] + fh / 2)
    mapper = K.place_device(canvas, framed, center, spec["angle"] * tilt)

    # Şerit cihazın önünden geçiyor; altına ince bir gölge düşüyor.
    colors, front = _FRONT[layout_name][index]
    K.shadow(canvas, front, (0, 0), strength=0.35, blur=0.012, drop=0.008)
    canvas.paste(colors, (0, 0), front)

    place_callout(canvas, screen, meta, spec, mapper, framed, layout["zoom"], text_bottom)

    if shot == "privacy_security":
        size = w * 0.031
        y = h * 0.69
        for label, icon in zip(BADGES[lang], BADGE_ICONS):
            badge(canvas, w * 0.045, y, label, icon, size, dark=True)
            y += size * 3.3
    return canvas


# ---------------------------------------------------------------------------
# App Store: ürün sayfası başlığı ve arama sonucu görseli
# ---------------------------------------------------------------------------

HEADER_SIZE = (3840, 1646)
# Apple şablonundaki güvenli alan: iPhone'da görünen orta kare
# (x 1097–2743) içinde, gezinme çubuğu ile simge/ad katmanı arasında kalan
# bant (y 493–1154). Yazı burada; dışı geniş ekranlarda görünüyor.
HEADER_SAFE = (1097, 493, 2743, 1154)
SEARCH_SIZE = (3840, 2560)
SEARCH_SAFE = (836, 765, 3004, 1795)


def device_with_callout(canvas, lang, device, shot, screen_w, center, angle, zoom, out, floor=0):
    screen, meta = load_raw(device, lang, shot)
    framed = K.Framed(device, screen, screen_w)
    mapper = K.place_device(canvas, framed, center, angle)
    spec = dict(SPECS[shot], out=out)
    return place_callout(canvas, screen, meta, spec, mapper, framed, zoom, floor)


def header(lang):
    w, h = HEADER_SIZE
    sx0, sy0, sx1, sy1 = HEADER_SAFE
    canvas = dark_canvas(HEADER_SIZE, [
        ((w * 0.5, h * 0.45), h * 0.8, K.BERRY_LIGHT, 0.50),
        ((w * 0.12, h * 0.15), h * 0.9, K.OVULATION, 0.28),
        ((w * 0.88, h * 0.9), h * 0.9, K.FERTILE, 0.22),
        ((w * 0.5, h * 1.05), h * 0.6, K.PLUM600, 0.5),
    ])
    # Şerit güvenli bandın altından geçiyor: yazıya hiç değmiyor; iPhone'da
    # simge/ad katmanının altında kalıyor, geniş ekranlarda görünüyor.
    backdrop_silk(canvas, lambda x: h * 0.86 + h * 0.05 * math.sin(2 * math.pi * x / 1900 + 0.3),
                  h * 0.055, 1500, 0.4, dot=30, line_unit=2000)

    # Kenarlar (iPad ve Mac'te görünür): iki yanda uygulama, ekrandan taşan
    # öğeleriyle.
    device_with_callout(canvas, lang, "iphone", "calendar", 700, (w * 0.135, h * 0.66), 9, 1.15, (0.035, 0.03))
    device_with_callout(canvas, lang, "iphone", "pregnancy_home", 700, (w * 0.865, h * 0.66), -9, 1.15,
                        (-0.035, 0.0))

    # Orta: imza ve tek cümle, güvenli bandın içinde.
    cx = (sx0 + sx1) / 2
    y = brand(canvas, cx, sy0 + 10, 64)
    headline(canvas, cx, y + 36, HEADER[lang], 190, (sx1 - sx0) * 0.9)
    return canvas


def search_results(lang):
    w, h = SEARCH_SIZE
    sx0, sy0, sx1, sy1 = SEARCH_SAFE
    canvas = dark_canvas(SEARCH_SIZE, [
        ((w * 0.75, h * 0.35), h * 0.7, K.BERRY_LIGHT, 0.55),
        ((w * 0.15, h * 0.2), h * 0.8, K.OVULATION, 0.25),
        ((w * 0.4, h * 1.0), h * 0.7, K.FERTILE, 0.25),
        ((w * 0.3, h * 0.5), h * 0.6, K.PLUM600, 0.5),
    ])
    backdrop_silk(canvas, lambda x: h * 0.86 + h * 0.06 * math.sin(2 * math.pi * x / 2600 + 0.4),
                  h * 0.05, 2000, 0.4, dot=34, line_unit=2000)

    # Sağ: arayüzün kendisi; halka kartı ekrandan taşıyor. Telefon güvenli
    # alandan taşabilir; kırpılan bir yerleşimde halka kartı içeride kalıyor.
    phone_cx = sx1 - 340
    callout = device_with_callout(canvas, lang, "iphone", "home", 880, (phone_cx, h * 0.56), -6, 1.2,
                                  (-0.045, 0.0))

    # Sol: ne olduğu — yazı büyütmenin soluna sığıyor.
    x0 = sx0 + 40
    text_w = (callout[0] if callout else phone_cx - 600) - 90 - x0
    brand(canvas, x0, sy0 + 20, 84, left=True)
    lines = SEARCH[lang].split("\n")
    size = K.fit_marked(K.SERIF_BOLD, lines, 240, text_w)
    baseline = sy0 + 200 + size * 0.86
    for line in lines:
        K.draw_marked(canvas, K.SERIF_BOLD, x0, baseline, line, size, K.WHITE)
        baseline += size * 1.04
    by = baseline - size * 1.04 + size * 0.55
    pairs = list(zip(BADGES[lang], BADGE_ICONS))[:2]
    bsize = min(84, min(84 * text_w / badge_width(label, 84) for label, _ in pairs))
    for label, icon in pairs:
        badge(canvas, x0, by, label, icon, bsize)
        by += bsize * 3.2
    return canvas


# ---------------------------------------------------------------------------
# Google Play: öne çıkan görsel ve simge
# ---------------------------------------------------------------------------


def feature_graphic(lang):
    size = (1024, 500)
    w, h = size
    canvas = dark_canvas(size, [
        ((w * 0.75, h * 0.3), h * 0.8, K.BERRY_LIGHT, 0.55),
        ((w * 0.1, h * 0.1), h * 0.8, K.OVULATION, 0.25),
        ((w * 0.35, h * 0.9), h * 0.6, K.PLUM600, 0.5),
    ])
    # Ekran görüntülerindeki ipek şerit, yazının altından telefonun
    # arkasına akıyor.
    backdrop_silk(canvas, lambda x: h * 0.80 + h * 0.07 * math.sin(2 * math.pi * x / 760 + 0.5),
                  h * 0.075, 560, 0.4, dot=10, line_unit=w * 1.4)
    device_with_callout(canvas, lang, "android", "home", 250, (w * 0.80, h * 0.80), -8, 1.15, (-0.10, -0.05))

    x = w * 0.07
    mark = K.lotus_mark(96)
    canvas.paste(mark, (int(x), int(h * 0.30)), mark)
    d = ImageDraw.Draw(canvas)
    K.SERIF_BOLD.draw(d, x + 96 + 16, h * 0.30 + 84, "Nilu", 92, K.WHITE)
    line = FEATURE[lang]
    tsize = K.fit_marked(K.SANS_BOLD, [line], 36, w * 0.5)
    K.draw_marked(canvas, K.SANS_BOLD, x + 6, h * 0.30 + 160, line, tsize, (255, 236, 246))
    return canvas


def play_icon():
    source = os.path.join(K.ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset",
                          "Icon-App-1024x1024@1x.png")
    return Image.open(source).convert("RGB").resize((512, 512), Image.LANCZOS)


# ---------------------------------------------------------------------------


def save(img, *parts):
    """PNG; büyük yaratıcı görseller JPEG (Apple ikisini de kabul ediyor).

    Gren dokusu PNG sıkıştırmasını bozuyor: 3840 px'lik arama görseli PNG
    olarak 10 MB'ı geçiyordu. JPEG 4:4:4 ve yüksek kalitede yazı kenarları
    bulanıklaşmıyor.
    """
    path = os.path.join(OUT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if path.endswith(".jpg"):
        img.convert("RGB").save(path, "JPEG", quality=93, subsampling=0, optimize=True)
    else:
        img.convert("RGB").save(path, "PNG", optimize=True)
    return path


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--lang", choices=LANGS, action="append",
                        help="yalnızca bu dil(ler); verilmezse hepsi")
    parser.add_argument("--only", choices=("app_store", "google_play", "creative"),
                        help="yalnızca bir grup")
    args = parser.parse_args()
    langs = args.lang or LANGS

    count = 0
    for lang in langs:
        if args.only in (None, "app_store"):
            for layout in ("iphone_6_9", "ipad_13"):
                for i, shot in enumerate(SHOTS):
                    img = panel(lang, layout, i, shot)
                    name = f"{i + 1:02d}_{shot}.png"
                    save(img, "app_store", lang, layout, name)
                    count += 1
                    if layout == "iphone_6_9":
                        save(img.resize(IPHONE_6_3, Image.LANCZOS), "app_store", lang, "iphone_6_3", name)
                        count += 1
        if args.only in (None, "creative"):
            save(header(lang), "app_store", lang, "header.jpg")
            save(search_results(lang), "app_store", lang, "search_results.jpg")
            count += 2
        if args.only in (None, "google_play"):
            for layout in ("phone", "tablet_10"):
                for i, shot in enumerate(PLAY_SHOTS):
                    save(panel(lang, layout, i, shot), "google_play", lang, layout, f"{i + 1:02d}_{shot}.png")
                    count += 1
            save(feature_graphic(lang), "google_play", lang, "feature_graphic.png")
            count += 1
        print(f"{lang}: tamam")
    if args.only in (None, "google_play"):
        save(play_icon(), "google_play", "icon_512.png")
        count += 1
    print(f"{count} görsel → {os.path.relpath(OUT, K.ROOT)}/")


if __name__ == "__main__":
    main()
