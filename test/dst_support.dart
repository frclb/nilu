import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Yaz saati testlerinin ortak parçası.
///
/// Geliştirme makinesi Türkiye saatinde ve Türkiye'de yaz saati yok: gün
/// hesabındaki saat kayması burada hiç görünmüyor. Bu yüzden yaz saatine
/// duyarlı test dosyaları `test/domain/dst_timezones_test.dart` tarafından
/// Europe/Berlin ve America/New_York saat dilimlerinde ayrı süreçte de
/// çalıştırılıyor; o süreçte bu değişken tanımlı.
const String dstChildEnv = 'NILU_DST_CHILD';

/// Yaz saati testleri: Türkiye saatinde koşan bir hesap hiçbir şey
/// sınamamış olur.
///
/// 2026'nın geçiş günleri, hepsi pazar: Avrupa'da 29 Mart ve 25 Ekim,
/// ABD'de 8 Mart ve 1 Kasım. Her test hepsinin iki yanına bakıyor; hangi
/// saat diliminde koşarsa koşsun ikisi o bölgenin geçişini aşıyor.
final List<DateTime> dstTransitions = [
  DateTime(2026, 3, 29),
  DateTime(2026, 10, 25),
  DateTime(2026, 3, 8),
  DateTime(2026, 11, 1),
];

/// [d] gününden [n] takvim günü sonrası; testin kendi hesabı, uygulamanın
/// yardımcısına bağlı değil.
DateTime dstDay(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Alt süreçte saat diliminin gerçekten uygulandığını doğrulayan test.
void expectDstZoneInChild() {
  test('alt süreçte yaz saati olan bir saat diliminde', () {
    if (Platform.environment[dstChildEnv] == null) return;
    expect(
      DateTime(2026, 1, 15).timeZoneOffset,
      isNot(DateTime(2026, 7, 15).timeZoneOffset),
      reason: 'Saat dilimi ${Platform.environment['TZ']} uygulanmadı',
    );
  });
}
