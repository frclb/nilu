import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/cycle_alert.dart';
import 'package:period_tracker/domain/services/insights_service.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';

/// Gebelik kesintisi gerçekten uygulamaya ulaşıyor mu?
///
/// `cycle_break_test` kuralları sınıyor. Bu dosya kuralın **uygulandığını**:
/// `getCycleInfo`'nun tek üretim çağıranı ViewModel ve `breaks` parametresi
/// orada varsayılanlı. Unutulursa her şey derlenir, birim testler geçer ve
/// lohusa anneye eski SAT'tan "reglin 250 gün gecikti" denir. Bu oturumda
/// iki test tam bu yüzden boşa geçmişti: kural doğruydu, uygulanmıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bugun = DateTime.now();
  final gun = DateTime(bugun.year, bugun.month, bugun.day);
  DateTime once(int n) => gun.subtract(Duration(days: n));

  /// Gebelik öncesi düzenli geçmiş: SAT bugünden ~13 ay önce.
  final sat = once(400);
  final gecmis = [
    for (var i = 3; i >= 0; i--)
      PeriodLog(
        id: 'p$i',
        startDate: sat.subtract(Duration(days: 28 * i)),
        endDate: sat.subtract(Duration(days: 28 * i - 4)),
      ),
  ];

  Future<CalendarViewModel> kur(Pregnancy gebelik) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await const PeriodRepository().savePeriodLogs(gecmis);
    await const PregnancyRepository().upsert(gebelik);
    final vm = CalendarViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return vm;
  }

  Pregnancy dogum(int kacGunOnce) => Pregnancy.fromLmp(
    lmp: sat,
    cycleLength: 28,
    confirmedAt: sat.add(const Duration(days: 40)),
  ).ended(outcome: PregnancyOutcome.birth, at: once(kacGunOnce));

  test('doğumdan aylar sonra eski SAT\'tan tahmin yok', () async {
    final vm = await kur(dogum(120));

    expect(vm.lifeStage, LifeStage.cycle, reason: '42 gün geçti');
    expect(
      vm.cycleInfo.lastPeriodStart,
      isNull,
      reason:
          'ViewModel kesintileri tahmin servisine iletmiyor. Son kayıt '
          'gebelik öncesi SAT; ondan sayılırsa "reglin 250+ gün gecikti" '
          'denir.',
    );
    expect(vm.cycleInfo.predictedNextPeriod, isNull);
  });

  test('lohusalıkta evre lohusalık ve regl kaydı reddediliyor', () async {
    final vm = await kur(dogum(10));

    expect(vm.lifeStage, LifeStage.postpartum);
    expect(
      await vm.togglePeriodDay(gun),
      isFalse,
      reason:
          'Lohia regl değil. Kaydedilirse lastPeriodStart doğumdan sonraki '
          'güne oturur; azalıp yeniden artan kanama — bir tehlike işareti — '
          'sıradan bir "regl başladı" olarak gömülür.',
    );
  });

  test('erken kayıptan sonra döngü kaydı hemen açık', () async {
    final vm = await kur(
      Pregnancy.fromLmp(
        lmp: once(70),
        cycleLength: 28,
        confirmedAt: once(40),
      ).ended(outcome: PregnancyOutcome.miscarriage, at: once(14)),
    );

    expect(vm.lifeStage, LifeStage.cycle);
    expect(await vm.togglePeriodDay(gun), isTrue);
  });

  test('ekranlar kesintiyi ViewModel\'den alabiliyor', () async {
    final vm = await kur(dogum(120));
    expect(
      vm.cycleBreaks,
      isNotEmpty,
      reason: 'Analiz kartları ve asistan kesintiyi buradan okuyor',
    );
  });

  group('lohusalıktaki kanama', () {
    // Lohia günlük kayıtta akış olarak giriliyor. Regl kaydının yakınında
    // olmadığı için kesinti bilinmezse "ara kanama" sayılıyordu.
    final dogumGunu = DateTime(2026, 3, 1);
    final gebelik = Pregnancy.fromLmp(
      lmp: DateTime(2025, 5, 25),
      cycleLength: 28,
      confirmedAt: DateTime(2025, 7, 1),
    ).ended(outcome: PregnancyOutcome.birth, at: dogumGunu);

    final lohia = [
      for (var i = 1; i <= 30; i += 4)
        DailyLog(
          date: dogumGunu.add(Duration(days: i)),
          flowIntensity: i < 15 ? 'heavy' : 'light',
        ),
    ];
    final regller = [
      PeriodLog(
        id: 'sat',
        startDate: DateTime(2025, 5, 25),
        endDate: DateTime(2025, 5, 29),
      ),
    ];

    test('ara kanama sayılmıyor', () {
      final kesintiler = CycleBreaks.fromPregnancies([gebelik]);

      expect(
        CycleAlertService.intermenstrualEpisodes(
          dailyLogs: lohia,
          periodLogs: regller,
          breaks: kesintiler,
        ),
        isEmpty,
        reason:
            'Lohia ara kanama değil. Sayılırsa lohusa bir annenin Analiz '
            'ekranı her gün alarm verir ve hekime giden özet lohiayı ara '
            'kanama diye listeler.',
      );
    });

    test('kesinti yokken aynı kayıtlar ara kanama sayılırdı', () {
      // Yukarıdaki iddianın boşa geçmediğinin kanıtı.
      expect(
        CycleAlertService.intermenstrualEpisodes(
          dailyLogs: lohia,
          periodLogs: regller,
          breaks: const [],
        ),
        isNotEmpty,
      );
    });
  });

  group('gebelikteki belirtiler', () {
    test('ilk trimester bulantısı bir regl evresine atanmıyor', () {
      final sat = DateTime(2026, 1, 1);
      final gebelik = Pregnancy.fromLmp(
        lmp: sat,
        cycleLength: 28,
        confirmedAt: DateTime(2026, 2, 1),
      );
      final regller = [
        PeriodLog(
          id: 'sat',
          startDate: sat,
          endDate: sat.add(const Duration(days: 4)),
        ),
      ];
      // 6–9. haftalar: SAT'tan 42–63 gün sonra, 90 günlük sınırın içinde.
      final bulanti = [
        for (var i = 42; i <= 63; i += 3)
          DailyLog(
            date: sat.add(Duration(days: i)),
            symptoms: const ['nausea'],
          ),
      ];

      final evreler = InsightsService.symptomsByPhase(
        'nausea',
        dailyLogs: bulanti,
        periodLogs: regller,
        periodLength: 5,
        breaks: CycleBreaks.fromPregnancies([gebelik]),
      );

      expect(
        evreler,
        isEmpty,
        reason:
            'Gebeliğin ilk 90 günü SAT\'tan sayılınca makul bir döngü günü '
            'çıkıyor; bulantı "luteal faz belirtisi" sayılıyordu.',
      );

      // Kesinti bilinmeseydi atanıyordu — iddia boşa geçmiyor.
      expect(
        InsightsService.symptomsByPhase(
          'nausea',
          dailyLogs: bulanti,
          periodLogs: regller,
          periodLength: 5,
          breaks: const [],
        ),
        isNotEmpty,
      );
    });
  });
}
