import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Takvimde bir günün **çizilen** hâli tutarlı mı?
///
/// Model bir güne aynı anda birden çok şey diyebiliyor — kısa döngüde
/// doğurganlık penceresi regl günlerine taşıyor, bu biyolojik olarak da
/// doğru. Önemli olan modelin ne dediği değil, hücrede ne göründüğü:
/// `calendar_grid.dart` doğurganlık noktasını regl gününde çizmiyor
/// (`isFertile && !isPeriod`), yumurtlama noktasını çiziyor.
///
/// Bu test o kuralları modelin üstüne uygulayıp sonucun tutarlı kaldığını
/// sınıyor. Kural değişirse burası düşer.
void main() {
  final bugun = DateTime(2026, 9, 27);
  DateTime g(int gun) => DateTime(2026, 9, gun);
  PeriodLog log(DateTime s, [DateTime? e]) =>
      PeriodLog(id: s.toIso8601String(), startDate: s, endDate: e);

  /// Bir hücrede gerçekten çizilenler.
  ({bool bant, bool tahminBant, bool yumurtlamaNoktasi, bool dogurganNoktasi})
  cizilen(CycleInfo info, List<PeriodLog> logs, DateTime d, int ayarliSure) {
    final kayitli = logs.any((l) => l.containsRecorded(d, today: bugun));
    final tahmin =
        info.isPredictedPeriod(d) ||
        logs.any(
          (l) => l.isExpectedContinuation(
            d,
            today: bugun,
            expectedLength: ayarliSure,
          ),
        );
    // Widget `if (isOvulation) … else if (isFertile && !isPeriod)` yazıyor:
    // yumurtlama günü doğurganlık noktası zaten çizilmiyor.
    final yumurtlama = info.isOvulationDay(d);
    return (
      bant: kayitli,
      tahminBant: tahmin && !kayitli,
      yumurtlamaNoktasi: yumurtlama,
      dogurganNoktasi: !yumurtlama && info.isFertile(d) && !kayitli,
    );
  }

  List<String> tara({
    required List<PeriodLog> logs,
    int userCycleLength = 27,
    int userPeriodLength = 7,
    bool hormonal = false,
  }) {
    final info = PredictionService().getCycleInfo(
      logs,
      userCycleLength: userCycleLength,
      userPeriodLength: userPeriodLength,
      hormonalContraception: hormonal,
      today: bugun,
    );

    final sorun = <String>[];
    for (var i = -60; i < 150; i++) {
      final d = DateTime(bugun.year, bugun.month, bugun.day + i);
      final c = cizilen(info, logs, d, userPeriodLength);
      final t = '${d.day}.${d.month}';

      // Aynı gün hem dolu hem soluk bant olamaz.
      if (c.bant && c.tahminBant) sorun.add('$t: hem dolu hem soluk bant');

      // İki nokta aynı anda çizilirse hangisi olduğu okunmaz.
      if (c.yumurtlamaNoktasi && c.dogurganNoktasi) {
        sorun.add('$t: yumurtlama ve doğurganlık noktası birlikte');
      }

      // Yumurtlama doğurganlık penceresinin içinde olmalı.
      if (c.yumurtlamaNoktasi && !info.isFertile(d)) {
        sorun.add('$t: yumurtlama, doğurganlık penceresi dışında');
      }

      // Hormonal doğum kontrolünde yumurtlama baskılanıyor; tahmin
      // gösterilmesi yanıltıcı olurdu.
      if (hormonal && (c.yumurtlamaNoktasi || c.dogurganNoktasi)) {
        sorun.add('$t: hormonalde doğurganlık göstergesi');
      }

      // Tahmin edilen regl, kayıtlı reglin üstüne binmemeli.
      if (info.isPredictedPeriod(d) &&
          logs.any((l) => l.containsRecorded(d, today: bugun))) {
        sorun.add('$t: tahmin kayıtlı reglin üstünde');
      }
    }
    return sorun;
  }

  void tutarli(
    String ad, {
    required List<PeriodLog> logs,
    int userCycleLength = 27,
    int userPeriodLength = 7,
    bool hormonal = false,
  }) {
    test(ad, () {
      final s = tara(
        logs: logs,
        userCycleLength: userCycleLength,
        userPeriodLength: userPeriodLength,
        hormonal: hormonal,
      );
      expect(s.toSet(), isEmpty, reason: s.toSet().join('\n'));
    });
  }

  group('takvim hücresi tutarlı', () {
    tutarli('kayıt yok', logs: []);
    tutarli('regl bugün başladı', logs: [log(g(27))]);
    tutarli('sürüyor, 4. gün', logs: [log(g(24))]);
    tutarli('bugün bitirildi', logs: [log(g(24), g(27))]);
    tutarli('bitti, foliküler', logs: [log(g(15), g(21))]);
    tutarli('bitti, yumurtlama civarı', logs: [log(g(10), g(16))]);
    tutarli(
      'gecikmiş (30. gün)',
      logs: [log(DateTime(2026, 8, 29), DateTime(2026, 9, 4))],
    );
    tutarli(
      'çok gecikmiş (45. gün)',
      logs: [log(DateTime(2026, 8, 14), DateTime(2026, 8, 20))],
    );
    tutarli('hormonal, sürüyor', logs: [log(g(24))], hormonal: true);
    tutarli('hormonal, bitmiş', logs: [log(g(15), g(21))], hormonal: true);

    // Kısa döngüde doğurganlık penceresi regl günlerine taşıyor. Model
    // doğru söylüyor; hücre doğurganlık noktasını regl gününde çizmediği
    // için ekran yine okunur kalıyor.
    tutarli('kısa döngü (21)', logs: [log(g(24))], userCycleLength: 21);
    tutarli(
      'kısa döngü, uzun regl',
      logs: [log(g(24))],
      userCycleLength: 21,
      userPeriodLength: 10,
    );
    tutarli(
      'en kısa döngü, en uzun regl',
      logs: [log(g(24))],
      userCycleLength: 20,
      userPeriodLength: 10,
    );

    tutarli(
      'ay sınırını aşan regl',
      logs: [log(DateTime(2026, 8, 29), DateTime(2026, 9, 4)), log(g(26))],
    );
    tutarli(
      'yıl sınırını aşan tahmin',
      logs: [log(DateTime(2026, 12, 20), DateTime(2026, 12, 26))],
    );
    tutarli(
      'uzun düzenli geçmiş',
      logs: [
        for (var ay = 3; ay <= 8; ay++)
          log(DateTime(2026, ay, 1), DateTime(2026, ay, 7)),
        log(g(24)),
      ],
    );
    tutarli(
      'düzensiz geçmiş',
      logs: [
        log(DateTime(2026, 5, 3), DateTime(2026, 5, 9)),
        log(DateTime(2026, 6, 20), DateTime(2026, 6, 23)),
        log(DateTime(2026, 8, 2), DateTime(2026, 8, 12)),
        log(g(24)),
      ],
    );
    tutarli(
      'yalnızca çok eski kayıt',
      logs: [log(DateTime(2025, 1, 5), DateTime(2025, 1, 11))],
    );
  });

  group('tahmin zinciri', () {
    test('tahmin edilen regller döngü boyu aralıklı', () {
      final info = PredictionService().getCycleInfo(
        [log(g(24), g(30))],
        userCycleLength: 27,
        userPeriodLength: 7,
        today: bugun,
      );
      // Zincirin ilk halkası bir sonraki regl. Eskiden zincir ondan
      // **sonra** başlıyordu ve o döngünün doğurganlık penceresi hiç
      // üretilmiyordu.
      expect(
        info.futurePredictions.first.startDate,
        info.predictedNextPeriod,
        reason: 'zincir bir sonraki reglle başlamıyor',
      );

      final baslangiclar = info.futurePredictions
          .map((p) => p.startDate)
          .toList();
      expect(baslangiclar.length, greaterThan(2));

      for (var i = 1; i < baslangiclar.length; i++) {
        expect(
          baslangiclar[i].difference(baslangiclar[i - 1]).inDays,
          27,
          reason: 'tahmin aralığı döngü boyundan farklı',
        );
      }
    });

    test('hormonalde yumurtlama tahmini üretilmiyor', () {
      final info = PredictionService().getCycleInfo(
        [log(g(24))],
        userCycleLength: 27,
        userPeriodLength: 7,
        hormonalContraception: true,
        today: bugun,
      );
      expect(info.ovulationDay, isNull);
      expect(info.fertileWindowStart, isNull);
      expect(
        info.futurePredictions.every((p) => p.ovulationDay == null),
        isTrue,
      );
    });
  });
}
