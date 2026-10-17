import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/prediction_basis.dart';
import 'package:period_tracker/domain/services/cycle_intervals.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Tahmin aralığı ve dayanağı: ekranda söylenen her cümlenin karşılığı.
void main() {
  final bugun = DateTime(2026, 10, 18);

  /// Verilen döngü uzunluklarıyla, son başlangıcı [sonBaslangicOnce] gün
  /// önce olan kayıtlar.
  List<PeriodLog> kayitlar(List<int> uzunluklar, {int sonBaslangicOnce = 5}) {
    var bas = DateTime(bugun.year, bugun.month, bugun.day - sonBaslangicOnce);
    final baslangiclar = [bas];
    for (final u in uzunluklar.reversed) {
      bas = DateTime(bas.year, bas.month, bas.day - u);
      baslangiclar.insert(0, bas);
    }
    return [
      for (var i = 0; i < baslangiclar.length; i++)
        PeriodLog(
          id: '$i',
          startDate: baslangiclar[i],
          endDate: DateTime(
            baslangiclar[i].year,
            baslangiclar[i].month,
            baslangiclar[i].day + 4,
          ),
        ),
    ];
  }

  CycleInfo hesapla(
    List<PeriodLog> logs, {
    bool kullanici = true,
    int ayar = 28,
    DateTime? ayarTarihi,
    List<DateSpan> breaks = const [],
  }) => PredictionService().getCycleInfo(
    logs,
    userCycleLength: ayar,
    settingsUpdatedAt: ayarTarihi,
    cycleLengthFromUser: kullanici,
    today: bugun,
    breaks: breaks,
  );

  DateTime gun(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

  test('hiç bilgi yok: 28 gün varsayımı, iki yana 3 gün', () {
    final info = hesapla(kayitlar(const []), kullanici: false);
    final b = info.basis!;
    expect(b.source, PredictionSource.assumed);
    expect(b.cycleLength, 28);
    expect(b.earliest, gun(info.predictedNextPeriod!, -3));
    expect(b.latest, gun(info.predictedNextPeriod!, 3));
  });

  test('kullanıcının girdiği süre: iki yana 2 gün', () {
    final info = hesapla(kayitlar(const []), ayar: 31);
    final b = info.basis!;
    expect(b.source, PredictionSource.settings);
    expect(b.cycleLength, 31);
    expect(b.latest.difference(b.earliest).inDays, 4);
  });

  test('iki döngü: kendi geçmişi ama aralık için yetersiz', () {
    final b = hesapla(kayitlar(const [27, 29])).basis!;
    expect(b.source, PredictionSource.history);
    expect(b.cyclesConsidered, 2);
    expect(b.rangeFromHistory, isFalse);
    expect(b.latest.difference(b.earliest).inDays, 4);
  });

  test('yeterli geçmiş: en kısa ve en uzun döngü', () {
    final logs = kayitlar(const [26, 30, 28, 29]);
    final info = hesapla(logs);
    final b = info.basis!;
    final son = logs.last.startDate;
    expect(b.source, PredictionSource.history);
    expect(b.cyclesAveraged, 3);
    expect(b.cycleLength, 29, reason: 'Son üçün ortalaması (30+28+29)/3');
    expect((b.shortest, b.longest), (26, 30));
    expect(b.earliest, gun(son, 26));
    expect(b.latest, gun(son, 30));
    expect(b.isIrregular, isFalse);
  });

  test('tamamen düzenli döngüde de bir gün pay', () {
    final logs = kayitlar(const [28, 28, 28]);
    final b = hesapla(logs).basis!;
    final son = logs.last.startDate;
    expect(b.earliest, gun(son, 27));
    expect(b.latest, gun(son, 29));
  });

  test('aralık son altı döngüden; eski uç değerler düşüyor', () {
    final b = hesapla(kayitlar(const [40, 28, 29, 27, 28, 30, 29])).basis!;
    expect(b.cyclesConsidered, 6);
    expect(b.longest, 30, reason: '40 günlük döngü yedi döngü önceydi');
  });

  test('döngüler arası fark 7 günü aşınca düzensiz', () {
    final b = hesapla(kayitlar(const [24, 35, 27])).basis!;
    expect(b.isIrregular, isTrue);
  });

  test('ayar son başlangıçtan önce değiştiyse ayar kullanılıyor', () {
    // Ayar 10 gün önce değişti, son regl 5 gün önce başladı: bu döngü yeni
    // ayarla sayılıyor (bkz. `PredictionService`).
    final logs = kayitlar(const [26, 30, 28, 29]);
    final b = hesapla(logs, ayar: 32, ayarTarihi: gun(bugun, -10)).basis!;
    expect(b.source, PredictionSource.settings);
    expect(b.cycleLength, 32);
  });

  test('en olası gün her durumda aralığın içinde', () {
    for (final u in const [
      <int>[],
      [21],
      [35, 22],
      [22, 23, 45],
      [30, 30, 30, 30],
      [26, 33, 29, 24, 31],
    ]) {
      for (final kullanici in [true, false]) {
        final info = hesapla(kayitlar(u), kullanici: kullanici);
        final b = info.basis!;
        final n = info.predictedNextPeriod!;
        expect(!b.earliest.isAfter(n) && !b.latest.isBefore(n), isTrue);
        expect(b.earliest.isBefore(b.latest), isTrue, reason: '$u');
      }
    }
  });

  test('tahmin yoksa dayanak da yok', () {
    expect(hesapla(const []).basis, isNull);
  });
}
