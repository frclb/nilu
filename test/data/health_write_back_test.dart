import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/datasources/health_datasource.dart';
import 'package:period_tracker/data/repositories/health_write_back.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/health_export.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/health_sync/health_sync_screen.dart';

import '../presentation/pregnancy_fixtures.dart';
import '../presentation/screen_harness.dart';

/// Platform kanalı yerine yazılanları kaydeden Sağlık kaynağı.
class _SahteSaglik extends HealthDatasource {
  _SahteSaglik({this.erisim = HealthAccess.granted, this.yazilir = true});

  final HealthAccess erisim;
  final bool yazilir;
  final List<({List<HealthPeriodDay> days, DateTime from, DateTime to})>
  aynalar = [];
  bool? yazmaIstendi;
  Completer<void>? bekletici;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> requestHistoryAccess() async => true;

  @override
  Future<bool> canInstall() async => false;

  @override
  Future<HealthAccess> requestPermissions({bool includeWrite = false}) async {
    yazmaIstendi = includeWrite;
    return erisim;
  }

  @override
  Future<bool> mirrorPeriods(
    List<HealthPeriodDay> days, {
    required DateTime from,
    required DateTime to,
  }) async {
    aynalar.add((days: days, from: from, to: to));
    final b = bekletici;
    if (b != null) await b.future;
    return yazilir;
  }
}

