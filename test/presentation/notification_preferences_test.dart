import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/notification_settings_repository.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/profile/notification_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gün, saat ve gecikme seçimleri kaydediliyor ve **bekleyen bildirimler
/// yeniden kuruluyor** mu?
///
/// Yalnızca kaydetmek yetmez: plan yeniden yazılmazsa ayar "4 gün önce"
/// derken cihazda iki gün öncesine kurulmuş bildirim bekler.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  const kanal = MethodChannel('dexterous.com/flutter/local_notifications');

  /// Kurulan bildirimlerin başlıkları; her `cancelAll` listeyi sıfırlıyor,
  /// yani liste her an cihazda bekleyenleri gösteriyor.
  List<String> kanaliTaklitEt() {
    final basliklar = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kanal, (call) async {
          switch (call.method) {
            case 'initialize':
            case 'requestPermissions':
              return true;
            case 'checkPermissions':
              return {'isEnabled': true};
            case 'cancelAll':
              basliklar.clear();
              return null;
            case 'zonedSchedule':
              basliklar.add((call.arguments as Map)['title'] as String);
              return null;
            case 'pendingNotificationRequests':
              return <Object>[];
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kanal, null),
    );
    IOSFlutterLocalNotificationsPlugin.registerWith();
    return basliklar;
  }

  Future<GeneralNotificationSettings> kayitli(WidgetTester tester) async =>
      (await tester.runAsync(
        () => NotificationSettingsRepository().getGeneralSettings(),
      ))!;

  Future<BuildContext> ac(
    WidgetTester tester, {
    Locale locale = const Locale('tr'),
  }) async {
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const NotificationSettingsScreen()),
      locale: locale,
    );
    return tester.element(find.byType(NotificationSettingsScreen));
  }

  testWidgets(
    'kaç gün önce: seçim kaydediliyor ve plan yeniden kuruluyor',
    (tester) async {
      final basliklar = kanaliTaklitEt();
      await seedCycles(lastStartAgo: 5);
      final ctx = await ac(tester);

      final satir = find.byKey(const Key('notif_lead_days'));
      expect(
        find.descendant(
          of: satir,
          matching: find.text(ctx.tr('notif_lead_many', params: {'n': '2'})),
        ),
        findsOneWidget,
        reason: 'Varsayılan iki gün',
      );

      await tester.tap(satir);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notif_lead_option_4')));
      await settleAsync(tester);

      expect((await kayitli(tester)).periodLeadDays, 4);
      expect(
        find.descendant(
          of: satir,
          matching: find.text(ctx.tr('notif_lead_many', params: {'n': '4'})),
        ),
        findsOneWidget,
      );
      expect(
        basliklar,
        contains(ctx.tr('notif_period_reminders')),
        reason: 'Seçimden sonra plan yeniden yazılmadı',
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    // Türkçede tekil ve çoğul aynı ("1 gün önce"); fark İngilizcede.
    'tek gün tekil yazılıyor ("1 day before")',
    (tester) async {
      kanaliTaklitEt();
      await seedCycles(lastStartAgo: 5);
      final ctx = await ac(tester, locale: const Locale('en'));

      await tester.tap(find.byKey(const Key('notif_lead_days')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notif_lead_option_1')));
      await settleAsync(tester);

      expect((await kayitli(tester)).periodLeadDays, 1);
      expect(find.text(ctx.tr('notif_lead_one')), findsOneWidget);
      expect(find.text('1 days before'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'regl hatırlatıcısı kapalıyken gün seçimi gizli',
    (tester) async {
      kanaliTaklitEt();
      await seedCycles(lastStartAgo: 5);
      final ctx = await ac(tester);

      await tester.tap(find.text(ctx.tr('notif_period_reminders')));
      await settleAsync(tester);

      expect((await kayitli(tester)).periodReminders, isFalse);
      expect(find.byKey(const Key('notif_lead_days')), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'hatırlatma saati: seçilen saat kaydediliyor ve gösteriliyor',
    (tester) async {
      final basliklar = kanaliTaklitEt();
      await seedCycles(lastStartAgo: 5);
      final ctx = await ac(tester);

      final satir = find.byKey(const Key('notif_reminder_time'));
      await tester.scrollUntilVisible(satir, 300);
      await tester.tap(satir);
      await tester.pumpAndSettle();

      // Kadran yerine klavye girişi: testte kadrana dokunmak açıya bağlı.
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final alanlar = find.byType(TextField);
      await tester.enterText(alanlar.at(0), '07');
      await tester.enterText(alanlar.at(1), '30');
      await tester.tap(find.text(MaterialLocalizations.of(ctx).okButtonLabel));
      await settleAsync(tester);

      expect((await kayitli(tester)).reminderMinuteOfDay, 7 * 60 + 30);
      expect(
        find.descendant(of: satir, matching: find.text('07:30')),
        findsOneWidget,
      );
      expect(basliklar, isNotEmpty, reason: 'Plan yeniden yazılmadı');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'günlük kayıt saati yalnızca hatırlatıcı açıkken görünüyor',
    (tester) async {
      kanaliTaklitEt();
      await seedCycles(lastStartAgo: 5);
      final ctx = await ac(tester);

      expect(find.byKey(const Key('notif_daily_log_time')), findsNothing);

      await tester.tap(find.text(ctx.tr('notif_daily_logs')));
      await settleAsync(tester);

      final satir = find.byKey(const Key('notif_daily_log_time'));
      expect(satir, findsOneWidget);
      expect(
        find.descendant(of: satir, matching: find.text('20:00')),
        findsOne,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'gecikme anahtarı: kapatınca bekleyen gecikme bildirimi kalkıyor',
    (tester) async {
      final basliklar = kanaliTaklitEt();
      // Döngünün 20. günü: beklenen gün ve üç gün sonrası ileride.
      await seedCycles(lastStartAgo: 19);
      final ctx = await ac(tester);
      final gecikme = ctx.tr('notif_late_title');

      // Önce bir değişiklikle planı kur: gecikme bildirimi içinde olmalı.
      await tester.tap(find.byKey(const Key('notif_lead_days')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notif_lead_option_3')));
      await settleAsync(tester);
      expect(basliklar, contains(gecikme));

      final anahtar = find.byKey(const Key('notif_late_switch'));
      await tester.scrollUntilVisible(anahtar, 300);
      await tester.tap(anahtar);
      await settleAsync(tester);

      expect((await kayitli(tester)).lateReminder, isFalse);
      expect(basliklar, isNotEmpty, reason: 'Plan yeniden yazılmadı');
      expect(basliklar, isNot(contains(gecikme)));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
