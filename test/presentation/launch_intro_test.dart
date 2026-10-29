import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_palette.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/design_system/brand_lotus.dart';
import 'package:period_tracker/design_system/launch_mark.dart';
import 'package:period_tracker/presentation/splash/launch_intro.dart';

/// Açılış perdesi: sistemin açılış ekranından uygulamaya geçiş.
///
/// En önemli iddia ilki: perdenin ilk karesi açılış ekranıyla aynı olmalı.
/// Açılış ekranı statik bir görsel (`tool/generate_launch_image.py`), perde
/// Dart; ikisi ayrışırsa derleme fark etmez, kullanıcı her açılışta zıplayan
/// bir logo görür.
void main() {
  final intro = find.byKey(const Key('launch_intro'));
  final spinner = find.byKey(const Key('launch_intro_spinner'));

  /// Yatay ölçek. `getMaxScaleOnAxis` z eksenini de sayıyor ve sıfır ölçekte
  /// 1 veriyor.
  double scaleOf(WidgetTester tester, String key) =>
      tester.widget<Transform>(find.byKey(Key(key))).transform.storage[0];

  /// Gerçek cihaz gibi kare kare ilerler: denetleyici ilk karesinde
  /// başlıyor, tek büyük `pump` bir kareyi atlayıp yanıltıyordu.
  Future<void> run(WidgetTester tester, Duration d) async {
    const frame = Duration(milliseconds: 16);
    for (var t = Duration.zero; t < d; t += frame) {
      await tester.pump(frame);
    }
  }

  BrandLotus lotus(WidgetTester tester) => tester.widget<BrandLotus>(
    find.descendant(of: intro, matching: find.byType(BrandLotus)),
  );

  Future<GlobalKey<_CounterState>> open(
    WidgetTester tester, {
    required ValueNotifier<bool> ready,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final counter = GlobalKey<_CounterState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.light(AppFlavor.plum)
            : AppTheme.dark(AppFlavor.plum),
        builder: (context, child) => LaunchIntro(
          ready: ready,
          isReady: () => ready.value,
          child: child!,
        ),
        home: _Counter(key: counter),
      ),
    );
    return counter;
  }

  testWidgets('ilk kare açılış ekranıyla aynı', (tester) async {
    await open(tester, ready: ValueNotifier(false));

    // Zemin, işaretin rengi, boyu ve yeri storyboard'daki gibi.
    final zemin = tester.widget<ColoredBox>(
      find.descendant(of: intro, matching: find.byType(ColoredBox)).first,
    );
    expect(zemin.color, AppTokens.light.background);
    expect(lotus(tester).color, AppPalette.plum700);
    expect(lotus(tester).sideOpacity, 0.75);
    expect(scaleOf(tester, 'launch_mark_lotus'), 1);
    expect(tester.getSize(find.byType(BrandLotus)).width, 120);
    expect(tester.getCenter(find.byType(BrandLotus)), const Offset(220, 478));
    // Daire henüz yok.
    expect(scaleOf(tester, 'launch_mark_circle'), 0);
  });

  testWidgets('koyu temada ilk kare koyu açılış ekranıyla aynı', (
    tester,
  ) async {
    await open(
      tester,
      ready: ValueNotifier(false),
      brightness: Brightness.dark,
    );

    final zemin = tester.widget<ColoredBox>(
      find.descendant(of: intro, matching: find.byType(ColoredBox)).first,
    );
    expect(zemin.color, AppTokens.dark.background);
    expect(lotus(tester).color, AppPalette.rose200);
  });

  test('işaretin genişliği açılış görseliyle aynı', () {
    final src = File('tool/generate_launch_image.py').readAsStringSync();
    final m = RegExp(r'^WIDTH_PT = (\d+)', multiLine: true).firstMatch(src);
    expect(m, isNotNull);
    expect(LaunchMark.launchWidth, double.parse(m!.group(1)!));
  });

  testWidgets('giriş bitince lotus beyaz ve dairenin içinde', (tester) async {
    await open(tester, ready: ValueNotifier(false));
    await run(tester, LaunchIntro.duration + const Duration(milliseconds: 50));

    expect(lotus(tester).color, Colors.white);
    // `AppLogoMark`'taki gibi dairenin %60'ı.
    expect(scaleOf(tester, 'launch_mark_lotus'), closeTo(88 * 0.6 / 120, 1e-9));
    expect(scaleOf(tester, 'launch_mark_circle'), closeTo(1, 1e-9));
    expect(find.text('Nilu'), findsOneWidget);
  });

  testWidgets('hazır değilse son karede bekliyor, sonra çark çıkıyor', (
    tester,
  ) async {
    final ready = ValueNotifier(false);
    await open(tester, ready: ready);
    await run(tester, LaunchIntro.duration + const Duration(milliseconds: 100));

    expect(intro, findsOneWidget);
    expect(spinner, findsNothing);

    await run(
      tester,
      LaunchIntro.spinnerDelay + const Duration(milliseconds: 100),
    );
    expect(spinner, findsOneWidget);

    ready.value = true;
    await run(
      tester,
      LaunchIntro.exitDuration + const Duration(milliseconds: 50),
    );
    expect(intro, findsNothing);
  });

  testWidgets('perde dokunuşları tutuyor, kalkınca alttaki durum korunuyor', (
    tester,
  ) async {
    final counter = await open(tester, ready: ValueNotifier(true));
    final state = counter.currentState;

    await tester.tap(find.byType(_Counter), warnIfMissed: false);
    await tester.pump();
    expect(counter.currentState!.taps, 0, reason: 'perde dokunuşu geçirdi');

    await tester.pumpAndSettle();
    expect(intro, findsNothing);
    expect(
      counter.currentState,
      same(state),
      reason: 'perde kalkınca alttaki ekran yeniden kuruldu',
    );

    await tester.tap(find.byType(_Counter));
    await tester.pump();
    expect(counter.currentState!.taps, 1);
  });

  testWidgets('hazırken dokunmak animasyonu kısaltıyor', (tester) async {
    await open(tester, ready: ValueNotifier(true));
    await run(tester, const Duration(milliseconds: 200));

    await tester.tap(intro);
    await run(tester, const Duration(milliseconds: 150 + 350 + 50));

    // Toplam ~750 ms: giriş kendi başına 1250 ms sürerdi, üstüne kalkış.
    expect(intro, findsNothing);
  });

  testWidgets('hazır değilken dokunmak bir şey değiştirmiyor', (tester) async {
    await open(tester, ready: ValueNotifier(false));
    await run(tester, const Duration(milliseconds: 200));

    await tester.tap(intro);
    await run(tester, LaunchIntro.duration + LaunchIntro.exitDuration);

    expect(intro, findsOneWidget);
  });

  testWidgets('"Hareketi azalt" açıkken işaret hareket etmiyor, yalnızca '
      'perde soluyor', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await open(tester, ready: ValueNotifier(true));
    await run(tester, LaunchIntro.exitDuration ~/ 2);

    expect(intro, findsOneWidget);
    expect(scaleOf(tester, 'launch_mark_lotus'), 1);
    expect(scaleOf(tester, 'launch_mark_circle'), 0);
    expect(lotus(tester).color, AppPalette.plum700);

    await run(tester, LaunchIntro.exitDuration);
    expect(intro, findsNothing);
  });
}

/// Perdenin altındaki ekran: dokunuşları sayıyor, durumu korunmalı.
class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => taps++),
    child: const SizedBox.expand(),
  );
}
