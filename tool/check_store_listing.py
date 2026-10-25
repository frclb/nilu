#!/usr/bin/env python3
"""STORE_LISTING.md içindeki metinleri App Store ve Google Play sınırlarına
göre denetler.

Sınırlar App Store Connect'te kaydederken zorlanıyor: uzun bir alan
yapıştırıldığında sessizce kırpılmıyor, kaydetme reddediliyor. Altı dilde
beş alanı elle saymak yerine burada sayılıyor.

Anahtar kelimelerde ayrıca virgülden sonra boşluk aranıyor: boşluk da
100 karaktere dahil, yani her boşluk bir kelimeden çalıyor.
"""

import re
import sys
from pathlib import Path

LIMITS = {
    "name": 30,
    "subtitle": 30,
    "promo": 170,
    "keywords": 100,
    "description": 4000,
    # Google Play
    "play_title": 30,
    "play_short": 80,
    "play_full": 4000,
}

# Alan adları dile göre değişiyor; başlıktaki etiketi türe eşliyoruz.
LABELS = {
    "name": {"ad", "name", "nome", "nom", "nombre"},
    "subtitle": {"alt başlık", "subtitle", "untertitel", "subtítulo", "sous-titre"},
    "promo": {
        "tanıtım metni",
        "promotional text",
        "werbetext",
        "texto promocional",
        "texte promotionnel",
    },
    "keywords": {
        "anahtar kelimeler",
        "keywords",
        "palabras clave",
        "mots-clés",
        "palavras-chave",
    },
    "description": {
        "açıklama",
        "description",
        "beschreibung",
        "descripción",
        "descrição",
    },
    # Play alanlarının etiketi her dilde Türkçe: başlık zaten dili söylüyor.
    "play_title": {"google play başlık"},
    "play_short": {"google play kısa açıklama"},
    "play_full": {"google play tam açıklama"},
}

# Denetlenmesi beklenen diller (her biri App Store ve Google Play için).
# Biri eksik kalırsa betik düşüyor.
LANGUAGES = ("Türkçe", "English", "Deutsch", "Español", "Français", "Português")

FIELD_OF_LABEL = {
    label: field for field, labels in LABELS.items() for label in labels
}


def main() -> int:
    path = Path("STORE_LISTING.md")
    text = path.read_text(encoding="utf-8")

    # "## Dil" başlıkları altındaki "**Alan**" + ``` bloğu çiftleri.
    language = None
    field = None
    problems = []
    checked = 0

    lines = text.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]

        if line.startswith("## "):
            language = line[3:].strip()
            field = None

        label_match = re.fullmatch(r"\*\*(.+?)\*\*", line.strip())
        if label_match:
            field = FIELD_OF_LABEL.get(label_match.group(1).strip().lower())

        if line.strip() == "```" and field and language:
            body = []
            i += 1
            while i < len(lines) and lines[i].strip() != "```":
                body.append(lines[i])
                i += 1
            value = "\n".join(body)
            limit = LIMITS[field]
            checked += 1

            if len(value) > limit:
                problems.append(
                    f"{language} / {field}: {len(value)} karakter, sınır {limit}"
                )
            if field == "keywords" and ", " in value:
                problems.append(
                    f"{language} / keywords: virgülden sonra boşluk var — "
                    "boşluklar da 100 karaktere dahil"
                )
            field = None

        i += 1

    # Eksik bir etiket sessizce atlanıyordu: "Nome" listede yoktu ve
    # Portekizce ad hiç denetlenmedi, betik yine de "uyuyor" dedi.
    # Beklenen sayı tutturulmazsa yalancı geçmek yerine düşmeli.
    expected = len(LANGUAGES) * len(LIMITS)
    if checked != expected:
        print(
            f"  {checked} alan bulundu, {expected} bekleniyordu — bir etiket "
            "tanınmamış olabilir (LABELS listesine bak)."
        )
        return 1

    for problem in problems:
        print(f"  {problem}")

    if problems:
        print(f"\n{len(problems)} sorun, {checked} alan denetlendi.")
        return 1

    print(f"Mağaza metinleri sınırlara uyuyor ({checked} alan).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
