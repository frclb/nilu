# Açılış ekranı görselleri

Bu klasördeki PNG'ler ve `Contents.json` **üretiliyor** — elle düzenlemeyin:

    python3 tool/generate_launch_image.py

Lotusun şekli `tool/lotus.py` içinde, uygulama ikonuyla ortak. Renkler
`lib/design_system/app_palette.dart` ile aynı olmak zorunda;
`test/launch_screen_test.dart` ikisini karşılaştırıyor.
