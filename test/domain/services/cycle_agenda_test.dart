import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/services/cycle_agenda.dart';

void main() {
  final now = DateTime(2026, 9, 1);

  CycleInfo info({
    DateTime? next,
    DateTime? fertile,
    DateTime? ovulation,
    bool tracked = true,
    List<PredictedCycle> future = const [],
  }) => CycleInfo(
    predictedNextPeriod: next,
    fertileWindowStart: fertile,
    ovulationDay: ovulation,
    fertilityTracked: tracked,
    futurePredictions: future,
  );

  group('CycleAgenda', () {
    test('yaklaşan olaylar tarihe göre sıralı gelir', () {
      final list = CycleAgenda.upcoming(
        info(
          next: DateTime(2026, 9, 20),
          fertile: DateTime(2026, 9, 8),
          ovulation: DateTime(2026, 9, 11),
        ),
        now: now,
      );
      expect(list.map((e) => e.kind), [
        AgendaKind.fertileStart,
        AgendaKind.ovulation,
        AgendaKind.periodStart,
      ]);
    });

    test('kalan gün sayısı doğru', () {
      final list = CycleAgenda.upcoming(
        info(next: DateTime(2026, 9, 20)),
        now: now,
      );
      expect(list.single.daysAway, 19);
    });

    test('bugün olan olay listeye girmez', () {
      // Bugünün durumu ekranın üstündeki cümlede zaten söyleniyor.
      final list = CycleAgenda.upcoming(
        info(next: now, fertile: DateTime(2026, 9, 5)),
        now: now,
      );
      expect(list.map((e) => e.kind), [AgendaKind.fertileStart]);
    });

    test('geçmiş olaylar listeye girmez', () {
      final list = CycleAgenda.upcoming(
        info(fertile: DateTime(2026, 8, 20), next: DateTime(2026, 9, 20)),
        now: now,
      );
      expect(list.map((e) => e.kind), [AgendaKind.periodStart]);
    });

    test('hormonal doğum kontrolünde doğurganlık listelenmez', () {
      // Yumurtlama baskılandığında bu olayları saymak olmayan bir şeyi
      // vaat etmek olur.
      final list = CycleAgenda.upcoming(
        info(
          next: DateTime(2026, 9, 20),
          fertile: DateTime(2026, 9, 8),
          ovulation: DateTime(2026, 9, 11),
          tracked: false,
        ),
        now: now,
      );
      expect(list.map((e) => e.kind), [AgendaKind.periodStart]);
    });

    test('ileri tahminler de listelenir', () {
      final list = CycleAgenda.upcoming(
        info(
          next: DateTime(2026, 9, 20),
          future: [
            PredictedCycle(
              startDate: DateTime(2026, 10, 18),
              fertileStart: DateTime(2026, 10, 6),
            ),
          ],
        ),
        now: now,
        limit: 5,
      );
      expect(list.length, 3);
      expect(list.last.date, DateTime(2026, 10, 18));
    });

    test('aynı tarihli olay iki kez listelenmez', () {
      // `predictedNextPeriod` çoğu zaman `futurePredictions`'ın ilkiyle aynı
      // tarih; ekranda "Regl bekleniyor" iki kez yazıyordu.
      final list = CycleAgenda.upcoming(
        info(
          next: DateTime(2026, 9, 20),
          future: [PredictedCycle(startDate: DateTime(2026, 9, 20))],
        ),
        now: now,
        limit: 5,
      );
      expect(list.length, 1);
      expect(list.single.kind, AgendaKind.periodStart);
    });

    test('sınır kadar olay döner', () {
      final list = CycleAgenda.upcoming(
        info(
          next: DateTime(2026, 9, 20),
          fertile: DateTime(2026, 9, 8),
          ovulation: DateTime(2026, 9, 11),
        ),
        now: now,
        limit: 2,
      );
      expect(list.length, 2);
    });

    test('veri yoksa liste boş', () {
      expect(CycleAgenda.upcoming(info(), now: now), isEmpty);
    });

    test('her olayın bir metin anahtarı var', () {
      for (final kind in AgendaKind.values) {
        final entry = AgendaEntry(kind: kind, date: now, daysAway: 1);
        expect(entry.labelKey, isNotEmpty, reason: '$kind');
      }
    });
  });
}
