#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""App Store Connect'e gidecek mağaza sayfasını fastlane düzeninde kurar.

Metinler STORE_LISTING.md'den (tool/check_store_listing.py'nin okuduğu
aynı bloklar), ekran görüntüleri store_assets/'ten (tool/store_screenshots.py)
geliyor; burada yalnızca fastlane'in beklediği klasörlere diziliyor:

    python3 tool/asc_metadata.py            # → build/fastlane/
    fastlane deliver --api_key_path … --metadata_path build/fastlane/metadata \
        --screenshots_path build/fastlane/screenshots …   (SETUP_KEYS.md §3)

Çıktı build/ altında, depoda değil: kaynak STORE_LISTING.md ve store_assets.
"""

import re
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_store_listing import FIELD_OF_LABEL  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "build" / "fastlane"
SITE = "https://frclb.github.io/nilu"

# STORE_LISTING.md başlığı → (App Store Connect dili, site/store_assets dili).
# Portekizce Brezilya lehçesi (STORE_LISTING.md "Notlar").
LANGUAGES = {
    "Türkçe": ("tr", "tr"),
    "English": ("en-US", "en"),
    "Deutsch": ("de-DE", "de"),
    "Español": ("es-ES", "es"),
    "Français": ("fr-FR", "fr"),
    "Português": ("pt-BR", "pt"),
}

# STORE_LISTING alanı → fastlane dosyası.
FILES = {
    "name": "name.txt",
    "subtitle": "subtitle.txt",
    "promo": "promotional_text.txt",
    "description": "description.txt",
    "keywords": "keywords.txt",
}

COPYRIGHT = "2026 Hürkan Çelebi"
CATEGORY = "HEALTH_AND_FITNESS"


def parse_listing():
    """{"Türkçe": {"name": …, …}, …} — yalnızca App Store bölümleri."""
    out, language, field = {}, None, None
    lines = (ROOT / "STORE_LISTING.md").read_text(encoding="utf-8").split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("## "):
            language = line[3:].strip()
            field = None
        label = re.fullmatch(r"\*\*(.+?)\*\*", line.strip())
        if label:
            field = FIELD_OF_LABEL.get(label.group(1).strip().lower())
        if line.strip() == "```" and field in FILES and language in LANGUAGES:
            body = []
            i += 1
            while i < len(lines) and lines[i].strip() != "```":
                body.append(lines[i])
                i += 1
            out.setdefault(language, {})[field] = "\n".join(body)
            field = None
        i += 1
    return out


def main():
    listing = parse_listing()
    missing = [
        f"{lang}/{field}" for lang in LANGUAGES for field in FILES
        if field not in listing.get(lang, {})
    ]
    if missing:
        sys.exit("STORE_LISTING.md'de eksik: " + ", ".join(missing))

    if OUT.exists():
        shutil.rmtree(OUT)
    meta = OUT / "metadata"
    meta.mkdir(parents=True)
    (meta / "copyright.txt").write_text(COPYRIGHT + "\n", encoding="utf-8")
    (meta / "primary_category.txt").write_text(CATEGORY + "\n", encoding="utf-8")

    shots = 0
    for language, (locale, site_lang) in LANGUAGES.items():
        folder = meta / locale
        folder.mkdir()
        for field, name in FILES.items():
            (folder / name).write_text(listing[language][field] + "\n", encoding="utf-8")
        for name, path in (
            ("marketing_url.txt", f"{SITE}/{site_lang}/"),
            ("support_url.txt", f"{SITE}/{site_lang}/support/"),
            ("privacy_url.txt", f"{SITE}/{site_lang}/privacy/"),
        ):
            (folder / name).write_text(path + "\n", encoding="utf-8")

        # fastlane cihazı çözünürlükten anlıyor; sıra dosya adından.
        target = OUT / "screenshots" / locale
        target.mkdir(parents=True)
        for device in ("iphone_6_9", "ipad_13"):
            source = ROOT / "store_assets" / "app_store" / site_lang / device
            files = sorted(source.glob("*.png"))
            if len(files) != 10:
                sys.exit(f"{source}: 10 görsel bekleniyordu, {len(files)} var "
                         "(python3 tool/store_screenshots.py)")
            for f in files:
                shutil.copy(f, target / f"{device}_{f.name}")
                shots += 1

    print(f"{len(LANGUAGES)} dil, {shots} ekran görüntüsü → {OUT.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
