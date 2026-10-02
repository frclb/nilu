import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/notification_settings_repository.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/profile/notification_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gizli bildirim anahtarı **kilit ekranına giden metni** değiştiriyor mu?
///
/// Ayarın kaydedilmesi yetmez: plan yeniden kurulmazsa kayıtlı ayar "gizli"
/// derken cihazda bekleyen bildirimler "Reglin 2 gün içinde başlayabilir"
/// diye kalır. Bu test eklentinin kanalına giden çağrıları yakalayıp
/// başlıklara bakıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  const kanal = MethodChannel('dexterous.com/flutter/local_notifications');

  /// Eklenti kanalı: izin verilmiş bir iOS cihazı gibi davranıyor.
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

  testWidgets(
    'açınca bekleyen her bildirim gizli başlıkla yeniden kuruluyor',
    (tester) async {
      final basliklar = kanaliTaklitEt();
      await seedCycles(lastStartAgo: 10);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const NotificationSettingsScreen()),
      );
      final ctx = tester.element(find.byType(NotificationSettingsScreen));
      final gizli = ctx.tr('notif_discreet_title');

      final anahtar = find.byKey(const Key('notif_discreet_switch'));
      await tester.scrollUntilVisible(anahtar, 300);
      await tester.tap(anahtar);
      await settleAsync(tester);

      final ayar = await tester.runAsync(
        () => NotificationSettingsRepository().getGeneralSettings(),
      );
      expect(ayar!.discreet, isTrue, reason: 'Ayar kaydedilmedi');
      expect(
        basliklar,
        isNotEmpty,
        reason: 'Plan yeniden kurulmadı; test bir şey sınamıyor',
      );
      expect(
        basliklar.toSet(),
        {gizli},
        reason: 'Kilit ekranına içerik sızıyor: ${basliklar.toSet()}',
      );

      // Kapatınca içerik geri geliyor.
      await tester.tap(anahtar);
      await settleAsync(tester);
      expect(basliklar, isNotEmpty);
      expect(basliklar, isNot(contains(gizli)));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('gebelik hatırlatıcıları anahtarı listede', (tester) async {
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const NotificationSettingsScreen()),
    );
    final ctx = tester.element(find.byType(NotificationSettingsScreen));
    final satir = find.text(ctx.tr('notif_care_setting'));
    await tester.scrollUntilVisible(satir, 300);
    expect(satir, findsOneWidget);
  });
}
