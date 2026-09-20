import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/assistant/assistant_answer.dart';
import 'package:period_tracker/domain/services/assistant/assistant_parser.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Asistanın cevapları uygulamanın geri kalanıyla uyuşuyor mu?
///
/// Asistan "kendi kayıtlarından hesaplanan cevaplar" diyor. O hâlde aynı
/// kayıttan ana ekranın söylediğiyle çelişemez: kullanıcı iki ekranda iki
/// farklı şey okuduğunda hangisine güveneceğini bilemez.
void main() {
  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  final now = DateTime(2026, 9, 20);
  final today = DateTime(now.year, now.month, now.day);

  /// [late] gün gecikmiş (negatifse döngü ortası) iki dönemlik kayıt.
  AssistantAnswer ask(
    AssistantIntent intent, {
    int late = -18,
    bool hormonal = false,
    List<PeriodLog>? logs,
  }) {
    final start = today.subtract(Duration(days: 28 + late));
    final periods =
        logs ??
        [
          PeriodLog(
            id: 'a',
            startDate: start.subtract(const Duration(days: 28)),
            endDate: start.subtract(const Duration(days: 24)),
          ),
          PeriodLog(
            id: 'b',
            startDate: start,
            endDate: start.add(const Duration(days: 4)),
          ),
        ];
    return AssistantAnswerBuilder.build(
      AssistantQuery(intent),
      cycleInfo: PredictionService().getCycleInfo(
        periods,
        hormonalContraception: hormonal,
        today: today,
      ),
      periodLogs: periods,
      dailyLogs: const [],
      now: now,
    );
  }

  group('gecikme doğru bildiriliyor', () {
    // Çarkta düzeltilmiş bir hatanın aynısı asistanda duruyordu:
    // `daysUntilNextPeriod` sıfırın altına inmediği için gecikmenin her
    // gününde "bugün başlıyor" deniyordu. Kırk gün gecikmiş birine
    // "bugün başlıyor" demek, endişe verici bir durumu görmezden gelmek.
    for (final late in [1, 5, 40]) {
      test('$late gün gecikmede "bugün başlıyor" denmiyor', () {
        final answer = ask(AssistantIntent.nextPeriod, late: late);

        expect(
          answer.key,
          isNot('assistant_next_period_today'),
          reason: '$late gün gecikmişken "bugün başlıyor" deniyor',
        );
        expect(answer.key, 'assistant_late');
        expect(answer.params['days'], '$late');
      });
    }

    test('beklenen gün geldiğinde bugün deniyor', () {
      // Karşı taraf: kural fazla geniş olsaydı asistan hiç
      // "bugün başlıyor" demezdi.
      expect(
        ask(AssistantIntent.nextPeriod, late: 0).key,
        'assistant_next_period_today',
      );
    });

    test('döngü ortasında kalan gün sayılıyor', () {
      final answer = ask(AssistantIntent.nextPeriod, late: -18);
      expect(answer.key, 'assistant_next_period');
      expect(answer.params['days'], '18');
    });
  });

  group('hormonal doğum kontrolü', () {
    test('doğurganlık sorusu "veri yok" demiyor', () {
      // Kullanıcının verisi var; uygulama doğurganlığı bilerek
      // hesaplamıyor. "Takvimde regl günlerini işaretledikçe
      // cevaplayabilirim" demek, sonsuza kadar işaretlese de cevap
      // gelmeyecek bir işe yönlendirmek olurdu.
      final answer = ask(AssistantIntent.fertileWindow, hormonal: true);

      expect(answer.key, isNot('assistant_no_data'));
      expect(answer.key, 'assistant_fertility_off');
    });

    test('doğurganlık izleniyorken cevap veriliyor', () {
      expect(
        ask(AssistantIntent.fertileWindow).key,
        'assistant_fertile_window',
      );
    });
  });

  group('evre sorusu evreyi söylüyor', () {
    test('cevapta evre adı geçiyor', () {
      // Soru "hangi evredeyim"; yalnızca gün numarası vermek soruyu
      // cevaplamıyor. `{phase}` parametresi hesaplanıyordu ama hiçbir
      // dilin metninde kullanılmıyordu.
      final answer = ask(AssistantIntent.currentPhase);

      expect(answer.params['phase'], isNotNull);
      expect(
        dictionary['assistant_current_phase'] as String,
        contains('{phase}'),
        reason: 'hesaplanan evre metne hiç girmiyor',
      );
    });
  });

  group('gerçekten veri yokken', () {
    test('kayıt yoksa veri yok deniyor', () {
      expect(
        ask(AssistantIntent.nextPeriod, logs: const []).key,
        'assistant_no_data',
      );
    });
  });

  group('sorular cihazdan çıkmıyor', () {
    // Ekranda yazan söz bu: "Kendi kayıtlarından hesaplanan cevaplar.
    // Soruların cihazından çıkmaz." Sağlık sorusu, sorunun kendisi de
    // hassas veri — "hamile miyim", "kramplarım ne zaman" gibi.
    const sources = [
      'lib/domain/services/assistant/assistant_answer.dart',
      'lib/domain/services/assistant/assistant_parser.dart',
      'lib/presentation/assistant/assistant_screen.dart',
    ];

    test('ağ, bulut ve analitik çağrısı yok', () {
      const forbidden = [
        'http',
        'Firestore',
        'firebase',
        'Dio(',
        'analytics',
        'openai',
      ];

      for (final path in sources) {
        final code = File(path)
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');

        for (final term in forbidden) {
          expect(
            code.contains(term),
            isFalse,
            reason: '$path içinde "$term" geçiyor',
          );
        }
      }
    });

    test('sorular kalıcı olarak saklanmıyor', () {
      // Soru geçmişi yalnızca bellekte; ekran kapanınca gidiyor.
      final screen = File(sources.last).readAsStringSync();

      expect(screen.contains('SharedPreferences'), isFalse);
      expect(screen.contains('SecureStore'), isFalse);
    });
  });
}
