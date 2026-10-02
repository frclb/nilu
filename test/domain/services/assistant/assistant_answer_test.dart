import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/assistant/assistant_answer.dart';
import 'package:period_tracker/domain/services/assistant/assistant_parser.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

void main() {
  final now = DateTime(2026, 8, 18);

  PeriodLog period(int month, int day, {int length = 5}) => PeriodLog(
    id: '$month-$day',
    startDate: DateTime(2026, month, day),
    endDate: DateTime(2026, month, day + length - 1),
  );

  DailyLog log(int month, int day, List<String> symptoms) =>
      DailyLog(date: DateTime(2026, month, day), symptoms: symptoms);

  AssistantAnswer answer(
    AssistantIntent intent, {
    String? symptom,
    List<PeriodLog> periods = const [],
    List<DailyLog> daily = const [],
  }) {
    final info = PredictionService().getCycleInfo(periods);
    return AssistantAnswerBuilder.build(
      AssistantQuery(intent, symptomCode: symptom),
      cycleInfo: info,
      periodLogs: periods,
      dailyLogs: daily,
      now: now,
      breaks: const [],
    );
  }

  group('veri yokken', () {
    test('tahmin uydurulmaz, kayıt istenir', () {
      // Sağlık uygulamasında "makul görünen" bir cevap, cevapsızlıktan kötü.
      for (final intent in [
        AssistantIntent.nextPeriod,
        AssistantIntent.currentPhase,
        AssistantIntent.fertileWindow,
        AssistantIntent.periodLength,
      ]) {
        final a = answer(intent);
        expect(a.needsData, isTrue, reason: intent.name);
      }
    });

    test('tek döngüyle uzunluk ve düzenlilik cevaplanmaz', () {
      expect(
        answer(AssistantIntent.cycleLength, periods: [period(8, 1)]).key,
        'assistant_need_two_cycles',
      );
      expect(
        answer(AssistantIntent.regularity, periods: [period(8, 1)]).key,
        'assistant_need_two_cycles',
      );
    });
  });

  group('döngü soruları', () {
    final periods = [period(6, 1), period(6, 29), period(7, 27)];

    test('sonraki regl gün sayısı ve tarih verir', () {
      // Enjekte edilen tarih 18 Ağustos, tahmin 24 Ağustos → 6 gün.
      // Bu sayı artık duvar saatine değil verilen [now]'a bağlı.
      final a = answer(AssistantIntent.nextPeriod, periods: periods);
      expect(a.key, 'assistant_next_period');
      expect(a.params['date'], '2026-08-24');
      expect(a.params['days'], '6');
    });

    test('döngü uzunluğu ortalamayı ve son döngüyü verir', () {
      final a = answer(AssistantIntent.cycleLength, periods: periods);
      expect(a.key, 'assistant_cycle_length');
      expect(a.params['days'], '28');
      expect(a.params['count'], '2');
    });

    test('düzenli döngü düzenli olarak bildirilir', () {
      expect(
        answer(AssistantIntent.regularity, periods: periods).key,
        'assistant_regular_steady',
      );
    });

    test('değişken döngü ayrı cevap verir', () {
      final degisken = [period(5, 1), period(6, 5), period(7, 1)];
      expect(
        answer(AssistantIntent.regularity, periods: degisken).key,
        'assistant_regular_irregular',
      );
    });

    test('doğurganlık penceresi üç tarih verir', () {
      final a = answer(AssistantIntent.fertileWindow, periods: periods);
      expect(a.key, 'assistant_fertile_window');
      expect(a.params.keys, containsAll(['start', 'end', 'ovulation']));
    });
  });

  group('belirti soruları', () {
    final periods = [period(8, 1)];

    test('hiç kaydı olmayan belirti için kayıt istenir', () {
      final a = answer(
        AssistantIntent.symptomFrequency,
        symptom: 'cramp',
        periods: periods,
      );
      expect(a.needsData, isTrue);
    });

    test('baskın evre çıkarılabiliyorsa evre bildirilir', () {
      final a = answer(
        AssistantIntent.symptomFrequency,
        symptom: 'cramp',
        periods: periods,
        daily: [
          log(8, 1, ['cramp']),
          log(8, 2, ['cramp']),
          log(8, 3, ['cramp']),
        ],
      );
      expect(a.key, 'assistant_symptom_phase');
      expect(a.params['phase'], 'phase_menstruation');
    });

    test('baskın evre yoksa yalnız sayı verilir', () {
      // İki regl, iki luteal: çoğunluk yok, "çoğunlukla" denemez.
      final a = answer(
        AssistantIntent.symptomFrequency,
        symptom: 'cramp',
        periods: periods,
        daily: [
          log(8, 1, ['cramp']),
          log(8, 2, ['cramp']),
          log(8, 20, ['cramp']),
          log(8, 21, ['cramp']),
        ],
      );
      expect(a.key, 'assistant_symptom_count_only');
      expect(a.params['count'], '4');
    });

    test('en son ne zaman, en yeni kaydı verir', () {
      final a = answer(
        AssistantIntent.lastSymptom,
        symptom: 'headache',
        daily: [
          log(7, 5, ['headache']),
          log(8, 12, ['headache']),
        ],
      );
      expect(a.key, 'assistant_last_symptom');
      expect(a.params['date'], '2026-08-12');
    });

    test('belirti kodu yoksa anlaşılmadı döner', () {
      expect(answer(AssistantIntent.lastSymptom).key, 'assistant_unknown');
    });
  });

  test('anlaşılmayan soru sabit cevap döner', () {
    expect(answer(AssistantIntent.unknown).key, 'assistant_unknown');
  });
}
