import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/services/phase_guide.dart';

import 'dart:convert';
import 'dart:io';

void main() {
  group('PhaseGuide', () {
    test('her evre için içerik döner', () {
      for (final phase in CyclePhase.values) {
        final guidance = PhaseGuide.forPhase(phase);
        expect(guidance.titleKey, isNotEmpty, reason: '$phase');
        expect(guidance.bodyKey, isNotEmpty, reason: '$phase');
        expect(guidance.tipKey, isNotEmpty, reason: '$phase');
        expect(guidance.activityMinutes, greaterThan(0), reason: '$phase');
      }
    });

    test('farklı evreler farklı içerik gösterir', () {
      // Aynı metni her evrede göstermek tam da düzeltilen hataydı.
      final bodies = CyclePhase.values
          .map((p) => PhaseGuide.forPhase(p).bodyKey)
          .toSet();
      expect(bodies.length, CyclePhase.values.length);

      final tips = CyclePhase.values
          .map((p) => PhaseGuide.forPhase(p).tipKey)
          .toSet();
      expect(tips.length, CyclePhase.values.length);
    });

    test('kullandığı tüm anahtarların çevirisi var', () {
      for (final file in Directory(
        'lib/localization',
      ).listSync().whereType<File>()) {
        if (!file.path.endsWith('.json')) continue;
        final map =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final key in PhaseGuide.allKeys) {
          expect(
            map.containsKey(key),
            isTrue,
            reason: '${file.path} içinde $key eksik',
          );
        }
      }
    });
  });

  group('CycleInfo.phaseForDate', () {
    // 28 günlük döngü, 5 günlük regl. Ovulasyon 14. gün (28-14).
    final start = DateTime(2026, 1, 1);
    // Sabit "bugün": tahmin çapaları yalnızca gelecek tarihler için geçerli.
    final now = DateTime(2026, 1, 20);
    final info = CycleInfo(
      averageCycleLength: 28,
      averagePeriodLength: 5,
      lastPeriodStart: start,
      predictedNextPeriod: DateTime(2026, 1, 29),
      futurePredictions: [
        PredictedCycle(startDate: DateTime(2026, 2, 26)),
        PredictedCycle(startDate: DateTime(2026, 3, 26)),
      ],
    );

    test('kayıtlı döngü içindeki günleri doğru sınıflar', () {
      expect(
        info.phaseForDate(DateTime(2026, 1, 3), loggedStart: start, now: now),
        CyclePhase.menstruation,
      );
      expect(
        info.phaseForDate(DateTime(2026, 1, 9), loggedStart: start, now: now),
        CyclePhase.follicular,
      );
      expect(
        info.phaseForDate(DateTime(2026, 1, 14), loggedStart: start, now: now),
        CyclePhase.ovulation,
      );
      expect(
        info.phaseForDate(DateTime(2026, 1, 25), loggedStart: start, now: now),
        CyclePhase.luteal,
      );
    });

    test('tahmin edilen sonraki döngüye sarar', () {
      // 30 Ocak, son kayıttan 30 gün sonra. Yalnızca kayıttan saysaydık 30.
      // güne düşüp luteal derdi; oysa tahmin edilen reglin 2. günü.
      expect(
        info.phaseForDate(DateTime(2026, 1, 30), loggedStart: start, now: now),
        CyclePhase.menstruation,
      );
    });

    test('ileri tahminlere de sarar', () {
      // 27 Şubat, üçüncü döngünün 2. günü.
      expect(
        info.phaseForDate(DateTime(2026, 2, 27), loggedStart: start, now: now),
        CyclePhase.menstruation,
      );
      // 11 Mart, o döngünün 14. günü → yumurtlama.
      expect(
        info.phaseForDate(DateTime(2026, 3, 11), loggedStart: start, now: now),
        CyclePhase.ovulation,
      );
    });

    test('çapadan önceki tarih bilinmiyor', () {
      expect(
        info.phaseForDate(DateTime(2025, 12, 20), loggedStart: null, now: now),
        CyclePhase.unknown,
      );
    });

    test('gün sayacı evre ile aynı çapayı kullanır', () {
      // Başlıkta "30. gün" yazarken içeriğin "regl dönemi" demesi
      // kullanıcıyı şaşırtıyordu; ikisi aynı döngüyü göstermeli.
      final date = DateTime(2026, 1, 30);
      expect(info.cycleDayForDate(date, loggedStart: start, now: now), 2);
      expect(
        info.phaseForDate(date, loggedStart: start, now: now),
        CyclePhase.menstruation,
      );
    });

    test('regl gecikince tahmine sarmaz', () {
      // 30 Ocak artık "bugün". Regl beklenen 29'unda başlamadı ve kullanıcı
      // bir şey işaretlemedi; sayaç 30. günde kalmalı, "2. gün" demek
      // reglin başladığını iddia etmek olurdu.
      final late = DateTime(2026, 1, 30);
      expect(info.cycleDayForDate(late, loggedStart: start, now: late), 30);
      expect(
        info.phaseForDate(late, loggedStart: start, now: late),
        CyclePhase.luteal,
      );
    });

    test('hiç veri yoksa bilinmiyor', () {
      expect(
        CycleInfo().phaseForDate(DateTime(2026, 1, 5)),
        CyclePhase.unknown,
      );
    });

    test('kayıtlı başlangıç tahminden yeniyse onu kullanır', () {
      // Kullanıcı regli erken işaretlediyse tahmin değil kayıt geçerli.
      final logged = DateTime(2026, 1, 26);
      expect(
        info.phaseForDate(DateTime(2026, 1, 28), loggedStart: logged, now: now),
        CyclePhase.menstruation,
      );
    });
  });
}
