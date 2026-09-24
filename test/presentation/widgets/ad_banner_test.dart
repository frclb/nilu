import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/data/datasources/ad_consent.dart';
import 'package:period_tracker/data/datasources/ads_datasource.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/presentation/widgets/ad_banner.dart';
import 'package:provider/provider.dart';

/// Rızayı hiç vermeyen kapı.
class _DeniedPort implements ConsentPort {
  int adRequestsAllowed = 0;
  int forms = 0;

  @override
  Future<bool> requestUpdate() async => true;

  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<bool> privacyOptionsRequired() async => true;

  @override
  Future<void> showFormIfRequired() async => forms++;

  @override
  Future<void> showPrivacyOptions() async {}
}

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(AppFlavor.plum),
  home: ChangeNotifierProvider(
    create: (_) => SubscriptionViewModel(),
    child: Scaffold(body: child),
  ),
);

void main() {
  tearDown(() {
    AdConsent.resetForTest();
    AdsDatasource.resetForTest();
  });

  testWidgets('rıza yokken banner yer kaplamaz ve çökmez', (tester) async {
    final port = _DeniedPort();
    AdConsent.resetForTest(port);
    AdsDatasource.resetForTest();

    await tester.pumpWidget(_wrap(const AdBanner()));
    await tester.pumpAndSettle();

    // Boş bir kutu bırakmak ekranda açıklanamayan bir boşluk yaratırdı.
    expect(tester.getSize(find.byType(AdBanner)).height, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reklamın göründüğü yerde rıza formu sorulur', (tester) async {
    final port = _DeniedPort();
    AdConsent.resetForTest(port);
    AdsDatasource.resetForTest();

    await tester.pumpWidget(_wrap(const AdBanner()));
    await tester.pumpAndSettle();

    expect(
      port.forms,
      1,
      reason: 'AEA rızası reklamın çıktığı ekranda sorulmalı',
    );
  });

  testWidgets('ağaçtan çıkan banner geriye iş bırakmaz', (tester) async {
    AdConsent.resetForTest(_DeniedPort());
    AdsDatasource.resetForTest();

    await tester.pumpWidget(_wrap(const AdBanner()));
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
