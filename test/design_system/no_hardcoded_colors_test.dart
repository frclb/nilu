import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sunum katmanında sabit renk kalmamalı.
///
/// Premium tema çeşitleri (ocean/forest/graphite) tek bir token katmanından
/// besleniyor. Bir ekran rengi sabit yazdığında o ekran temayı takip etmiyor:
/// kullanıcı ödediği temayı seçiyor ama partner/tarif/yoga ekranları marka
/// pembesinde kalıyordu.
///
/// Üç sabit renk biçimi de yakalanıyor:
///
/// * `Color(0x…)` — ham değer.
/// * `Colors.…` — Material'in kendi paleti. Bunlar `Color(0x…)` kadar
///   körlerdi ama eski denetim onları görmüyordu; `Colors.grey.shade700`
///   koyu temada da gri kalıyordu.
/// * `AppColors.…` — eski isim köprüsü. Değerleri açık temaya sabitlenmiş;
///   `AppColors.textMainSlate` koyu temada da koyu metin veriyordu.
/// * `AppPalette.…` — ham palet. Tema değil ton seçiyor: premium çeşitler
///   (ocean/forest/graphite) marka rengini değiştirdiğinde bu ekranlar plum
///   tonlarında kalıyordu.
///
/// Bilerek sabit kalan renkler için tasarım sisteminde `AppScrim` var:
/// fotoğraf, video ve kamera görüntüsü üzerindeki katmanlar. Onların altındaki
/// görüntü temayı takip etmediği için renkleri de etmiyor.
void main() {
  test('sunum katmanında sabit renk yok', () {
    // Video üzerindeki karartma teması takip etmemeli — her temada siyah.
    const allowed = {'lib/presentation/yoga/widgets/yoga_video_player.dart'};

    // `Colors.transparent` bir renk değil, rengin yokluğu.
    final patterns = <RegExp>[
      RegExp(r'Color\(0x'),
      RegExp(r'\bColors\.(?!transparent\b)[a-zA-Z]'),
      RegExp(r'\bAppColors\.'),
      RegExp(r'\bAppPalette\.'),
    ];

    final offenders = <String>[];

    for (final dir in ['lib/presentation', 'lib/core']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final path = entity.path;
        if (allowed.contains(path)) continue;

        var inBlockComment = false;
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trimLeft();

          // Yorumlar kod değil: açıklamada geçen `Colors.red` sayılmamalı.
          if (inBlockComment) {
            if (trimmed.contains('*/')) inBlockComment = false;
            continue;
          }
          if (trimmed.startsWith('/*')) {
            if (!trimmed.contains('*/')) inBlockComment = true;
            continue;
          }
          if (trimmed.startsWith('//')) continue;

          final code = line.split('//').first;
          if (patterns.any((p) => p.hasMatch(code))) {
            offenders.add('$path:${i + 1}: ${line.trim()}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Sabit renk yerine context.tokens (rol rengi), '
          'Theme.of(context).colorScheme (marka) ya da '
          'AppScrim (fotoğraf/kamera üstü) kullan:\n${offenders.join('\n')}',
    );
  });
}
