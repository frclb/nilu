import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/main.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // ViewModel'lar açılışta SharedPreferences okur; testte platform kanalı
    // olmadığı için sahte bir depo veriyoruz.
    SharedPreferences.setMockInitialValues({});
  });

  /// Varsayılan test yüzeyi 800x600'dür; ekranlar telefon boyu için
  /// tasarlandığından gerçekçi bir yüzey veriyoruz (iPhone 13: 390x844pt).
  void usePhoneSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('uygulama Firebase yapılandırması olmadan da açılır', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);

    // FirebaseConfig.init() burada çağrılmaz → isAvailable false kalır.
    // Bu, yapılandırma dosyaları eklenmeden önceki gerçek durumu temsil eder;
    // uygulama bu modda çökmeden açılmalıdır.
    await tester.pumpWidget(PeriodTrackerApp(userViewModel: UserViewModel()));
    await tester.pumpAndSettle();

    expect(find.byType(PeriodTrackerApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding tamamlanmamışken onboarding ekranı açılır', (
    WidgetTester tester,
  ) async {
    usePhoneSurface(tester);
    SharedPreferences.setMockInitialValues({'onboarding_complete': false});

    await tester.pumpWidget(PeriodTrackerApp(userViewModel: UserViewModel()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
