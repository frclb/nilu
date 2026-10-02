import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/core/navigation/navigation_service.dart';
import 'package:period_tracker/data/local/reminder_scheduler.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/reminders/reminder_sync.dart';

import 'screen_harness.dart';

/// İzin durumunu taklit eden zamanlayıcı. İzin isteği her zaman kabul
/// ediliyor; o andan sonra izin "verilmiş" görünüyor — iOS'taki gibi.
class _Zamanlayici extends ReminderScheduler {
  _Zamanlayici({required this.izinli});

  bool izinli;
  int istek = 0;
  int uygulama = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> isPermissionGranted() async => izinli;

  @override
  Future<bool> requestPermission() async {
    istek++;
    izinli = true;
    return true;
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> apply(
    List<ScheduledReminder> reminders, {
    required String Function(String key) localize,
  }) async => uygulama++;

  @override
  Future<List<PendingNotificationRequest>> pending() async => const [];
}

/// İzin verilmiş kullanıcıya gerekçe kutusu bir daha açılmıyor mu?
///
/// Oturum bayrağı yalnızca "şimdi değil" ve reddedilme yolunda kuruluyordu.
/// İzin veren kullanıcı ise kutuyu **her** plan değişikliğinde yeniden
/// görüyordu: her açılışta, regl işaretleyince, gebelik başlatınca, randevu
/// girince. Uygulamanın en sık açılan ekranında sürekli çıkan bir kutu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  final bugun = DateTime.now();
  final gun = DateTime(bugun.year, bugun.month, bugun.day);

  Future<void> bekle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<BuildContext> kur(WidgetTester tester, _Zamanlayici z) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    // Tahmin üretecek kadar geçmiş: varsayılan ayarlarda regl ve doğurganlık
    // hatırlatıcıları açık, yani plan boş değil.
    await tester.runAsync(
      () => const PeriodRepository().savePeriodLogs([
        for (final once in [66, 38, 10])
          PeriodLog(
            id: 'p$once',
            startDate: gun.subtract(Duration(days: once)),
            endDate: gun.subtract(Duration(days: once - 4)),
          ),
      ]),
    );

    await pumpScreen(
      tester,
      ReminderSync(
        scheduler: z,
        child: const Scaffold(body: SizedBox(key: Key('kok'))),
      ),
      size: const Size(390, 844),
      navigatorKey: NavigationService().navigatorKey,
    );
    await bekle(tester);
    return tester.element(find.byKey(const Key('kok')));
  }

  /// Plan imzasını değiştirir: bugün yeni bir regl başlıyor.
  Future<void> reglBaslat(WidgetTester tester, BuildContext ctx) async {
    final takvim = ctx.read<CalendarViewModel>();
    final once = takvim.cycleInfo.predictedNextPeriod;
    await tester.runAsync(() => takvim.togglePeriodDay(gun));
    await bekle(tester);
    expect(
      takvim.cycleInfo.predictedNextPeriod,
      isNot(once),
      reason: 'Tahmin değişmedi; imza da değişmez, test bir şey sınamaz',
    );
  }

  testWidgets('izin verilmişse kutu hiç açılmıyor, plan doğrudan kuruluyor', (
    tester,
  ) async {
    final z = _Zamanlayici(izinli: true);
    final ctx = await kur(tester, z);
    final baslik = find.text(ctx.tr('reminder_permission_title'));

    expect(baslik, findsNothing, reason: 'İzni olan kullanıcıya gerekçe');
    expect(z.uygulama, 1, reason: 'Plan kurulmadı');

    await reglBaslat(tester, ctx);

    expect(
      baslik,
      findsNothing,
      reason: 'Regl işaretleyince gerekçe kutusu yeniden açıldı',
    );
    expect(z.uygulama, 2, reason: 'Yeni plan kurulmadı');
    expect(z.istek, 0);
  });

  testWidgets('izin yokken bir kez soruluyor; verildikten sonra bir daha '
      'sorulmuyor', (tester) async {
    final z = _Zamanlayici(izinli: false);
    final ctx = await kur(tester, z);
    final baslik = find.text(ctx.tr('reminder_permission_title'));

    expect(baslik, findsOneWidget, reason: 'İlk seferde gerekçe gösterilmeli');
    await tester.tap(find.text(ctx.tr('reminder_permission_continue')));
    await bekle(tester);

    expect(z.istek, 1);
    expect(z.uygulama, 1);
    expect(baslik, findsNothing);

    await reglBaslat(tester, ctx);

    expect(
      baslik,
      findsNothing,
      reason:
          'İzin verildi ama bir sonraki plan değişikliğinde kutu yine '
          'açıldı',
    );
    expect(z.istek, 1, reason: 'İzin ikinci kez istendi');
    expect(z.uygulama, 2);
  });
}
