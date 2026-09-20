import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/period_service.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Geçmiş bir günü regl olarak işaretlemek dönemi bitirmemeli.
///
/// Takvimde 17'sine dokunup "reglim o gün başladı" demek, uygulamada
/// "17'sinde başlayıp 17'sinde bitti" olarak kaydediliyordu: `toggleDay`
/// eklediği günü `endDate: cleanDate` ile kapatıyordu. Sonucu kullanıcı şöyle
/// görüyordu — takvimdeki bant bugünden önce kesiliyor, `periodEndedToday`
/// doğru dönüyor ve ana ekran daha ilk günden "Reglin bugün bitti" diyordu.
///
/// Asıl çelişki şuydu: **aynı olgu iki arayüzde iki farklı şey kaydediyordu.**
/// Ana ekrandaki "Reglim başladı" düğmesi ([PeriodService.startPeriod]) aynı
/// tarihi bitişsiz kaydediyor ve dönem sürüyor sayılıyordu. Takvim ise
/// kapatıyordu. Bu dosya ikisini yan yana koyup aynı sonucu vermelerini
/// şart koşuyor.
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  const periodLength = 5;
  final service = PeriodService();

  List<PeriodLog> mark(List<DateTime> days, {List<PeriodLog>? onto}) {
    var logs = onto ?? <PeriodLog>[];
    for (final day in days) {
      logs = service.toggleDay(
        logs,
        day,
        today: today,
        expectedLength: periodLength,
      );
    }
    return logs;
  }

  bool covers(List<PeriodLog> logs, DateTime day) =>
      logs.any((l) => l.containsRecorded(day, today: today));

  group('sürüyor olabilecek dönem açık kaydediliyor', () {
    test('4 gün önce işaretlenen gün bugüne kadar doluyor', () {
      final logs = mark([daysAgo(4)]);

      expect(logs, hasLength(1));
      expect(logs.single.isOngoing, isTrue,
          reason: 'Beklenen regl süresi dolmadan dönem kapatılmamalı.');
      for (var d = 4; d >= 0; d--) {
        expect(covers(logs, daysAgo(d)), isTrue,
            reason: '$d gün önceki gün takvimde dolu olmalı.');
      }
    });

    test('bugün işaretlemek "bugün bitti" anlamına gelmiyor', () {
      final logs = mark([today]);

      expect(logs.single.isOngoing, isTrue);
      expect(PredictionService().getCycleInfo(logs).periodEndedToday, isFalse,
          reason: 'Takvimde bugüne dokunmak dönemi bitirmiş sayılıyordu.');
    });

    test('ilk güne dokunmak aradaki günleri zaten dolduruyor', () {
      // Kullanıcı 17'ye dokunduğunda bant bugüne kadar doluyor; 18'e ayrıca
      // dokunması gerekmiyor. Dolu bir güne dokunmak artık onu **kaldırmak**
      // demek ve ekranda görünenle tutarlı olan da bu.
      final logs = mark([daysAgo(4)]);
      expect(covers(logs, daysAgo(3)), isTrue);

      final after = service.toggleDay(
        logs,
        daysAgo(3),
        today: today,
        expectedLength: periodLength,
      );
      expect(covers(after, daysAgo(3)), isFalse);
    });

    test('sondan kırpmak dönemi geçmişte kapatabiliyor', () {
      // Regli 17-19 sürüp bitmişse: 17'ye dokun, sonra bugünü ve dünü kaldır.
      var logs = mark([daysAgo(4)]);
      for (final day in [today, daysAgo(1)]) {
        logs = service.toggleDay(
          logs,
          day,
          today: today,
          expectedLength: periodLength,
        );
      }

      expect(logs.single.endDate, daysAgo(2));
      expect(logs.single.isOngoing, isFalse);
    });
  });

  group('geçmişte kalmış dönem kapalı kaydediliyor', () {
    test('süresi dolmuş bir gün bugüne uzanmıyor', () {
      final logs = mark([daysAgo(20)]);

      expect(logs.single.isOngoing, isFalse,
          reason: 'Aylar önceki bir gün dönemi bugüne kadar uzatmamalı.');
      expect(covers(logs, today), isFalse);
    });

    test('sonrasında başka bir dönem varsa açılmıyor', () {
      // Önce bugünkü dönem, sonra geçmişe dönük düzeltme.
      final logs = mark([daysAgo(4)], onto: mark([daysAgo(30)]));

      final older = logs.firstWhere((l) => l.firstDay == daysAgo(30));
      expect(older.isOngoing, isFalse);
      // İki kayıt da açık olsaydı ikisi birden bugüne kadar uzanır,
      // aynı günler iki döneme birden ait görünürdü.
      expect(logs.where((l) => l.isOngoing), hasLength(1));
    });
  });

  group('takvim ile ana ekran aynı şeyi söylüyor', () {
    test('takvimden işaretlemek başlat düğmesiyle aynı kaydı üretiyor', () {
      final viaCalendar = mark([daysAgo(4)]);
      final viaButton = service.startPeriod(<PeriodLog>[], daysAgo(4));

      expect(viaCalendar.single.firstDay, viaButton.single.firstDay);
      expect(viaCalendar.single.isOngoing, viaButton.single.isOngoing,
          reason: 'Aynı olgu iki arayüzde farklı kaydediliyordu.');
    });

    test('ana ekran döngü gününü doğru sayıyor', () {
      final info = PredictionService().getCycleInfo(mark([daysAgo(4)]));

      expect(info.lastPeriodStart, daysAgo(4));
      expect(info.currentCycleDay, 5, reason: '17→21 beşinci gündür.');
      expect(info.currentPeriodLength, 5);
      expect(info.periodEndedToday, isFalse);
      expect(info.currentPeriodEnd, isNull);
    });
  });

  group('onboarding formu da aynı kuralı izliyor', () {
    // Form yalnızca başlangıcı soruyor; ekran bundan bir bitiş uydurup kaydı
    // kapatıyordu. Kural artık takvimle ortak.
    PeriodLog fromStart(int ago) => service.recordFromStart(
      daysAgo(ago),
      today: today,
      expectedLength: periodLength,
    );

    test('süresi dolmamış başlangıç açık kaydediliyor', () {
      final log = fromStart(2);
      expect(log.isOngoing, isTrue);
      expect(log.containsRecorded(today, today: today), isTrue);
    });

    test('geçmişte kalmış başlangıç kapalı kaydediliyor', () {
      final log = fromStart(30);
      expect(log.isOngoing, isFalse);
      expect(log.endDate, daysAgo(30 - (periodLength - 1)));
    });

    test('takvimle aynı sonucu veriyor', () {
      // İki yol, tek kural: biri değişip diğeri unutulmasın.
      for (final ago in [0, 2, 4, 5, 30]) {
        expect(fromStart(ago).isOngoing, mark([daysAgo(ago)]).single.isOngoing,
            reason: '$ago gün önce: form ile takvim ayrışıyor.');
      }
    });
  });

  group('kaldırma yolu bozulmadı', () {
    test('bugünü kaldırmak dönemi dün kapatıyor', () {
      // Aksi hâlde "geri al" işe yaramaz: kayıt her seferinde yeniden açılır.
      final logs = mark([daysAgo(2)]);
      expect(covers(logs, today), isTrue);

      final after = service.toggleDay(
        logs,
        today,
        today: today,
        expectedLength: periodLength,
      );

      expect(after.single.endDate, daysAgo(1));
      expect(covers(after, today), isFalse);
    });

    test('tek günlük geçmiş kayda tekrar dokunmak siliyor', () {
      final logs = mark([daysAgo(20)]);
      final after = service.toggleDay(
        logs,
        daysAgo(20),
        today: today,
        expectedLength: periodLength,
      );

      expect(after, isEmpty);
    });
  });
}
