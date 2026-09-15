import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_welcome_screen.dart';

/// Tanıtım sayfasının her ekranda okunabilir kalması.
///
/// Sayfa dikeyde zaten sıkışık: simge, kahraman çizim, başlık ve açıklama
/// alt alta ve aralarında kaydırma yok sayılır. Kahraman çizimin yüksekliğini
/// 40 pt artırmak telefonda **açıklama metnini ekranın dışına itiyordu** —
/// slaytın asıl mesajı görünmez oluyordu, üstelik hiçbir taşma uyarısı
/// çıkmadan (içerik kaydırılabilir olduğu için sessizce kesiliyor).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/en.json').readAsStringSync())
          as Map<String, dynamic>;

  /// Cihazı **güvenli alan boşluklarıyla birlikte** kurar.
  ///
  /// Boşluklar olmadan test gerçekte olmayan bir ferahlık veriyor: durum
  /// çubuğu ve ana ekran göstergesi telefonda ~93 pt yiyor ve tanıtım sayfası
  /// tam orada sıkışıyor. Bu satırlar olmadan test, açıklamayı ekran dışına
  /// iten bir değişikliği fark etmiyordu — denenerek görüldü.
  Future<void> open(
    WidgetTester tester,
    Size pixels,
    double ratio, {
    required double topInset,
    required double bottomInset,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = pixels;
    tester.view.devicePixelRatio = ratio;
    tester.view.padding = FakeViewPadding(
      top: topInset * ratio,
      bottom: bottomInset * ratio,
    );
    tester.view.viewPadding = FakeViewPadding(
      top: topInset * ratio,
      bottom: bottomInset * ratio,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          // Uygulamanın kendi teması şart: yazı tipi ve metin ölçüleri
          // buradan geliyor ve sayfanın yüksekliğini onlar belirliyor.
          // Varsayılan temayla ölçülen bir düzen gerçeği temsil etmiyor.
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: const OnboardingWelcomeScreen(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  /// İlk slaytın açıklaması.
  Finder description(Map<String, dynamic> d) =>
      find.text(d['onboarding_welcome_desc'] as String);

  // (fiziksel boyut, ölçek, üst inset, alt inset) — insetler pt.
  const devices = <String, (Size, double, double, double)>{
    'iPhone 16e': (Size(1170, 2532), 3, 47, 34),
    'iPhone 17': (Size(1179, 2556), 3, 59, 34),
    'iPhone Duo (kapalı)': (Size(1398, 2034), 3, 59, 34), // en kısa telefon
    'iPad mini': (Size(1488, 2266), 2, 24, 20),
    'iPad Pro 13"': (Size(2064, 2752), 2, 24, 20),
    'iPad Pro 13" yatay': (Size(2752, 2064), 2, 24, 20),
  };

  group('açıklama metni ekranda kalır', () {
    devices.forEach((name, spec) {
      testWidgets(name, (tester) async {
        final (pixels, ratio, top, bottom) = spec;
        await open(tester, pixels, ratio, topInset: top, bottomInset: bottom);

        final finder = description(dictionary);
        expect(finder, findsOneWidget, reason: '$name: açıklama çizilmemiş');

        // Sınır ekranın kendisi değil **sayfanın görünür alanı**: slayt
        // `PageView` içinde ve içeriği kayabiliyor. Metin ekran
        // koordinatlarının içinde kalıp yine de kırpılabiliyor — gerçek
        // cihazda tam bu oldu, ekran sınırına bakan bir iddia fark etmedi.
        final viewport = tester.getRect(find.byType(PageView));
        final rect = tester.getRect(finder);

        expect(
          rect.bottom,
          lessThanOrEqualTo(viewport.bottom),
          reason: '$name: açıklama sayfanın altından kırpılıyor',
        );
        expect(
          rect.top,
          greaterThanOrEqualTo(viewport.top),
          reason: '$name: açıklama sayfanın üstünden kırpılıyor',
        );
      });
    });
  });

  group('kahraman çizim geniş ekranda büyür', () {
    /// Kahraman alanının yüksekliği.
    double heroHeight(WidgetTester tester) =>
        tester.getRect(find.byType(FittedBox).first).height;

    testWidgets('iPad 13" portrede telefondan belirgin büyük', (tester) async {
      await open(
        tester,
        const Size(1179, 2556),
        3,
        topInset: 59,
        bottomInset: 34,
      );
      final onPhone = heroHeight(tester);

      await open(
        tester,
        const Size(2064, 2752),
        2,
        topInset: 24,
        bottomInset: 20,
      );
      final onTablet = heroHeight(tester);

      expect(
        onTablet,
        greaterThan(onPhone * 1.5),
        reason:
            'çizim geniş ekranda doğal boyutunda kalırsa sayfa boş görünüyor',
      );
    });
  });
}