/// Regl günlerini Apple Sağlık'a yazma.
///
/// `writePeriod` vardı ama hiçbir yerden çağrılmıyordu ve her güne "orta"
/// akış yazıyordu. Mağaza metni Sağlık'a yazmayı vaat ediyordu. Artık
/// isteğe bağlı bir ayar: kapalıyken hiçbir şey yazılmıyor; açıkken her
/// regl değişikliğinden sonra uygulamanın kendi kayıtları ayna gibi
/// yeniden yazılıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  test('Sağlık\'tan yalnız regl okunuyor', () {
    // Uyku ve nabız isteniyordu ama hiçbir ekran kullanmıyordu.
    expect(HealthDatasource.readTypes, [HealthDataType.MENSTRUATION_FLOW]);
    expect(HealthDatasource.writeTypes, [HealthDataType.MENSTRUATION_FLOW]);
  });

  group('yazılacak günler', () {
    final bugun = DateTime(2026, 10, 7);
    DateTime g(int n) => DateTime(bugun.year, bugun.month, bugun.day + n);

    test('akış yalnız kullanıcı girdiyse; ilk gün döngü başı', () {
      final gunler = HealthExport.periodDays(
        periods: [PeriodLog(id: 'a', startDate: g(-20), endDate: g(-17))],
        dailyLogs: [
          DailyLog(date: g(-20), flowIntensity: 'heavy'),
          DailyLog(date: g(-19), flowIntensity: 'spotting'),
          DailyLog(date: g(-18), flowIntensity: 'light'),
        ],
        today: bugun,
      );
      expect(gunler.map((d) => (d.date, d.flow, d.isStartOfCycle)), [
        (g(-20), 'heavy', true),
        (g(-19), null, false),
        (g(-18), 'light', false),
        (g(-17), null, false),
      ]);
    });

    test('süren dönem bugüne kadar; çakışan günler bir kez', () {
      final gunler = HealthExport.periodDays(
        periods: [
          PeriodLog(id: 'b', startDate: g(-1)),
          PeriodLog(id: 'a', startDate: g(-2), endDate: g(-1)),
        ],
        dailyLogs: const [],
        today: bugun,
      );
      expect(gunler.map((d) => d.date), [g(-2), g(-1), g(0)]);
      expect(gunler.first.isStartOfCycle, isTrue);
    });
  });

  group('ayar', () {
    final regller = [PeriodLog(id: 'a', startDate: today, endDate: today)];

    test('kapalıyken hiçbir şey yazılmıyor', () async {
      final saglik = _SahteSaglik();
      final yazma = HealthWriteBack(datasource: saglik);
      expect(await yazma.isEnabled(), isFalse, reason: 'Varsayılan kapalı');
      expect(
        await yazma.syncIfEnabled(periods: regller, dailyLogs: const []),
        isNull,
      );
      expect(saglik.aynalar, isEmpty);
    });

    test('açıkken son üç yıl ayna olarak yazılıyor', () async {
      final saglik = _SahteSaglik();
      final yazma = HealthWriteBack(datasource: saglik);
      await yazma.setEnabled(true);
      final simdi = DateTime(2026, 10, 7, 15);
      expect(
        await yazma.syncIfEnabled(
          periods: [
            PeriodLog(
              id: 'eski',
              startDate: DateTime(2023, 1, 1),
              endDate: DateTime(2023, 1, 3),
            ),
            PeriodLog(
              id: 'yeni',
              startDate: DateTime(2026, 10, 1),
              endDate: DateTime(2026, 10, 2),
            ),
          ],
          dailyLogs: const [],
          now: simdi,
        ),
        isTrue,
      );
      final ayna = saglik.aynalar.single;
      expect(ayna.from, DateTime(2023, 10, 7));
      expect(ayna.to, DateTime(2026, 10, 8), reason: 'Bugün dahil');
      expect(
        ayna.days.map((d) => d.date),
        [DateTime(2026, 10, 1), DateTime(2026, 10, 2)],
        reason: 'Pencere dışındaki eski dönem yazılmamalı',
      );
    });

    test('yazımlar sırayla: ikincisi birincinin bitmesini bekliyor', () async {
      final saglik = _SahteSaglik()..bekletici = Completer<void>();
      final yazma = HealthWriteBack(datasource: saglik);
      await yazma.setEnabled(true);

      final ilk = yazma.syncIfEnabled(periods: regller, dailyLogs: const []);
      final ikinci = yazma.syncIfEnabled(
        periods: const [],
        dailyLogs: const [],
      );
      await pumpEventQueue();
      expect(saglik.aynalar, hasLength(1), reason: 'İkinci yazım beklemedi');

      saglik.bekletici!.complete();
      await ilk;
      await ikinci;
      expect(saglik.aynalar, hasLength(2));
      expect(saglik.aynalar.last.days, isEmpty);
    });
  });

  group('takvim', () {
    Future<CalendarViewModel> kur(
      _SahteSaglik saglik, {
      bool acik = true,
    }) async {
      final yazma = HealthWriteBack(datasource: saglik);
      if (acik) await yazma.setEnabled(true);
      final vm = CalendarViewModel(healthWriteBack: yazma);
      await vm.refreshData();
      return vm;
    }

    test('regl değişince Sağlık\'a yazılıyor', () async {
      final saglik = _SahteSaglik();
      final vm = await kur(saglik);
      await vm.togglePeriodDay(daysAgo(3));
      await pumpEventQueue();
      expect(saglik.aynalar, hasLength(1));
      expect(saglik.aynalar.single.days.first.date, daysAgo(3));
    });

    test('ayar kapalıyken regl değişikliği yazılmıyor', () async {
      final saglik = _SahteSaglik();
      final vm = await kur(saglik, acik: false);
      await vm.togglePeriodDay(daysAgo(3));
      await pumpEventQueue();
      expect(saglik.aynalar, isEmpty);
    });

    test('yalnız akış değişince günlük kayıt yeniden yazdırıyor', () async {
      final saglik = _SahteSaglik();
      await const PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'a', startDate: daysAgo(2), endDate: daysAgo(1)),
      ]);
      final vm = await kur(saglik);

      await vm.updateDailyLog(DailyLog(date: daysAgo(2), notes: 'not'));
      await pumpEventQueue();
      expect(saglik.aynalar, isEmpty, reason: 'Akış değişmedi');

      await vm.updateDailyLog(
        DailyLog(date: daysAgo(2), notes: 'not', flowIntensity: 'heavy'),
      );
      await pumpEventQueue();
      expect(saglik.aynalar.single.days.first.flow, 'heavy');
    });
  });

  group('ekran', () {
    Future<BuildContext> ac(WidgetTester tester, _SahteSaglik saglik) async {
      await seedCycles();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(
          HealthSyncScreen(
            health: saglik,
            writeBack: HealthWriteBack(datasource: saglik),
          ),
        ),
      );
      return tester.element(find.byType(HealthSyncScreen));
    }

    Finder anahtar() => find.byKey(const Key('health_write_back'));
    bool acik(WidgetTester t) => t.widget<SwitchListTile>(anahtar()).value;

    testWidgets('açınca yazma izni isteniyor ve geçmiş yazılıyor', (
      tester,
    ) async {
      final saglik = _SahteSaglik();
      final ctx = await ac(tester, saglik);
      expect(acik(tester), isFalse);

      await tester.tap(anahtar());
      await settleAsync(tester);
      expect(saglik.yazmaIstendi, isTrue);
      expect(saglik.aynalar, hasLength(1));
      expect(saglik.aynalar.single.days, isNotEmpty);
      expect(acik(tester), isTrue);
      expect(find.text(ctx.tr('health_write_done')), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('health_write_back'), isTrue);

      await tester.tap(anahtar());
      await settleAsync(tester);
      expect(acik(tester), isFalse);
      expect(find.text(ctx.tr('health_write_off')), findsOneWidget);
      expect(prefs.getBool('health_write_back'), isFalse);
    });

    testWidgets('izin verilmezse açılmıyor', (tester) async {
      final saglik = _SahteSaglik(erisim: HealthAccess.denied);
      final ctx = await ac(tester, saglik);
      await tester.tap(anahtar());
      await settleAsync(tester);
      expect(acik(tester), isFalse);
      expect(saglik.aynalar, isEmpty);
      expect(find.text(ctx.tr('health_permission_denied')), findsOneWidget);
    });

    testWidgets('yazılamazsa açık görünmüyor', (tester) async {
      final saglik = _SahteSaglik(yazilir: false);
      final ctx = await ac(tester, saglik);
      await tester.tap(anahtar());
      await settleAsync(tester);
      expect(acik(tester), isFalse);
      expect(find.text(ctx.tr('health_write_failed')), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('health_write_back'),
        isNot(true),
        reason: 'Yazılamadığı hâlde sonraki değişikliklerde yazmayı deneyecek',
      );
    });
  });
}
