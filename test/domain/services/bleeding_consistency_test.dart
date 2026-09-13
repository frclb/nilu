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
/// Düğmenin kaynağı `PeriodLog.containsRecorded`, başlığınki
/// `CycleInfo.currentPhase`. Bu dosya ikisini yan yana koyup aynı cevabı
/// verdiklerini doğruluyor.
void main() {
  final service = PredictionService();
  final periods = PeriodService();

  DateTime dayAt(int daysAgo) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - daysAgo);
  }

  bool bleedingToday(List<PeriodLog> logs) =>
      logs.any((l) => l.containsRecorded(dayAt(0)));

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
      expect(bleedingToday(logs), isFalse);
      expect(info.currentPhase, isNot(CyclePhase.menstruation));
    });

    test('ortalamadan uzun süren regl başlıkta da regl kalır', () {
      // Önceki iki döngü 3 gün sürmüş. Bu döngü uzadı ve kullanıcı bugünü de
      // regl olarak işaretledi. Düğme "Reglim bitti" derken başlığın
      // "Foliküler faz" demesi aynı çelişkinin diğer yüzü.
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
      expect(bleedingToday(logs), isTrue);
      expect(info.currentPhase, CyclePhase.menstruation);
    });

    test('devam eden kayıt bugüne kadar sayılır, ötesine değil', () {
      // Geçmiş ortalaması 9 gün ama bu dönem 7 gündür sürüyor. Başlık
      // ortalamaya bakarsa kayıtla ayrışır.
      final logs = [
        PeriodLog(id: 'a', startDate: dayAt(60), endDate: dayAt(52)),
        PeriodLog(id: 'b', startDate: dayAt(32), endDate: dayAt(24)),
        PeriodLog(id: 'c', startDate: dayAt(6), endDate: null),
      ];

      final info = service.getCycleInfo(logs, userPeriodLength: 4);

      expect(info.averagePeriodLength, 9, reason: 'geçmiş ortalaması 9 gün');
      expect(info.currentCycleDay, 7);
      expect(info.currentPeriodLength, 7, reason: 'kayıt bugüne kadar 7 gün');
      expect(bleedingToday(logs), isTrue);
      expect(info.currentPhase, CyclePhase.menstruation);
    });

    test('regl günü her iki kaynakta da regl', () {
      final logs = [PeriodLog(id: 'a', startDate: dayAt(1), endDate: null)];

      final info = service.getCycleInfo(logs, userPeriodLength: 5);

      expect(bleedingToday(logs), isTrue);
      expect(info.currentPhase, CyclePhase.menstruation);
    });
  });

  group('düğmeye basınca ekran gerçekten değişir', () {
    test('"Reglim bitti" bugünü kayıtta bırakır ve dönemi kapatır', () {
      // Düğmenin can alıcı davranışı: bitiş günü kaydın **içinde** kalmalı.
      // Önceden bu eylem günü kaydın dışına çıkarıyordu; kullanıcı son
      // kanama gününü hiç işaretleyemiyordu.
      final logs = [PeriodLog(id: 'a', startDate: dayAt(2), endDate: null)];

      final after = periods.endPeriod(logs, dayAt(0));

      expect(after, hasLength(1));
      expect(after.single.endDate, dayAt(0));
      expect(after.single.isOngoing, isFalse, reason: 'dönem kapanmalı');
      expect(bleedingToday(after), isTrue, reason: 'bugün işaretli kalmalı');

      final info = service.getCycleInfo(after, userPeriodLength: 5);
      expect(info.currentPeriodLength, 3);
      expect(info.currentPhase, CyclePhase.menstruation);
    });

    test('bugünün ötesine uzanan kayıt bugüne kırpılır', () {
      // Onboarding'in ürettiği kayıt tipik olarak uzanıyor. Önceden bugünü
      // çıkarmak dönemi ikiye bölüyor, ikinci parça yarın başlıyordu;
      // `lastPeriodStart` geleceğe kayınca döngü günü null oluyor, başlık ile
      // çelenk tamamen boşalıyordu.
      final start = dayAt(2);
      final logs = [
        PeriodLog(
          id: 'a',
          startDate: start,
          endDate: start.add(const Duration(days: 4)),
        ),
      ];

      final after = periods.endPeriod(logs, dayAt(0));

      expect(after, hasLength(1));
      expect(after.single.endDate, dayAt(0));
      expect(
        after.every((l) => !l.startDate.isAfter(dayAt(0))),
        isTrue,
        reason: 'gelecekte başlayan dönem kalmamalı',
      );

      final info = service.getCycleInfo(after, userPeriodLength: 5);
      expect(info.currentCycleDay, 3, reason: 'sayaç kaybolmamalı');
      expect(info.currentPhase, isNot(CyclePhase.unknown));
    });

    test('başlat → bitir → geri al her adımda görünür bir fark yaratır', () {
      var logs = <PeriodLog>[];

      // "Reglim başladı"
      logs = periods.startPeriod(logs, dayAt(0));
      var info = service.getCycleInfo(logs, userPeriodLength: 5);
      expect(bleedingToday(logs), isTrue);
      expect(logs.single.isOngoing, isTrue);
      expect(info.currentCycleDay, 1);
      expect(info.currentPhase, CyclePhase.menstruation);

      // "Reglim bitti" — bugün kayıtta kalır, dönem kapanır
      logs = periods.endPeriod(logs, dayAt(0));
      info = service.getCycleInfo(logs, userPeriodLength: 5);
      expect(bleedingToday(logs), isTrue);
      expect(logs.single.isOngoing, isFalse);
      expect(info.currentPeriodLength, 1);

      // "Geri al" — dönem yeniden açılır
      logs.single.endDate = null;
      expect(logs.single.isOngoing, isTrue);
      expect(bleedingToday(logs), isTrue);
    });

    test('ertesi gün "başladı" aynı dönemi sürdürür, yeni döngü açmaz', () {
      // Dün kapanan dönem bugün yeniden açılıyor: aynı kanamayı iki döngü
      // gibi saysaydık ortalama döngü uzunluğu da bozulurdu.
      final logs = [PeriodLog(id: 'a', startDate: dayAt(3), endDate: dayAt(1))];

      final after = periods.startPeriod(logs, dayAt(0));

      expect(after, hasLength(1));
      expect(after.single.startDate, dayAt(3));
      expect(after.single.isOngoing, isTrue);

      final info = service.getCycleInfo(after, userPeriodLength: 5);
      expect(info.currentCycleDay, 4);
      expect(info.currentPeriodLength, 4);
      expect(info.currentPhase, CyclePhase.menstruation);
    });
  });

  group('yanlışlıkla "Reglim başladı"', () {
    /// Ana ekranın geri alma eylemi: bugünü kayıttan tamamen çıkarır.
    List<PeriodLog> undoStart(List<PeriodLog> logs) =>
        periods.toggleDay(logs, dayAt(0), today: dayAt(0));

    test('hiç kayıt yokken geri alma başlangıç öncesine döner', () {
      final started = periods.startPeriod([], dayAt(0));
      expect(started, hasLength(1));

      expect(undoStart(started), isEmpty);
    });

    test('dün biten dönem yeniden açıldıysa eski bitiş tarihi geri gelir', () {
      // "Başladı" burada yeni bir dönem açmıyor, dünkü dönemi yeniden
      // açıyor. Geri alma da kaydı silmek yerine bitişi geri koymalı.
      final original = [
        PeriodLog(id: 'a', startDate: dayAt(3), endDate: dayAt(1)),
      ];

      final started = periods.startPeriod(original, dayAt(0));
      expect(started.single.isOngoing, isTrue);

      final undone = undoStart(started);
      expect(undone, hasLength(1));
      expect(undone.single.startDate, dayAt(3));
      expect(undone.single.endDate, dayAt(1));
      expect(bleedingToday(undone), isFalse);
    });

    test('ilgisiz eski kayıtlara dokunulmaz', () {
      final original = [
        PeriodLog(id: 'a', startDate: dayAt(35), endDate: dayAt(31)),
      ];

      final undone = undoStart(periods.startPeriod(original, dayAt(0)));

      expect(undone, hasLength(1));
      expect(undone.single.startDate, dayAt(35));
      expect(undone.single.endDate, dayAt(31));
    });

    test('geri almadan sonra başlık da başlangıç öncesine döner', () {
      final original = [
        PeriodLog(id: 'a', startDate: dayAt(30), endDate: dayAt(26)),
      ];

      final started = periods.startPeriod(original, dayAt(0));
      expect(
        service.getCycleInfo(started, userPeriodLength: 5).currentPhase,
        CyclePhase.menstruation,
      );

      final undone = undoStart(started);
      final info = service.getCycleInfo(undone, userPeriodLength: 5);
      expect(info.currentCycleDay, 31);
      expect(info.currentPhase, isNot(CyclePhase.menstruation));
    });
  });

  group('yanlışlıkla başlatıp bitirme', () {
    /// Ana ekranın "bitti"yi geri alma eylemi: dönem bugün açıldıysa kaydı
    /// tamamen kaldırır, daha eskiyse yalnızca yeniden açar.
    List<PeriodLog> undoEnd(List<PeriodLog> logs) {
      final today = dayAt(0);
      for (final log in logs) {
        final end = log.endDate;
        if (end == null || !end.isAtSameMomentAs(today)) continue;
        if (log.firstDay.isAtSameMomentAs(today)) {
          return periods.toggleDay(logs, today, today: today);
        }
        log.endDate = null;
        return logs;
      }
      return logs;
    }

    test('bugün açılan dönem geri alınınca kayıt tamamen silinir', () {
      // Döngünün ortasında yanlışlıkla başlat → bitir. Yalnızca yeniden
      // açmak bir günlük sahte bir dönem bırakırdı ve `lastPeriodStart`
      // kaydığı için bütün tahminler bozuk kalırdı.
      final original = [
        PeriodLog(id: 'a', startDate: dayAt(40), endDate: dayAt(36)),
        PeriodLog(id: 'b', startDate: dayAt(12), endDate: dayAt(8)),
      ];
      final before = service.getCycleInfo(original, userPeriodLength: 5);

      var logs = periods.startPeriod([...original], dayAt(0));
      logs = periods.endPeriod(logs, dayAt(0));
      expect(bleedingToday(logs), isTrue, reason: 'bugün kayıtlı olmalı');

      logs = undoEnd(logs);

      expect(logs, hasLength(2), reason: 'bugünkü kayıt kalkmalı');
      expect(bleedingToday(logs), isFalse);

      final after = service.getCycleInfo(logs, userPeriodLength: 5);
      expect(
        after.lastPeriodStart,
        before.lastPeriodStart,
        reason: 'tahmin çapası başlangıçtaki yerine dönmeli',
      );
      expect(after.currentCycleDay, before.currentCycleDay);
    });

    test('eski dönemin bitirilmesi geri alınınca kayıt yerinde kalır', () {
      // Dönem gerçekten dün başlamışsa oradaki günler veri; geri alma
      // yalnızca "bitirmeyi" geri almalı.
      var logs = <PeriodLog>[
        PeriodLog(id: 'a', startDate: dayAt(2), endDate: null),
      ];
      logs = periods.endPeriod(logs, dayAt(0));
      expect(logs.single.endDate, dayAt(0));

      logs = undoEnd(logs);

      expect(logs, hasLength(1), reason: 'kayıt silinmemeli');
      expect(logs.single.startDate, dayAt(2));
      expect(logs.single.isOngoing, isTrue, reason: 'yeniden açılmalı');
    });
  });

  group('takvim kaydı ile beklentiyi ayırır', () {
    test('devam eden dönemin bugünden sonrası kayıt değil beklentidir', () {
      final log = PeriodLog(id: 'a', startDate: dayAt(1), endDate: null);

      expect(log.containsRecorded(dayAt(0)), isTrue);
      expect(
        log.containsRecorded(dayAt(-1)),
        isFalse,
        reason: 'yarın henüz yaşanmadı',
      );
      expect(
        log.isExpectedContinuation(dayAt(-1), expectedLength: 5),
        isTrue,
        reason: 'yarın tahmin olarak gösterilmeli',
      );
      expect(
        log.isExpectedContinuation(dayAt(-4), expectedLength: 5),
        isFalse,
        reason: 'beklenen uzunluğun ötesi beklenti de değil',
      );
    });

    test('dönem kapatılınca beklenen günler de kalkar', () {
      final log = PeriodLog(id: 'a', startDate: dayAt(1), endDate: null);
      final after = periods.endPeriod([log], dayAt(0)).single;

      expect(after.containsRecorded(dayAt(0)), isTrue);
      expect(
        after.isExpectedContinuation(dayAt(-1), expectedLength: 5),
        isFalse,
      );
    });
  });
}
