import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `SharedPreferences.clear()` yalnızca hesap silmede çağrılabilir.
///
/// Profil ekranında "Önbelleği Temizle" diye bir düğme vardı ve
/// `prefs.clear()` çağırıyordu. Diyalog "tüm önbellek verileri
/// silinecektir" diyordu ama silinenler tercihlerdi: onboarding durumu,
/// bildirim ayarları, partner bağı ve **ekran kilidi**. Kullanıcının regl
/// verisini korumak için açtığı kilit, "önbellek" yazan bir düğmeyle
/// kapanıyordu.
///
/// Temizlenecek bir önbellek de yoktu — `SharedPreferences`'taki her
/// anahtar bir tercih ya da durum. Düğme kaldırıldı.
///
/// Bu test çağrının geri gelmesini engelliyor: her şeyi silmek yalnızca
/// "Hesabımı Sil" akışının işi, ve orası ne yaptığını söylüyor.
void main() {
  test('prefs.clear() yalnızca hesap silmede', () {
    const izinli = 'lib/data/repositories/privacy_settings_repository.dart';
    final cagiranlar = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path == izinli) continue;

      final satirlar = entity.readAsLinesSync();
      for (var i = 0; i < satirlar.length; i++) {
        final kod = satirlar[i].split('//').first;
        if (RegExp(r'\bprefs\.clear\(\)').hasMatch(kod)) {
          cagiranlar.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      cagiranlar,
      isEmpty,
      reason:
          'Tüm tercihleri silmek yalnızca hesap silme akışının işi. '
          'Başka bir yerden çağrılırsa kullanıcı ne kaybettiğini '
          'bilmeden kaybeder:\n${cagiranlar.join('\n')}',
    );
  });
}
