import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/core/platform/app_icon.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/appearance/appearance_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Sade ana ekran simgesi: yerel kanala doğru ad gidiyor mu, desteklenmeyen
/// yerde bölüm gizli mi?
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  const kanal = MethodChannel(AppIconService.channelName);

  /// Yerel tarafın taklidi; `set` çağrılarının argümanlarını topluyor.
  List<Object?> taklit({
    bool destek = true,
    String? mevcut,
    bool basarili = true,
  }) {
    final cagrilar = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(kanal, (call) async {
          switch (call.method) {
            case 'isSupported':
              return destek;
            case 'current':
              return mevcut;
            case 'set':
              cagrilar.add(call.arguments);
              return basarili;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(kanal, null),
    );
    return cagrilar;
  }

  Future<void> ac(WidgetTester tester) async {
    await pumpScreen(
      tester,
      const AppearanceScreen(),
      size: const Size(393, 852),
    );
    await settleAsync(tester);
  }

  Future<void> dokun(WidgetTester tester, AppIconChoice c) async {
    final f = find.byKey(Key('appearance_icon_${c.name}'));
    await tester.scrollUntilVisible(f, 200);
    await tester.tap(f);
    await settleAsync(tester);
  }

  testWidgets('sade simge seçilince yerel tarafa doğru ad gidiyor; geri '
      'dönülebiliyor', (tester) async {
    final cagrilar = taklit();
    await ac(tester);

    await dokun(tester, AppIconChoice.neutral);
    expect(cagrilar, [AppIconService.neutralIconName]);
    expect(
      tester.getSemantics(find.byKey(const Key('appearance_icon_neutral'))),
      containsSemantics(isSelected: true),
    );

    await dokun(tester, AppIconChoice.standard);
    expect(cagrilar, [AppIconService.neutralIconName, null]);
  });

  testWidgets('açılışta mevcut simge seçili görünüyor', (tester) async {
    taklit(mevcut: AppIconService.neutralIconName);
    await ac(tester);
    final semantik = tester.ensureSemantics();
    final f = find.bySemanticsLabel(
      tester
          .element(find.byType(AppearanceScreen))
          .tr('appearance_icon_neutral'),
    );
    expect(tester.getSemantics(f), containsSemantics(isSelected: true));
    semantik.dispose();
  });

  testWidgets('değişmezse seçim kaymıyor ve söyleniyor', (tester) async {
    final cagrilar = taklit(basarili: false);
    await ac(tester);
    await dokun(tester, AppIconChoice.neutral);

    expect(cagrilar, hasLength(1));
    final ctx = tester.element(find.byType(AppearanceScreen));
    expect(find.text(ctx.tr('appearance_icon_failed')), findsOneWidget);
  });

  testWidgets('desteklenmiyorsa bölüm yok', (tester) async {
    taklit(destek: false);
    await ac(tester);
    expect(find.byKey(const Key('appearance_icon_section')), findsNothing);
  });

  testWidgets('kanal hiç yoksa (başka platform) bölüm yok, hata yok', (
    tester,
  ) async {
    await ac(tester);
    expect(find.byKey(const Key('appearance_icon_section')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
