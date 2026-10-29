import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/platform/app_platform.dart';
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

/// Aylık planda başlangıç teklifi (ör. ücretsiz deneme) var.
class _IntroVM extends _FakeVM {
  @override
  List<SubscriptionPlan> get plans => const [
    SubscriptionPlan(
      id: 'monthly',
      period: PlanPeriod.monthly,
      priceString: '₺149,99',
      price: 149.99,
      introOffer: '₺0,00',
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
    SubscriptionViewModel? vm,
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
            value: vm ?? _FakeVM(),
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

  group('yenileme ve iptal düğmenin hemen üstünde', () {
    // Uyum denetimi (6502, Mesafeli Sözleşmeler Yönetmeliği): fiyat,
    // yenileme sıklığı, kimden çekileceği ve iptal yolu satın alma
    // düğmesine basmadan görülmeli. Önceden yalnızca listenin dibindeki
    // küçük notta duruyordu; düğme ise ekranın altına sabit.
    String ozet(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const Key('premium_renewal_summary')))
        .data!;

    testWidgets('seçili plana göre ve kaydırmadan görünüyor', (tester) async {
      await open(tester, brightness: Brightness.light);

      final metin = find.byKey(const Key('premium_renewal_summary'));
      final dugme = find.text(s('premium_subscribe_button'));
      expect(
        tester.getBottomLeft(metin).dy,
        lessThan(tester.getTopLeft(dugme).dy),
      );
      expect(
        tester.getBottomLeft(metin).dy,
        lessThan(tester.view.physicalSize.height / 3),
        reason: 'kaydırmadan ekranda',
      );

      // Varsayılan seçim yıllık plan.
      expect(
        ozet(tester),
        s('premium_renewal_summary')
            .replaceAll('{price}', '₺899,99')
            .replaceAll('{every}', s('premium_every_annual')),
      );
      expect(ozet(tester), contains('Abonelikler'));

      await tester.tap(find.text(s('premium_period_monthly')));
      await tester.pump();
      expect(ozet(tester), contains('₺149,99'));
      expect(ozet(tester), contains(s('premium_every_monthly')));
    });

    testWidgets('başlangıç teklifinde sonra ne çekileceği yazıyor', (
      tester,
    ) async {
      await open(tester, brightness: Brightness.light, vm: _IntroVM());
      expect(
        ozet(tester),
        s('premium_renewal_summary_intro')
            .replaceAll('{intro}', '₺0,00')
            .replaceAll('{price}', '₺149,99')
            .replaceAll('{every}', s('premium_every_monthly')),
      );
    });

    testWidgets('Android: Google Play hesabı ve Google Play\'den iptal', (
      tester,
    ) async {
      AppPlatform.debugAndroid = true;
      addTearDown(() => AppPlatform.debugAndroid = null);
      await open(tester, brightness: Brightness.light);
      expect(ozet(tester), contains('Google Play'));
      expect(ozet(tester), isNot(contains('Apple')));
    });

    test('cayma ve iade yolu ödeme notunda ve şartlarda', () {
      for (final key in [
        'premium_disclaimer',
        'premium_disclaimer_android',
        'terms_section5_content',
        'terms_section5_content_ios',
      ]) {
        expect(s(key), contains('cayma'), reason: key);
        expect(s(key), contains(RegExp('[İi]ade')), reason: key);
      }
    });
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

  testWidgets('Android: ödeme Google Play hesabından', (tester) async {
    // Google Play de otomatik yenileme bildirimini istiyor; "Apple kimliği"
    // yazan bir not Android'de yanlış olurdu.
    AppPlatform.debugAndroid = true;
    addTearDown(() => AppPlatform.debugAndroid = null);
    await open(tester, brightness: Brightness.light);

    expect(find.text(s('premium_disclaimer_android')), findsOneWidget);
    expect(find.text(s('premium_disclaimer')), findsNothing);
  });

  testWidgets('karanlık temada da eksiksiz', (tester) async {
    await open(tester, brightness: Brightness.dark);

    expect(find.text(s('premium_disclaimer')), findsOneWidget);
    expect(find.text(s('premium_restore_purchases')), findsOneWidget);
    expect(find.byType(BrandLotus), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
