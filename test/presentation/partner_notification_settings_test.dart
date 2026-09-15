import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/notification_settings_repository.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/partner_match/partner_notification_settings_screen.dart';

/// Partner → Bildirim Ayarları ekranı.
///
/// Ekran ilk açılışta kırmızı hata sayfasına düşüyordu: modelin
/// `ovulationValue` varsayılanı `'same_day'`'di ama açılır listede
/// `'0'/'1'/'2'` vardı ve `DropdownButton` değerini öğeler arasında
/// bulamayınca assert atıyordu. Hiç kayıt yapmamış **her** kullanıcı
/// etkileniyordu; hiçbir test o ekranı hiç çizmediği için görülmemişti.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> open(WidgetTester tester) async {
    // Varsayılan 800x600 test yüzeyi bu ekran için gerçekçi değil.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('tr'),
          // Uygulamadaki listeyle aynı: yalnızca kendi delegemizi vermek
          // Material'ınkileri düşürüyor ve `AppBar` ile `DropdownButton`
          // "No MaterialLocalizations found" diye assert atıyor.
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('tr')],
          home: PartnerNotificationSettingsScreen(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  group('ekran açılışı', () {
    testWidgets('hiç kayıt yokken çizilir', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await open(tester);

      expect(find.byType(PartnerNotificationSettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('depoda tanınmayan değer varsa da çizilir', (tester) async {
      // Eski sürümün yazmış olabileceği değer. Doğrudan geçirilirse
      // `DropdownButton` assert atar.
      SharedPreferences.setMockInitialValues({
        'flutter.notif_partner_ovulation_value': 'same_day',
        'flutter.notif_partner_period_start_value': 'bir_gun_once',
      });

      await open(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('varsayılanlar açılır liste öğeleriyle eşleşir', () {
    const defaults = PartnerNotificationSettings();

    test('her varsayılan kendi kümesinde', () {
      expect(
        PartnerNotificationSettings.periodStartValues,
        contains(defaults.periodStartValue),
      );
      expect(
        PartnerNotificationSettings.ovulationValues,
        contains(defaults.ovulationValue),
        reason: 'regresyon: varsayılan "same_day" idi, liste 0/1/2 idi',
      );
      expect(
        PartnerNotificationSettings.symptomsValues,
        contains(defaults.symptomsValue),
      );
      expect(
        PartnerNotificationSettings.dailySupportValues,
        contains(defaults.dailySupportValue),
      );
    });
  });

  group('depo tanınmayan değeri varsayılana düşürür', () {
    test('bozuk değer okunmaz', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.notif_partner_ovulation_value': 'same_day',
      });

      final settings = await NotificationSettingsRepository()
          .getPartnerSettings();

      expect(settings.ovulationValue, '0');
    });

    test('geçerli değer korunur', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.notif_partner_ovulation_value': '2',
      });

      final settings = await NotificationSettingsRepository()
          .getPartnerSettings();

      expect(settings.ovulationValue, '2');
    });
  });
}
