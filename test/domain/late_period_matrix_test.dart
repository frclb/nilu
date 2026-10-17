import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/cycle_agenda.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Regl gecikince ekranın söyledikleri.
///
/// Ana ekranın üstü "5 gün gecikti" derken hemen altındaki SIRADA listesi
/// "Regl bekleniyor — 23 gün" diyordu. Sebep: beklenen tarih geçmişte
/// kaldığı için listeden düşüyor, yerine zincirin **bir sonraki** döngüsü
/// geçiyordu. Yani gelmemiş bir döngünün ardındaki döngü, sıradaki regl
/// gibi gösteriliyordu.
///
/// Doğurganlık penceresi daha da ağır: gecikmede listelenen pencere,
/// henüz başlamamış bir döngüye ait. Korunma farkındalığı için bakan biri
/// için yanlış bilgi.
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  /// 28 günlük döngü, 5 günlük regl; [late] gün gecikmiş.
  ({List<AgendaEntry> agenda, int daysLate, int? daysUntil}) stateFor(
    int late,
  ) {
    final start = today.subtract(Duration(days: 28 + late));
    final info = PredictionService().getCycleInfo([
      PeriodLog(
        id: 'a',
        startDate: start,
        endDate: start.add(const Duration(days: 4)),
      ),
    ]);
    return (
      agenda: CycleAgenda.upcoming(info, now: now),
      daysLate: info.daysLateAt(now),
      daysUntil: info.daysUntilNextPeriod,
    );
  }

  group('gecikmede tahmin sunulmuyor', () {
    for (final late in [1, 3, 5, 14, 40, 90]) {
      test('$late gün gecikme', () {
        final state = stateFor(late);
        expect(state.daysLate, late, reason: 'kurulum yanlış');

        expect(
          state.agenda,
          isEmpty,
          reason:
              '$late gün gecikmişken ajanda hâlâ tahmin sıralıyor: '
              '${state.agenda.map((e) => "${e.kind.name}+${e.daysAway}").join(", ")}',
        );
      });
    }
  });

  group('gecikme yokken ajanda çalışıyor', () {
    test('beklenen gün geldiğinde sonraki döngü listeleniyor', () {
      // Karşı taraf: kural fazla geniş olsaydı ajanda hiç görünmezdi.
      final state = stateFor(0);
      expect(state.daysLate, 0);
      expect(state.agenda, isNotEmpty, reason: 'gecikme yokken liste dolmalı');
    });

    test('döngü ortasında ajanda dolu', () {
      final start = today.subtract(const Duration(days: 10));
      final info = PredictionService().getCycleInfo([
        PeriodLog(
          id: 'a',
          startDate: start,
          endDate: start.add(const Duration(days: 4)),
        ),
      ]);
      expect(CycleAgenda.upcoming(info, now: now), isNotEmpty);
    });
  });

  group('gecikme sayısı doğru', () {
    test('beklenen günde gecikme sıfır', () {
      expect(stateFor(0).daysLate, 0);
    });

    test('daysUntil eksiye düşmüyor', () {
      // Başlık "{n} gün var" derken eksi bir sayı yazmamalı.
      for (final late in [0, 1, 20]) {
        expect(stateFor(late).daysUntil, isNonNegative);
      }
    });
  });
}
