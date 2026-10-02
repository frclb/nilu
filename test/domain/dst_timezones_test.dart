import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../dst_support.dart';

/// Yaz saatine duyarlı testleri yaz saati olan saat dilimlerinde çalıştırır.
///
/// Geliştirme makinesi Türkiye saatinde; Türkiye'de yaz saati yok ve gün
/// hesabındaki saat kayması hiçbir testte görünmüyordu. Gün eklemek ve gün
/// farkı saymak saatle yapıldığında Berlin'de 26 Şubat → 1 Nisan döngüsü
/// 33 gün sayılıyor, tahmini doğum bir gün erken kaydediliyordu.
///
/// Aşağıdaki dosyalar ayrı bir süreçte Europe/Berlin ve America/New_York
/// saat dilimleriyle yeniden koşuyor (ikisi de 2026'da farklı pazarlarda
/// saat değiştiriyor). Alt süreçte her dosya saat diliminin gerçekten
/// uygulandığını kendisi doğruluyor (`expectDstZoneInChild`).
void main() {
  const dosyalar = [
    'test/domain/dst_dates_test.dart',
    'test/domain/dst_cycle_test.dart',
    'test/presentation/dst_calendar_grid_test.dart',
  ];

  for (final tz in ['Europe/Berlin', 'America/New_York']) {
    test(tz, () async {
      final r = await Process.run(
        'flutter',
        ['test', ...dosyalar],
        environment: {'TZ': tz, dstChildEnv: '1'},
      );
      expect(r.exitCode, 0, reason: '$tz:\n${r.stdout}\n${r.stderr}');
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
}
