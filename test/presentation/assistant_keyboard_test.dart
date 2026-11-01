import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/presentation/assistant/assistant_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// "Verine sor"da yazılan soru klavye açıkken görünüyor.
///
/// Soru alanı `Scaffold.bottomNavigationBar`'daydı; `Scaffold` o bölümü
/// klavyeyle yukarı taşımıyor. Klavye açılınca alan altında kalıyor ve
/// TestFlight'ta "yazdıklarımız gözükmüyor" diye bildirildi.
void main() {
  setUpAll(mockMissingPlatformChannels);

  testWidgets('soru alanı klavyenin üstünde', (tester) async {
    resetStores(onboarded: true);
    const size = Size(390, 844);
    await pumpScreen(tester, const AssistantScreen(), size: size);

    // iPhone klavyesi ~336 pt.
    const keyboard = 336.0;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Bu ay kanama neden az sürdü',
    );
    await tester.pump();

    final field = tester.getRect(find.byType(TextField));
    expect(
      field.bottom,
      lessThanOrEqualTo(size.height - keyboard),
      reason: 'soru alanı klavyenin altında kalıyor: $field',
    );
    expect(find.text('Bu ay kanama neden az sürdü'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
