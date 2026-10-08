import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/local/reminder_scheduler.dart';
import 'package:period_tracker/data/repositories/notification_settings_repository.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/profile/notification_settings_screen.dart';

/// İzin durumunu taklit eden zamanlayıcı.
class _Zamanlayici extends ReminderScheduler {
  _Zamanlayici({required this.izinli, this.verilir = true});

  bool izinli;
  final bool verilir;
  int istek = 0;
  int uygulama = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> isPermissionGranted() async => izinli;

  @override
  Future<bool> requestPermission() async {
    istek++;
    return izinli = verilir;
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

/// Bildirim izni yokken ekranın söyledikleri.
///
/// iOS sistem istemini **bir kez** gösteriyor. Reddedildikten sonra anahtarı
/// açmak hiçbir şey yapmıyor; kullanıcının bunu neden olduğunu görmesi ve
/// düzeltebileceği yere gidebilmesi gerekiyor.
///
/// Varsayılan olarak regl ve doğurganlık hatırlatıcıları açık. İzin yokken
/// ekran anahtarları açık gösteriyor, uyarı ancak bir anahtara dokununca
/// çıkıyordu: kullanıcı hatırlatıcıların kurulduğunu sanıyordu.
///
/// Zamanlayıcı verilmeyen testlerde bildirim eklentisi yok, yani izin
/// okunamıyor ve istek başarısız oluyor — reddedilmiş iznin ta kendisi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<void> open(WidgetTester tester, {ReminderScheduler? scheduler}) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Ayarlar depodan **asenkron** okunuyor; `pumpAndSettle` sahte saatte
    // bunu beklemiyor. Gerçek zamanlı bir pencere açılıyor.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr')],
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CalendarViewModel()),
            ],
            child: NotificationSettingsScreen(scheduler: scheduler),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pumpAndSettle();
  }

  final notice = find.text(dictionary['notif_permission_off'] as String);

  Finder tile(String key) => find.ancestor(
    of: find.text(dictionary[key] as String),
    matching: find.byType(SwitchListTile),
  );

  bool value(WidgetTester tester, String key) =>
      tester.widget<SwitchListTile>(tile(key)).value;

  testWidgets('izin yokken açık hatırlatıcıların gelmediği baştan yazıyor', (
    tester,
  ) async {
    await open(tester);
    expect(notice, findsOneWidget, reason: 'Anahtara dokunmadan görünmeli');
    expect(
      find.byKey(const Key('notif_permission_allow')),
      findsOneWidget,
      reason: 'Uyarı düzeltilebileceği yeri göstermeli',
    );
  });

  testWidgets('izin varsa uyarı yok', (tester) async {
    await open(tester, scheduler: _Zamanlayici(izinli: true));
    expect(notice, findsNothing);
  });

  testWidgets('açıklama geçici değil, zamanla kaybolmaz', (tester) async {
    await open(tester);
    await tester.tap(tile('notif_daily_logs'));
    await tester.pumpAndSettle();

    // Eskiden bu bir snackbar'dı: kullanıcıyı ekrandan ekrana takip ediyor,
    // sonra da kayboluyordu. Anahtar kapalı kaldığı sürece sebebi de durmalı.
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();

    expect(notice, findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('izin verilmeyince açılan anahtar açık kalmaz', (tester) async {
    await open(tester);
    expect(value(tester, 'notif_daily_logs'), isFalse);
    await tester.tap(tile('notif_daily_logs'));
    await tester.pumpAndSettle();

    // Açık kalsaydı kullanıcı hatırlatıcının kurulduğunu sanırdı.
    expect(value(tester, 'notif_daily_logs'), isFalse);
  });

  testWidgets('izin yokken bir hatırlatıcı kapatılabiliyor', (tester) async {
    // Kapatmak da izin istiyordu; alınamayınca anahtar yeniden açılıyordu.
    final z = _Zamanlayici(izinli: false, verilir: false);
    await open(tester, scheduler: z);
    expect(value(tester, 'notif_period_reminders'), isTrue);

    await tester.tap(tile('notif_period_reminders'));
    await tester.pumpAndSettle();

    expect(value(tester, 'notif_period_reminders'), isFalse);
    expect(z.istek, 0, reason: 'Kapatmak için izin istenmemeli');
    final saved = await tester.runAsync(
      () => NotificationSettingsRepository().getGeneralSettings(),
    );
    expect(saved!.periodReminders, isFalse);
  });

  testWidgets('düğmeyle izin verilince uyarı kalkıyor, plan kuruluyor', (
    tester,
  ) async {
    final z = _Zamanlayici(izinli: false);
    await open(tester, scheduler: z);
    expect(notice, findsOneWidget);

    await tester.tap(find.byKey(const Key('notif_permission_allow')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(z.istek, 1);
    expect(z.uygulama, 1);
    expect(notice, findsNothing);
  });

  testWidgets('Ayarlar\'dan izin verip dönünce uyarı kalkıyor', (tester) async {
    final z = _Zamanlayici(izinli: false);
    await open(tester, scheduler: z);
    expect(notice, findsOneWidget);

    z.izinli = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(notice, findsNothing);
    expect(z.uygulama, 1);
    expect(z.istek, 0, reason: 'İzin zaten verilmişti');
  });
}
