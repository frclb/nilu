import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/care_templates.dart';

/// Bildirimde kullanılan her anahtar altı dilde de tanımlı mı?
///
/// Lokalizasyon denetçisi (`tool/check_localization.dart`) yalnızca
/// `context.tr('...')` çağrılarını görüyor. Hatırlatıcı planlayıcısı ise
/// anahtarı `titleKey`/`bodyKey` alanında taşıyor ve çeviriyi cihaz
/// bildirimi yazarken yapıyor — denetçinin görüş alanının dışında.
/// Tanımsız bir anahtar çevrilemeyince kilit ekranına olduğu gibi düşer:
/// "notif_care_window_body". Bu, uygulamayı bozuk gösteren en görünür hata.
void main() {
  const diller = ['tr', 'en', 'de', 'fr', 'es', 'pt'];
  final sozlukler = {
    for (final d in diller)
      d:
          (jsonDecode(File('lib/localization/$d.json').readAsStringSync())
                  as Map<String, dynamic>)
              .keys
              .toSet(),
  };

  /// Planlayıcının üretebileceği bütün anahtarlar.
  Set<String> planlayiciAnahtarlari() {
    final kaynak = File(
      'lib/domain/services/reminder_planner.dart',
    ).readAsStringSync();
    final sabit = RegExp(
      r"'((?:notif|care)_[a-z_]+)'",
    ).allMatches(kaynak).map((m) => m.group(1)!).toSet();

    final sablon = {
      for (final k in [
        ...CareTemplates.turkeyAntenatal,
        ...CareTemplates.turkeyPostnatal,
      ]) ...{'care_${k.code}_title', ?k.conditionKey},
    };
    return {...sabit, ...sablon};
  }

  test('planlayıcı anahtarları bulunuyor', () {
    // Tarama hiçbir şey bulamazsa aşağıdaki test boşa geçer.
    final a = planlayiciAnahtarlari();
    expect(a, contains('notif_period_body'));
    expect(a, contains('care_tr_screen_anomaly_title'));
    expect(a, contains('notif_discreet_title'));
  });

  for (final dil in diller) {
    test('$dil: her bildirim anahtarı tanımlı', () {
      final eksik = planlayiciAnahtarlari().difference(sozlukler[dil]!);
      expect(
        eksik,
        isEmpty,
        reason:
            '$dil sözlüğünde tanımsız; bildirimde anahtarın kendisi '
            'görünür:\n${eksik.join('\n')}',
      );
    });
  }
}
