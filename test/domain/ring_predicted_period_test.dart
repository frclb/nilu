import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Çelenk, **yaşanmış** regl gününü **tahmin edilen**den ayırıyor mu?
///
/// Takvim ayırıyor: kayıtlı gün `flow` ile dolu, devamı beklenen gün ince bir
/// tül (`predictedBandColor`). Çelenk ikisini de aynı renge boyuyordu, yani
/// reglin **ilk** günündeki kullanıcıya planladığı yedi günün tamamı olmuş
/// gibi görünüyordu. Aynı veriden iki ekranda iki farklı cevap; oturum
/// boyunca bulunan hataların çoğu bu desendi.
///
/// `ring_calendar_sync_test` bunu göremiyordu: orada takvim tarafı
/// `containsRecorded || isExpectedContinuation` olarak hesaplanıyor, yani
/// kayıt ile tahmin tek torbaya giriyor.
void main() {
  final bugun = DateTime(2026, 9, 27);
  DateTime g(int gun) => DateTime(2026, 9, gun);

  CycleInfo bilgi({
    required int kayitli,
    int planlanan = 7,
    bool bitti = false,
  }) {
    final start = g(27 - (kayitli - 1));
    return PredictionService().getCycleInfo(
      [PeriodLog(id: 'p', startDate: start, endDate: bitti ? bugun : null)],
      userCycleLength: 28,
      userPeriodLength: planlanan,
      today: bugun,
    );
  }

  test('süren reglde kaydın ötesi tahmin sayılıyor', () {
    final info = bilgi(kayitli: 3, planlanan: 7);

    for (var gun = 1; gun <= 3; gun++) {
      expect(
        info.isPredictedPeriodRingDay(gun),
        isFalse,
        reason: '$gun. gün kayıtlı — tahmin gibi gösterilmemeli',
      );
    }
    for (var gun = 4; gun <= 7; gun++) {
      expect(
        info.isPredictedPeriodRingDay(gun),
        isTrue,
        reason:
            '$gun. gün henüz yaşanmadı; takvim onu tül ile çiziyor, çelenk de '
            'kesinmiş gibi göstermemeli',
      );
    }
    expect(info.isPredictedPeriodRingDay(8), isFalse, reason: 'regl dışı');
  });

  test('ilk gün: altı günün tamamı tahmin', () {
    final info = bilgi(kayitli: 1, planlanan: 7);
    expect(info.isPredictedPeriodRingDay(1), isFalse);
    for (var gun = 2; gun <= 7; gun++) {
      expect(info.isPredictedPeriodRingDay(gun), isTrue, reason: '$gun. gün');
    }
  });

  test('regl bitirildiğinde tahmin kalmıyor', () {
    final info = bilgi(kayitli: 3, planlanan: 7, bitti: true);
    for (var gun = 1; gun <= 10; gun++) {
      expect(
        info.isPredictedPeriodRingDay(gun),
        isFalse,
        reason:
            '$gun. gün: dönem kapandı, kayıt kesin — tahmin edilecek gün yok',
      );
    }
  });

  test('planlanandan uzun süren reglde tahmin yok', () {
    // Kayıt planlanandan uzun: halka zaten yalnızca yaşanmış günleri
    // gösteriyor, tahmin edilecek bir gün kalmıyor.
    final info = bilgi(kayitli: 9, planlanan: 7);
    for (var gun = 1; gun <= 12; gun++) {
      expect(info.isPredictedPeriodRingDay(gun), isFalse, reason: '$gun. gün');
    }
  });

  test('kayıt yokken tahmin işaretlenmiyor', () {
    final info = PredictionService().getCycleInfo(
      const [],
      userCycleLength: 28,
      userPeriodLength: 7,
      today: bugun,
    );
    for (var gun = 1; gun <= 10; gun++) {
      expect(info.isPredictedPeriodRingDay(gun), isFalse);
    }
  });
}
