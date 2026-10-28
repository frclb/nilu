import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/onboarding_welcome/widgets/onboarding_day_wheel.dart';

/// Hapın içindeki gün görünüyor mu?
///
/// TestFlight bulgusu (iPhone, iOS 27): kurulumun döngü süresi adımında
/// ortada 28 dururken hap koyu, rakam soluk ve küçük çizildi — "gün
/// gözükmüyor". Çark seçili satırı ekranın tuttuğu `selected` değerinden
/// okuyordu; o değer çarkın gerçek konumundan ayrışınca ortadaki gün
/// "seçili değil" sayılıyordu. Artık çarkın kendi konumu esas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FixedExtentScrollController> open(
    WidgetTester tester, {
    required int initialDays,
    required int selected,
  }) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final controller = FixedExtentScrollController(
      initialItem: initialDays - 21,
    );
    addTearDown(controller.dispose);

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
          home: Scaffold(
            body: Center(
              child: OnboardingDayWheel(
                controller: controller,
                min: 21,
                max: 45,
                // Bilerek ayrışık: ekranın değeri çarkın konumunu
                // izlemiyor.
                selected: selected,
                onSelected: (_) {},
                label: 'Döngü süresi',
                icon: Icons.autorenew,
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
    return controller;
  }

  TextStyle styleOf(WidgetTester tester, int days) =>
      DefaultTextStyle.of(tester.element(find.text('$days Gün'))).style;

  bool shownAsSelected(WidgetTester tester, int days) {
    final style = styleOf(tester, days);
    final onPrimary = Theme.of(
      tester.element(find.text('$days Gün')),
    ).colorScheme.onPrimary;
    return style.color == onPrimary && style.fontSize == 26;
  }

  testWidgets('ortadaki gün hapın içinde, ekranın değeri ayrışsa da', (
    tester,
  ) async {
    await open(tester, initialDays: 28, selected: 30);

    expect(
      shownAsSelected(tester, 28),
      isTrue,
      reason: 'Ortada 28 var; hapın içinde beyaz ve büyük çizilmeli',
    );
    expect(shownAsSelected(tester, 30), isFalse);
  });

  testWidgets('kaydırınca hapın içindeki gün de değişiyor', (tester) async {
    final controller = await open(tester, initialDays: 28, selected: 28);

    await tester.drag(
      find.byType(ListWheelScrollView),
      const Offset(0, -OnboardingDayWheel.itemExtent),
    );
    await tester.pumpAndSettle();

    final center = controller.selectedItem + 21;
    expect(center, 29);
    expect(shownAsSelected(tester, 29), isTrue);
    expect(shownAsSelected(tester, 28), isFalse);
  });
}
