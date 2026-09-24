import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/core/platform/app_settings_link.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/profile/notification_settings_screen.dart';

/// Bildirim izni alınamadığında ekranın söyledikleri.
///
/// iOS sistem istemini **bir kez** gösteriyor. Reddedildikten sonra anahtarı
/// açmak hiçbir şey yapmıyor; kullanıcının bunu neden olduğunu görmesi ve
/// düzeltebileceği yere gidebilmesi gerekiyor.
///
/// Testte bildirim eklentisi yok, yani `requestPermission` başarısız oluyor —
/// aradığımız durum tam olarak bu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<void> open(WidgetTester tester) async {
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
            child: const NotificationSettingsScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pumpAndSettle();
  }

  testWidgets('izin alınamayınca sebep ekranda kalır', (tester) async {
    await open(tester);

    final notice = find.text(dictionary['notif_permission_denied'] as String);
    expect(notice, findsNothing, reason: 'henüz bir şey denenmedi');

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(notice, findsOneWidget);
  });

  testWidgets('açıklama geçici değil, zamanla kaybolmaz', (tester) async {
    await open(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Eskiden bu bir snackbar'dı: kullanıcıyı ekrandan ekrana takip ediyor,
    // sonra da kayboluyordu. Anahtar kapalı kaldığı sürece sebebi de durmalı.
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();

    expect(
      find.text(dictionary['notif_permission_denied'] as String),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('desteklenen platformda ayarlara gidilebilir', (tester) async {
    await open(tester);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final button = find.text(dictionary['open_settings'] as String);
    expect(button, AppSettingsLink.isSupported ? findsOneWidget : findsNothing);
  });

  testWidgets('izin verilmeyince anahtar açık kalmaz', (tester) async {
    await open(tester);

    final first = find.byType(Switch).first;
    final before = tester.widget<Switch>(first).value;
    await tester.tap(first);
    await tester.pumpAndSettle();

    // Açık kalsaydı kullanıcı hatırlatıcıların kurulduğunu sanırdı.
    expect(tester.widget<Switch>(find.byType(Switch).first).value, before);
  });
}
