import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/core/platform/app_platform.dart';
import 'package:period_tracker/data/datasources/health_datasource.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/health_sync/health_sync_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';
import 'package:period_tracker/presentation/widgets_preview/widgets_preview_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Android'de Apple Sağlık'ın yerini Health Connect alıyor; widget iki
/// platformda da var ama eklenme yolu farklı.
///
/// Metinler platforma göre seçiliyor: Android'de "Apple Sağlık" ya da
/// "Bekleme modu" yazan bir ekran kullanıcıyı olmayan bir şeye yönlendirirdi.
class _HazirSaglik extends HealthDatasource {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> canInstall() async => false;
}

class _YokSaglik extends HealthDatasource {
  _YokSaglik({required this.kurulabilir});

  final bool kurulabilir;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> canInstall() async => kurulabilir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);
  tearDown(() => AppPlatform.debugAndroid = null);

  Future<BuildContext> ac(
    WidgetTester tester,
    Widget ekran, {
    required bool android,
    Size size = const Size(390, 2400),
  }) async {
    AppPlatform.debugAndroid = android;
    resetStores(onboarded: true);
    await pumpScreen(tester, ekran, size: size);
    return tester.element(find.byWidget(ekran));
  }

  group('profil', () {
    testWidgets('iOS: Apple Sağlık ve widget girişleri', (tester) async {
      final ctx = await ac(
        tester,
        const ProfileSettingsScreen(),
        android: false,
      );
      expect(find.text(ctx.tr('health_sync_title')), findsOneWidget);
      expect(find.text(ctx.tr('widgets_title')), findsOneWidget);
    });

    testWidgets('Android: Health Connect ve widget girişleri', (tester) async {
      final ctx = await ac(
        tester,
        const ProfileSettingsScreen(),
        android: true,
      );
      expect(find.text(ctx.tr('health_connect_sync_title')), findsOneWidget);
      expect(find.text(ctx.tr('health_sync_title')), findsNothing);
      expect(find.text(ctx.tr('widgets_title')), findsOneWidget);
    });
  });

  group('Sağlık ekranı', () {
    testWidgets('Android: metinler Health Connect\'e göre', (tester) async {
      final ekran = HealthSyncScreen(health: _HazirSaglik());
      final ctx = await ac(tester, ekran, android: true);
      expect(find.text(ctx.tr('health_connect_sync_title')), findsOneWidget);
      expect(find.text(ctx.tr('health_connect_import_button')), findsOneWidget);
      expect(find.text(ctx.tr('health_connect_write_title')), findsOneWidget);
      expect(find.text(ctx.tr('health_sync_title')), findsNothing);
      expect(find.text(ctx.tr('health_import_button')), findsNothing);
    });

    testWidgets('iOS: metinler Apple Sağlık\'a göre', (tester) async {
      final ekran = HealthSyncScreen(health: _HazirSaglik());
      final ctx = await ac(tester, ekran, android: false);
      expect(find.text(ctx.tr('health_import_button')), findsOneWidget);
      expect(find.text(ctx.tr('health_connect_import_button')), findsNothing);
    });

    testWidgets('Health Connect yoksa yükleme düğmesi', (tester) async {
      final ekran = HealthSyncScreen(health: _YokSaglik(kurulabilir: true));
      final ctx = await ac(tester, ekran, android: true);
      expect(find.text(ctx.tr('health_connect_unavailable')), findsOneWidget);
      expect(find.byKey(const Key('health_connect_install')), findsOneWidget);
    });

    testWidgets('cihaz desteklemiyorsa düğme yok', (tester) async {
      final ekran = HealthSyncScreen(health: _YokSaglik(kurulabilir: false));
      await ac(tester, ekran, android: true);
      expect(find.byKey(const Key('health_connect_install')), findsNothing);
    });
  });

  group('widget ekranı', () {
    testWidgets('Android: ekleme yolu ve not Android\'e göre', (tester) async {
      final ctx = await ac(tester, const WidgetsPreviewScreen(), android: true);
      expect(find.text(ctx.tr('widgets_how_to_add_android')), findsOneWidget);
      expect(find.text(ctx.tr('widgets_privacy_note_android')), findsOneWidget);
      expect(find.text(ctx.tr('widgets_how_to_add')), findsNothing);
    });

    testWidgets('iOS: Araç Takımı yolu', (tester) async {
      final ctx = await ac(
        tester,
        const WidgetsPreviewScreen(),
        android: false,
      );
      expect(find.text(ctx.tr('widgets_how_to_add')), findsOneWidget);
      // iOS'ta uygulamadan ekleme yok.
      expect(find.byKey(const Key('widget_pin_small')), findsNothing);
    });
  });
}
