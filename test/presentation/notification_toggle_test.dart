import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/notification_settings_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/profile/notification_settings_screen.dart';

/// Genel bildirim anahtarları.
///
/// Anahtar açılınca ayar **önce** kaydediliyor, sonra izin isteniyordu. İzin
/// reddedilince anahtar açık kalıyor ve kayıtlı kalıyordu: kullanıcı
/// hatırlatıcıların kurulduğunu sanıyor ama hiçbir bildirim gelmiyor.
///
/// Testte bildirim eklentisinin platform kanalı yok, yani izin isteği hep
/// başarısız oluyor — reddedilmiş izin durumunun ta kendisi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/en.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<void> open(WidgetTester tester, {bool hormonal = false}) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      // Ayar `SecureStore`'da tutuluyor; `SharedPreferences` mock'u buraya
      // ulaşmıyor. Görünümün beslendiği yerden yazmak gerekiyor.
      if (hormonal) {
        await CycleSettingsRepository().setHormonalContraception(true);
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: ChangeNotifierProvider(
            create: (_) => CalendarViewModel(),
            child: const NotificationSettingsScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Etiketiyle bir anahtarı bulur.
  ///
  /// Ekran `SwitchListTile` kullanıyor; içindeki `Switch`'i aramak yerine
  /// doğrudan onu bulmak hem daha sağlam hem de dokunma hedefi o.
  Finder switchTile(String key) => find.ancestor(
    of: find.text(dictionary[key] as String),
    matching: find.byType(SwitchListTile),
  );

  bool switchValue(WidgetTester tester, String key) =>
      tester.widget<SwitchListTile>(switchTile(key).first).value;

  Future<void> toggle(WidgetTester tester, String key) async {
    await tester.tap(switchTile(key).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('izin verilmeyince anahtar eski hâline döner', (tester) async {
    await open(tester);

    // Varsayılan kapalı olan anahtar: açmayı deniyoruz.
    expect(
      switchValue(tester, 'notif_daily_logs'),
      isFalse,
      reason: 'başlangıç durumu kapalı olmalı',
    );

    await toggle(tester, 'notif_daily_logs');

    expect(
      switchValue(tester, 'notif_daily_logs'),
      isFalse,
      reason: 'izin alınamadan anahtar açık kalmamalı',
    );
  });

  testWidgets('doğurganlık izlenmiyorsa anahtar gösterilmiyor', (tester) async {
    // Hormonal doğum kontrolünde doğurganlık verisi kaynakta hiç
    // üretilmiyor; anahtar açılsa bile hiçbir bildirim planlanamaz.
    // Çalışmayan bir düğme bırakmak, kullanıcıya bildirimin gelmemesini
    // arıza gibi gösterirdi.
    await open(tester, hormonal: true);

    expect(
      find.text(dictionary['notif_fertile_window'] as String),
      findsNothing,
    );
    expect(
      find.text(dictionary['notif_period_reminders'] as String),
      findsOneWidget,
      reason: 'diğer anahtarlar yerinde kalmalı',
    );
  });

  testWidgets('doğurganlık izleniyorsa anahtar duruyor', (tester) async {
    await open(tester);

    expect(
      find.text(dictionary['notif_fertile_window'] as String),
      findsOneWidget,
    );
  });

  testWidgets('reddedilen izin kaydedilmez', (tester) async {
    await open(tester);

    await toggle(tester, 'notif_daily_logs');
    await tester.pump(const Duration(milliseconds: 200));

    final saved = await NotificationSettingsRepository().getGeneralSettings();

    expect(
      saved.dailyLogs,
      isFalse,
      reason: 'ekranda kapalı görünüp depoda açık kalmamalı',
    );
  });
}
