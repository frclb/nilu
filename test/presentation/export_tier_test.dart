import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/privacy_settings_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/profile/privacy_security_screen.dart';

/// Dışa aktarma kutusunun katmana göre söyledikleri.
///
/// Makine-okunur bir kopya almak KVKK ve GDPR'da bir hak ve gizlilik
/// politikasının 9. bölümü bunu vaat ediyor; ücrete bağlanamaz. Hekim
/// özeti ile tablo ise kolaylık, onlar Premium'da.
///
/// Kutunun metni de buna uymalı: ücretsiz kullanıcıya üretilmeyecek
/// dosyaları saymak, olmayan bir şeyi vaat etmek olurdu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `local_auth` platform kanalı testte yok; ekran `capability()`
  // çözülmeden yükleme durumundan çıkmıyordu ve hiçbir karo çizilmiyordu.
  // Kanal sahteleniyor: biyometri yok, cihaz şifresi de yok — gizlilik
  // ekranının en sade hâli.
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'),
          (call) async {
            switch (call.method) {
              case 'getAvailableBiometrics':
                return <String>[];
              case 'deviceSupportsBiometrics':
              case 'isDeviceSupported':
                return false;
            }
            return null;
          },
        );
  });

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<void> openDialog(WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
              ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),
              ChangeNotifierProvider(create: (_) => CalendarViewModel()),
              ChangeNotifierProvider(create: (_) => UserViewModel()),
            ],
            child: const PrivacySecurityScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Metin yerine `ListTile`: dokunma hedefi o, ve metne dokunmak
    // ekranın kaydırma durumuna göre boşa gidebiliyor.
    final action = find.ancestor(
      of: find.text(dictionary['privacy_export'] as String),
      matching: find.byType(ListTile),
    );
    await tester.ensureVisible(action.first);
    await tester.pumpAndSettle();
    await tester.tap(action.first);
    await tester.pumpAndSettle();
  }

  testWidgets('ücretsiz kullanıcıya yedek vaat ediliyor', (tester) async {
    // `SubscriptionViewModel` mağazaya ulaşamadığı için testte hep
    // ücretsiz: aradığımız durum tam olarak bu.
    await openDialog(tester);

    expect(
      find.text(dictionary['privacy_export_desc_free'] as String),
      findsOneWidget,
      reason: 'ücretsiz metin gösterilmiyor',
    );
  });

  testWidgets('üretilmeyecek dosyalar sayılmıyor', (tester) async {
    await openDialog(tester);

    expect(
      find.text(dictionary['privacy_export_desc'] as String),
      findsNothing,
      reason: 'ücretsiz kullanıcıya üç dosya vaat ediliyor',
    );
  });

  testWidgets('kutu premium duvarına dönüşmüyor', (tester) async {
    // Eskiden dışa aktarma tamamen kilitliydi ve düğme kullanıcıyı
    // doğrudan premium ekranına atıyordu. Artık yedek herkese açık.
    await openDialog(tester);

    expect(
      find.text(dictionary['privacy_export_confirm'] as String),
      findsOneWidget,
      reason: 'onay düğmesi yok — akış kilitli olabilir',
    );
  });

  group('parolalı yedek', () {
    Finder onay() => find.byKey(const Key('privacy_export_confirm'));
    bool etkin(WidgetTester tester) =>
        tester.widget<ElevatedButton>(onay()).onPressed != null;

    Future<void> yaz(WidgetTester tester, String alan, String deger) async {
      await tester.enterText(find.byKey(Key(alan)), deger);
      await tester.pump();
    }

    testWidgets('varsayılan kapalı, düz yedek hemen alınabiliyor', (
      tester,
    ) async {
      await openDialog(tester);
      expect(find.byKey(const Key('privacy_export_password')), findsNothing);
      expect(etkin(tester), isTrue);
    });

    testWidgets('açınca parola girilmeden aktarılmıyor; kısa ve uyuşmayan '
        'parola söyleniyor', (tester) async {
      await openDialog(tester);
      await tester.tap(find.byKey(const Key('privacy_export_protect')));
      await tester.pumpAndSettle();

      expect(
        find.text(dictionary['privacy_export_protect_desc'] as String),
        findsOneWidget,
        reason: 'Parolanın saklanmadığı baştan söylenmeli',
      );
      expect(etkin(tester), isFalse);

      await yaz(tester, 'privacy_export_password', 'kisa');
      expect(
        find.text(
          (dictionary['privacy_export_password_short'] as String).replaceAll(
            '{n}',
            '8',
          ),
        ),
        findsOneWidget,
      );
      expect(etkin(tester), isFalse);

      await yaz(tester, 'privacy_export_password', 'yeterince-uzun');
      await yaz(tester, 'privacy_export_password_repeat', 'baska-bir-sey');
      expect(
        find.text(dictionary['privacy_export_password_mismatch'] as String),
        findsOneWidget,
      );
      expect(etkin(tester), isFalse);

      await yaz(tester, 'privacy_export_password_repeat', 'yeterince-uzun');
      expect(etkin(tester), isTrue);
    });
  });

  testWidgets('cinsel aktivite kaydı anahtarı varsayılan kapalı ve '
      'kalıcı', (tester) async {
    await openDialog(tester);
    await tester.tap(find.text(dictionary['cancel'] as String));
    await tester.pumpAndSettle();

    final anahtar = find.byKey(const Key('privacy_sexual_log'));
    await tester.ensureVisible(anahtar);
    expect(tester.widget<SwitchListTile>(anahtar).value, isFalse);

    await tester.tap(anahtar);
    await tester.pumpAndSettle();
    final kayitli = await tester.runAsync(
      () => const PrivacySettingsRepository().getSexualActivityLogging(),
    );
    expect(kayitli, isTrue);
  });
}
