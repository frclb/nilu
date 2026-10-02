import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/localization/app_localizations.dart';

/// Büyük harfli başlıklar dile göre mi büyütülüyor?
///
/// `String.toUpperCase()` Türkçede yanlış: "i"nin büyüğü "İ", Dart "I"
/// yazıyor. Profil ekranında "DIĞER", gecikmede ana ekranda "3 GÜN
/// GECIKTI", gebelik panosunda "2. TRIMESTER" görünüyordu.
void main() {
  test('Türkçede noktalı i büyüyünce noktalı kalıyor', () {
    expect(upperFor('tr', 'Gizlilik'), 'GİZLİLİK');
    expect(upperFor('tr', 'Diğer'), 'DİĞER');
    expect(upperFor('tr', '3 gün gecikti'), '3 GÜN GECİKTİ');
    // Noktasız ı'nın büyüğü I — ona dokunulmamalı.
    expect(upperFor('tr', 'Sıradaki'), 'SIRADAKİ');
  });

  test('diğer dillerde i → I', () {
    expect(upperFor('en', 'Coming up'), 'COMING UP');
    expect(upperFor('de', 'Termine'), 'TERMINE');
    expect(upperFor('fr', 'Prochain'), 'PROCHAIN');
    expect(upperFor(null, 'mix'), 'MIX');
  });

  test('arayüz kodu metni doğrudan toUpperCase ile büyütmüyor', () {
    // Gerekçesi yazılı istisnalar.
    const izinli = {
      // Marka adı: her dilde aynı yazılmalı ("NİLU" değil).
      'lib/presentation/onboarding_welcome/onboarding_success_screen.dart',
    };

    final ihlal = <String>[];
    for (final kok in ['lib/presentation', 'lib/design_system']) {
      for (final f in Directory(kok).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (izinli.contains(f.path)) continue;
        final satirlar = f.readAsLinesSync();
        for (var i = 0; i < satirlar.length; i++) {
          if (satirlar[i].contains('.toUpperCase()')) {
            ihlal.add('${f.path}:${i + 1}');
          }
        }
      }
    }
    expect(
      ihlal,
      isEmpty,
      reason:
          'Ekrandaki metin `context.upper(...)` ile büyütülmeli; '
          'Türkçede "i" → "I" oluyor:\n${ihlal.join('\n')}',
    );
  });
}
