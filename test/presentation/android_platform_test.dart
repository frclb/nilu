import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/core/platform/app_platform.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Android'de henüz olmayan özelliklerin kapısı kapalı.
///
/// Apple Sağlık ve ana ekran widget'ı yalnızca iOS'ta yazıldı. Android'de
/// profil ekranından açılabilselerdi kullanıcı çalışmayan bir ekrana düşerdi
/// (widget eklenemez, Sağlık izni istenemez).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);
  tearDown(() => AppPlatform.debugAndroid = null);

  Future<BuildContext> profil(
    WidgetTester tester, {
    required bool android,
  }) async {
    AppPlatform.debugAndroid = android;
    resetStores(onboarded: true);
    await pumpScreen(
      tester,
      const ProfileSettingsScreen(),
      size: const Size(390, 2400),
    );
    return tester.element(find.byType(ProfileSettingsScreen));
  }

  testWidgets('iOS: Sağlık ve widget girişleri var', (tester) async {
    final ctx = await profil(tester, android: false);
    expect(find.text(ctx.tr('health_sync_title')), findsOneWidget);
    expect(find.text(ctx.tr('widgets_title')), findsOneWidget);
  });

  testWidgets('Android: Sağlık ve widget girişleri yok', (tester) async {
    final ctx = await profil(tester, android: true);
    expect(find.text(ctx.tr('health_sync_title')), findsNothing);
    expect(find.text(ctx.tr('widgets_title')), findsNothing);
    // Profilin geri kalanı yerinde.
    expect(find.text(ctx.tr('profile_notifications')), findsOneWidget);
  });
}
