import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/period_service.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Ana ekranın başlığı ile "Reglim başladı / bitti" düğmesi aynı soruyu
/// soruyor: bugün kanama var mı? İkisi farklı kaynağa bakarsa ekran kendi
/// kendini yalanlıyor ve düğme işlevsiz görünüyor — basılıyor, başlık
/// değişmiyor.
///
/// Düğmenin kaynağı `PeriodLog.contains`, başlığınki `CycleInfo.currentPhase`.
/// Bu dosya ikisini yan yana koyup aynı cevabı verdiklerini doğruluyor.
void main() {
  final service = PredictionService();

  DateTime dayAt(int daysAgo) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - daysAgo);
  }

  bool bleedingToday(List<PeriodLog> logs, int userPeriodLength) {
    final today = dayAt(0);
    return logs.any((l) => l.contains(today, ongoingLength: userPeriodLength));
  }

  group('başlık ile düğme aynı şeyi söyler', () {
    test('takvimde kısaltılan regl başlıktan da düşer', () {
      // Önceki iki döngü 5 gün sürmüş. Kullanıcı takvimde bu döngünün
      // bugününü ve dünkü gününü sildi: kayıt 2 günde bitti, bugün döngünün
      // 3. günü. Ortalamayı geçmiş çektiği için başlık "REGL / 3. gün"
      // diyordu, düğme ise "Reglim başladı".
      final logs = [
        PeriodLog(id: 'a', startDate: dayAt(58), endDate: dayAt(54)),
        PeriodLog(id: 'b', startDate: dayAt(30), endDate: dayAt(26)),
        PeriodLog(id: 'c', startDate: dayAt(2), endDate: dayAt(1)),
      ];

      final info = service.getCycleInfo(logs, userPeriodLength: 5);

      expect(info.currentCycleDay, 3);
      expect(bleedingToday(logs, 5), isFalse);
      expect(info.currentPhase, isNot(CyclePhase.menstruation));
    });

    test('ortalamadan uzun süren regl başlıkta da regl kalır', () {
      // Önceki iki döngü 3 gün sürmüş, ortalama 3. Bu döngü uzadı ve
      // kullanıcı bugünü de regl olarak işaretledi. Düğme "Reglim bitti"
      // derken başlığın "Foliküler faz" demesi aynı çelişkinin diğer yüzü.
      final logs = [
        PeriodLog(id: 'a', startDate: dayAt(61), endDate: dayAt(59)),
        PeriodLog(id: 'b', startDate: dayAt(33), endDate: dayAt(31)),
        PeriodLog(id: 'c', startDate: dayAt(5), endDate: dayAt(0)),
      ];

      final info = service.getCycleInfo(logs, userPeriodLength: 5);

      expect(info.currentCycleDay, 6);
      expect(
        info.averagePeriodLength,
        lessThan(6),
        reason: 'ortalama, bu döngünün gerçek uzunluğunun altında',
      );
      expect(bleedingToday(logs, 5), isTrue);
      expect(info.currentPhase, CyclePhase.menstruation);
    });

    test('devam eden kayıt kullanıcının regl süresi kadar projekte edilir', () {
      // Bitiş girilmemiş: `contains` kullanıcının ayarını kullanıyor.
      // Başlık da aynı sayıyı kullanmalı, geçmişin ortalamasını değil.
      final logs = [
        PeriodLog(id: 'a', startDate: dayAt(60), endDate: dayAt(52)),
        PeriodLog(id: 'b', startDate: dayAt(32), endDate: dayAt(24)),
        PeriodLog(id: 'c', startDate: dayAt(6), endDate: null),
      ];

      final info = service.getCycleInfo(logs, userPeriodLength: 4);

      expect(info.averagePeriodLength, 9, reason: 'geçmiş ortalaması 9 gün');
      expect(info.currentCycleDay, 7);
      expect(bleedingToday(logs, 4), isFalse);
      expect(info.currentPhase, isNot(CyclePhase.menstruation));
    });

    test('regl günü her iki kaynakta da regl', () {
      final logs = [PeriodLog(id: 'a', startDate: dayAt(1), endDate: null)];

      final info = service.getCycleInfo(logs, userPeriodLength: 5);

      expect(bleedingToday(logs, 5), isTrue);
      expect(info.currentPhase, CyclePhase.menstruation);
    });
  });

  group('düğmeye basınca ekran gerçekten değişir', () {
    final periods = PeriodService();

    /// Ana ekranın düğmesinin yaptığı işin aynısı.
    List<PeriodLog> tapToggle(List<PeriodLog> logs, int userPeriodLength) =>
        periods.toggleDay(
          logs,
          dayAt(0),
          ongoingLength: userPeriodLength,
          today: dayAt(0),
        );

    test('"Reglim bitti" gelecekte başlayan bir dönem bırakmaz', () {
      // Onboarding'in ürettiği kayıt bugünün ötesine uzanıyor: 2 gün önce
      // başladı, 5 gün sürecek. Bugünü çıkarmak dönemi ikiye bölüyor ve
      // ikinci parça yarın başlıyordu; `lastPeriodStart` geleceğe kayınca
      // döngü günü null oluyor, başlık ile çelenk boşalıyordu.
      final start = dayAt(2);
      final logs = [
        PeriodLog(
          id: 'a',
          startDate: start,
          endDate: start.add(const Duration(days: 4)),
        ),
      ];

      final after = tapToggle(logs, 5);

      expect(after, hasLength(1));
      expect(after.single.endDate, dayAt(1));
      expect(
        after.every((l) => !l.startDate.isAfter(dayAt(0))),
        isTrue,
        reason: 'gelecekte başlayan dönem kalmamalı',
      );

      final info = service.getCycleInfo(after, userPeriodLength: 5);
      expect(info.currentCycleDay, 3, reason: 'sayaç kaybolmamalı');
      expect(info.currentPhase, isNot(CyclePhase.unknown));
      expect(bleedingToday(after, 5), isFalse);
      expect(info.currentPhase, isNot(CyclePhase.menstruation));
    });

    test('bitir → başlat gidiş dönüşünde başlık her adımda değişir', () {
      final start = dayAt(2);
      var logs = <PeriodLog>[
        PeriodLog(
          id: 'a',
          startDate: start,
          endDate: start.add(const Duration(days: 4)),
        ),
      ];

      var info = service.getCycleInfo(logs, userPeriodLength: 5);
      expect(info.currentPhase, CyclePhase.menstruation);
      expect(bleedingToday(logs, 5), isTrue);

      // "Reglim bitti"
      logs = tapToggle(logs, 5);
      info = service.getCycleInfo(logs, userPeriodLength: 5);
      expect(bleedingToday(logs, 5), isFalse);
      expect(info.currentPhase, isNot(CyclePhase.menstruation));

      // "Reglim başladı" — dün bitmiş döneme bitişik olduğu için ona eklenir
      logs = tapToggle(logs, 5);
      info = service.getCycleInfo(logs, userPeriodLength: 5);
      expect(bleedingToday(logs, 5), isTrue);
      expect(info.currentPhase, CyclePhase.menstruation);
      expect(info.currentCycleDay, 3);
    });

    test('devam eden kayıtta "Reglim bitti" kaydı kapatır, bölmez', () {
      final logs = [PeriodLog(id: 'a', startDate: dayAt(2), endDate: null)];

      final after = tapToggle(logs, 5);

      expect(after, hasLength(1));
      expect(after.single.endDate, dayAt(1));
      expect(bleedingToday(after, 5), isFalse);
    });

    test('geçmişteki bir gün silinince dönem hâlâ ikiye ayrılır', () {
      // Gelecek koruması, takvimde geçmiş bir günü tek tek silmeyi
      // bozmamalı.
      final logs = [
        PeriodLog(id: 'a', startDate: dayAt(10), endDate: dayAt(6)),
      ];

      final after = periods.toggleDay(
        logs,
        dayAt(8),
        ongoingLength: 5,
        today: dayAt(0),
      );

      expect(after, hasLength(2));
      expect(after.first.startDate, dayAt(10));
      expect(after.first.endDate, dayAt(9));
      expect(after.last.startDate, dayAt(7));
      expect(after.last.endDate, dayAt(6));
    });
  });
}
