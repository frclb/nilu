import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Ana ekrandaki çelenk ile takvim aynı güne aynı cevabı vermeli.
///
/// İkisi ayrı yollardan hesaplanıyor: takvim kayıtlara ve kullanıcının
/// ayarına bakıyor (`containsRecorded` + `isExpectedContinuation`), çelenk
/// ise döngü fazına (`phaseForRingDay`). Aynı veriden iki cevap üretmenin
/// bedeli, kullanıcının hangisine inanacağını bilememesi.
///
/// Bir kez ayrıştılar: kullanıcı regl süresini 7 ayarladığında takvim yedi
/// gün boyuyor, çelenk dördüncü çiçekte kesiliyordu. İkinci kez, geçmişi
/// olan kullanıcıda çelenk geçmişin ortalamasını, takvim ayarı kullanıyordu.
void main() {
  final bugun = DateTime(2026, 9, 27);
  DateTime g(int gun) => DateTime(2026, 9, gun);

  PeriodLog log(DateTime s, [DateTime? e]) =>
      PeriodLog(id: s.toIso8601String(), startDate: s, endDate: e);

  /// Senaryoda çelenk ile takvimin ayrıştığı günleri döndürür.
  List<String> ayrisanGunler({
    required List<PeriodLog> logs,
    int userCycleLength = 27,
    int userPeriodLength = 7,
    DateTime? settingsUpdatedAt,
    bool hormonal = false,
  }) {
    final info = PredictionService().getCycleInfo(
      logs,
      userCycleLength: userCycleLength,
      userPeriodLength: userPeriodLength,
      settingsUpdatedAt: settingsUpdatedAt,
      hormonalContraception: hormonal,
      today: bugun,
    );
    final start = info.lastPeriodStart;
    if (start == null) return const [];

    final fark = <String>[];
    for (var i = 0; i < 45; i++) {
      final tarih = DateTime(start.year, start.month, start.day + i);

      final takvimdeRegl =
          logs.any((l) => l.containsRecorded(tarih, today: bugun)) ||
          logs.any(
            (l) => l.isExpectedContinuation(
              tarih,
              today: bugun,
              expectedLength: userPeriodLength,
            ),
          );
      final celenkteRegl =
          info.phaseForRingDay(i + 1) == CyclePhase.menstruation;

      if (takvimdeRegl != celenkteRegl) {
        fark.add(
          'döngü günü ${i + 1} (${tarih.day}.${tarih.month}): '
          'takvim=${takvimdeRegl ? "regl" : "regl değil"} '
          'çelenk=${celenkteRegl ? "regl" : "regl değil"}',
        );
      }
    }
    return fark;
  }

  void eslenik(
    String ad, {
    required List<PeriodLog> logs,
    int userCycleLength = 27,
    int userPeriodLength = 7,
    DateTime? settingsUpdatedAt,
    bool hormonal = false,
  }) {
    test(ad, () {
      final fark = ayrisanGunler(
        logs: logs,
        userCycleLength: userCycleLength,
        userPeriodLength: userPeriodLength,
        settingsUpdatedAt: settingsUpdatedAt,
        hormonal: hormonal,
      );
      expect(fark, isEmpty, reason: fark.join('\n'));
    });
  }

  group('çelenk ve takvim eşlenik', () {
    eslenik('kayıt hiç yok', logs: []);
    eslenik('regl bugün başladı', logs: [log(g(27))]);
    eslenik('4. gün, sürüyor', logs: [log(g(24))]);
    eslenik('beklenen son gün (7.), sürüyor', logs: [log(g(21))]);
    eslenik('beklenenden uzun (9. gün)', logs: [log(g(19))]);
    eslenik('beklenenden çok uzun (20. gün)', logs: [log(g(8))]);
    eslenik('ilk gün bitirildi', logs: [log(g(27), g(27))]);
    eslenik('3. günde bitirildi', logs: [log(g(24), g(26))]);
    eslenik('tam beklenen sürede bitti', logs: [log(g(21), g(27))]);
    eslenik('bitti, foliküler evrede', logs: [log(g(15), g(21))]);
    eslenik('bitti, yumurtlama civarı', logs: [log(g(10), g(16))]);
    eslenik(
      'gecikmiş regl (30. gün)',
      logs: [log(DateTime(2026, 8, 29), DateTime(2026, 9, 4))],
    );
    eslenik(
      'çok gecikmiş (45. gün)',
      logs: [log(DateTime(2026, 8, 14), DateTime(2026, 8, 20))],
    );
    eslenik('hormonal doğum kontrolü', logs: [log(g(24))], hormonal: true);
    eslenik(
      'hormonal, dönem bitmiş',
      logs: [log(g(15), g(21))],
      hormonal: true,
    );

    // Bu senaryo bir kez ayrıştı: çelenk geçmişin ortalamasını (3 gün),
    // takvim kullanıcının ayarını (7 gün) kullanıyordu.
    eslenik(
      'geçmiş ortalaması ayardan kısa',
      logs: [
        log(DateTime(2026, 7, 1), DateTime(2026, 7, 3)),
        log(DateTime(2026, 8, 1), DateTime(2026, 8, 3)),
        log(g(24)),
      ],
    );
    eslenik(
      'geçmiş ortalaması ayardan uzun',
      logs: [
        log(DateTime(2026, 7, 1), DateTime(2026, 7, 9)),
        log(DateTime(2026, 8, 1), DateTime(2026, 8, 9)),
        log(g(24)),
      ],
      userPeriodLength: 3,
    );

    eslenik(
      'ayar son reglden sonra değişti',
      logs: [log(g(24))],
      settingsUpdatedAt: DateTime(2026, 9, 26),
    );
    eslenik(
      'ayar son reglden önce değişti',
      logs: [log(g(24))],
      settingsUpdatedAt: DateTime(2026, 9, 1),
    );

    eslenik('en kısa regl ayarı (2)', logs: [log(g(24))], userPeriodLength: 2);
    eslenik('en uzun regl ayarı (10)', logs: [log(g(24))], userPeriodLength: 10);
    eslenik(
      'regl ayarı döngüden uzun',
      logs: [log(g(24))],
      userCycleLength: 5,
      userPeriodLength: 10,
    );
    eslenik(
      'art arda iki kısa döngü',
      logs: [log(DateTime(2026, 9, 5), DateTime(2026, 9, 9)), log(g(24))],
    );
    eslenik(
      'uzun geçmiş, düzenli',
      logs: [
        for (var ay = 3; ay <= 8; ay++)
          log(DateTime(2026, ay, 1), DateTime(2026, ay, 7)),
        log(g(24)),
      ],
    );
  });

  group('başlık ve çelenk aynı fazı söyler', () {
    void bugunFaziAyni(String ad, List<PeriodLog> logs) {
      test(ad, () {
        final info = PredictionService().getCycleInfo(
          logs,
          userCycleLength: 27,
          userPeriodLength: 7,
          today: bugun,
        );
        final gun = info.currentCycleDay;
        if (gun == null) return;
        expect(
          info.phaseForRingDay(gun),
          info.phaseForCurrentCycleDay(gun),
          reason: 'başlık ile çelenk bugüne farklı faz veriyor',
        );
      });
    }

    bugunFaziAyni('sürüyor', [log(g(24))]);
    bugunFaziAyni('bugün bitirildi', [log(g(24), g(27))]);
    bugunFaziAyni('dün bitirildi', [log(g(24), g(26))]);
    bugunFaziAyni('foliküler', [log(g(15), g(21))]);
  });
}
