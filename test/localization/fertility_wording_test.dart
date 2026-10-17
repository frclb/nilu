import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Gün sayfasındaki doğurganlık satırı.
///
/// "Doğurganlık Şansı: Düşük" yazıyordu: takvim hesabından çıkan bir
/// tahmin, kesin bilgi gibi. Bu satırı "korunmasız ilişki için güvenli"
/// diye okuyan kullanıcı için uygulama bir doğum kontrol yöntemi
/// gibi davranıyordu; mağaza metni ve Şartlar ise öyle olmadığını
/// söylüyor.
void main() {
  // Dile göre "doğum kontrolü" kökü.
  const korunma = {
    'tr': 'doğum kontrol',
    'en': 'contracept',
    'de': 'Verhütung',
    'es': 'anticoncep',
    'fr': 'contraception',
    'pt': 'contracep',
  };
  // Dile göre "tahmini" kökü.
  const tahmin = {
    'tr': 'Tahmini',
    'en': 'stimated',
    'de': 'eschätzt',
    'es': 'stimad',
    'fr': 'stimé',
    'pt': 'stimad',
  };

  for (final dil in korunma.keys) {
    test('$dil: tahmin olduğu ve korunma için kullanılamayacağı yazıyor', () {
      final s =
          jsonDecode(File('lib/localization/$dil.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final k in [
        'day_detail_fertility_peak',
        'day_detail_fertility_high',
        'day_detail_fertility_low',
        // Ana ekran ajandası: "Doğurgan dönem başlıyor" kesin bir takvim
        // olayı gibi okunuyordu.
        'agenda_fertile_start',
        'agenda_ovulation',
      ]) {
        expect(s[k], contains(tahmin[dil]), reason: '$dil $k');
      }
      expect(
        (s['day_detail_fertility_low'] as String).toLowerCase(),
        contains(korunma[dil]!.toLowerCase()),
      );
    });
  }
}
