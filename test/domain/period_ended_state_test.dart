import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// "Reglim bitti"den sonraki durum.
///
/// Ana ekran aynı anda hem "Reglin bugün bitti" hem "REGL · 3. gün"
/// yazıyordu. İkisi de modelle tutarlıydı — bugün reglin son günü — ama
/// ekranın en büyük yazısı dönemin bittiğine dair hiçbir iz taşımıyordu.
///
/// Asıl sorun tek bir ekranda değildi: [CycleInfo] "dönem kapandı"
/// bilgisini hiç taşımıyordu. Fazı okuyan her yüzey (çark, günün önerisi,
/// asistan, ana ekran widget'ı) "devam ediyor" ile "bugün bitti"yi
/// birbirinden ayırt edemiyordu.
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 2));

  PeriodLog ongoing() => PeriodLog(id: 'p', startDate: start);
  PeriodLog endedToday() =>
      PeriodLog(id: 'p', startDate: start, endDate: today);
  PeriodLog endedYesterday() => PeriodLog(
    id: 'p',
    startDate: start,
    endDate: today.subtract(const Duration(days: 1)),
  );

  info(PeriodLog log) => PredictionService().getCycleInfo([log]);

  group('kapanmış dönem ayırt edilebiliyor', () {
    test('devam eden dönemin bitiş tarihi yok', () {
      expect(info(ongoing()).currentPeriodEnd, isNull);
    });

    test('bugün bitirilen dönemin bitişi bugün', () {
      expect(info(endedToday()).currentPeriodEnd, today);
    });

    test('dün bitirilen dönemin bitişi dün', () {
      expect(
        info(endedYesterday()).currentPeriodEnd,
        today.subtract(const Duration(days: 1)),
      );
    });

    test('bugün bitti mi sorusu doğrudan cevaplanıyor', () {
      // Her yüzeyin `currentPeriodEnd`'i bugünle kendi karşılaştırması,
      // aynı kıyası dört yerde tekrarlamak demekti.
      expect(info(endedToday()).periodEndedToday, isTrue);
      expect(info(ongoing()).periodEndedToday, isFalse);
      expect(info(endedYesterday()).periodEndedToday, isFalse);
    });
  });

  group('faz doğru kalıyor', () {
    test('bugün bitirilen dönemde bugün hâlâ regl günü', () {
      // Bugün kanama oldu; "Reglim bitti" son günü işaretler, silmez.
      // Fazı değiştirmek takvimi ve kaydı da yanlış gösterirdi.
      expect(info(endedToday()).currentPhase, CyclePhase.menstruation);
    });

    test('dün bitirilen dönemde bugün regl günü değil', () {
      expect(info(endedYesterday()).currentPhase, isNot(CyclePhase.menstruation));
    });
  });

  group('kayıtlı uzunluk', () {
    test('bitirilen dönem gerçek uzunluğunu bildiriyor', () {
      expect(info(endedToday()).currentPeriodLength, 3);
    });
  });
}
