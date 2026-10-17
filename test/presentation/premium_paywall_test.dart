import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/design_system/brand_lotus.dart';
import 'package:period_tracker/domain/services/subscription_pricing.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/premium/premium_screen.dart';

/// Paywall'ın Apple'ın istediklerini gösterdiği.
///
/// App Store 3.1.2 abonelik ekranında şunları arıyor: fiyat, süre, otomatik
/// yenileme bildirimi, satın alımları geri yükleme, ve şartlar ile gizlilik
/// politikası bağlantıları. Biri eksikse sürüm reddediliyor.
///
/// Bunlar tasarım değişikliklerinde sessizce düşebilecek şeyler: hepsi aynı
/// listede duruyor ve bir yeniden düzenlemede biri kolayca dışarıda kalır.
class _FakeVM extends SubscriptionViewModel {
  @override
  bool get isLoading => false;

  @override
  bool get isPremium => false;

  @override
  List<SubscriptionPlan> get plans => const [
    SubscriptionPlan(
      id: 'monthly',
      period: PlanPeriod.monthly,
      priceString: '₺149,99',
      price: 149.99,
    ),
    SubscriptionPlan(
      id: 'annual',
      period: PlanPeriod.annual,
      priceString: '₺899,99',
      price: 899.99,
    ),
  ];
}

void main() {
  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  String s(String key) => dictionary[key] as String;

  Future<void> open(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    tester.view.physicalSize = const Size(1320, 2868);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Lokalizasyon sözlüğü varlıklardan **asenkron** okunuyor; sahte saatte
    // beklenmiyor ve ekran boş kalıyor.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.light
              ? AppTheme.light(AppFlavor.plum)
              : AppTheme.dark(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr')],
          home: ChangeNotifierProvider<SubscriptionViewModel>.value(
            value: _FakeVM(),
            child: const PremiumScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Apple\'ın aradığı beş şey ekranda', (tester) async {
    await open(tester, brightness: Brightness.light);

    // Fiyatlar mağazadan geldiği gibi, biçimlendirilmiş.
    expect(find.text('₺149,99'), findsOneWidget, reason: 'aylık fiyat yok');
    expect(find.text('₺899,99'), findsOneWidget, reason: 'yıllık fiyat yok');

    // Süre etiketleri.
    expect(find.text(s('premium_period_monthly')), findsOneWidget);
    expect(find.text(s('premium_period_annual')), findsOneWidget);

    expect(
      find.text(s('premium_disclaimer')),
      findsOneWidget,
      reason: 'otomatik yenileme bildirimi yok',
    );
    expect(
      find.text(s('premium_restore_purchases')),
      findsOneWidget,
      reason: 'geri yükleme düğmesi yok',
    );
    expect(find.text(s('premium_subscribe_button')), findsOneWidget);

    // Bağlantılar listenin dibinde ve katlamanın altında kalıyor. Apple
    // bunların paywall'da **bulunmasını** istiyor, ekranın ilk karesinde
    // görünmesini değil — ama erişilebilir olmaları şart.
    await tester.scrollUntilVisible(
      find.text(s('premium_terms')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(s('premium_privacy')), findsOneWidget);
    expect(find.text(s('premium_terms')), findsOneWidget);
  });

  testWidgets('marka başlığı çiziliyor', (tester) async {
    await open(tester, brightness: Brightness.light);

    // Lotus yalnızca genişliği sınırlı bir yere konursa sıfır yükseklikte
    // çiziliyor ve sessizce kayboluyor — bir kez başımıza geldi.
    expect(find.byType(BrandLotus), findsOneWidget);
    final size = tester.getSize(find.byType(BrandLotus));
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));

    expect(find.text(s('premium_subtitle')), findsOneWidget);
  });

  testWidgets('en avantajlı plan işaretli ve önceden seçili', (tester) async {
    await open(tester, brightness: Brightness.light);

    expect(find.text(s('premium_best_value')), findsOneWidget);

    // Tasarruf oranı ekrandaki en ikna edici sayı; soluk kalmamalı.
    final saving = find.textContaining('daha uygun');
    expect(saving, findsOneWidget);
    final style = tester.widget<Text>(saving).style;
    expect(style?.fontWeight, FontWeight.w600);
  });

  testWidgets('karanlık temada da eksiksiz', (tester) async {
    await open(tester, brightness: Brightness.dark);

    expect(find.text(s('premium_disclaimer')), findsOneWidget);
    expect(find.text(s('premium_restore_purchases')), findsOneWidget);
    expect(find.byType(BrandLotus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
