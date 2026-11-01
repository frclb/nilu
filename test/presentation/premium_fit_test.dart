import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/services/subscription_pricing.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/premium/premium_screen.dart';

import '../gallery/gallery_fonts.dart';

/// Satış ekranı her cihazda **kaydırmadan** sığıyor.
///
/// Fiyat, yenileme koşulları, düğme, geri yükleme ve yasal bağlantılar aynı
/// anda görünmeli; ekran kaydırılmıyor. Burada iOS'un desteklediği en küçük
/// telefondan iPad'e kadar, iki temada, en uzun dille ve büyük yazıyla
/// açılıp her öğenin ekranın içinde olduğu ölçülüyor.
///
/// `--dart-define=GALLERY=true` ile her durumun görüntüsü
/// `build/paywall/` altına yazılıyor.
const _capture = bool.fromEnvironment('GALLERY');

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
      priceString: '₺1.299,99',
      price: 1299.99,
    ),
  ];
}

/// Ekran boyu ve güvenli alan (pt).
typedef _Device = ({Size size, double top, double bottom});

const Map<String, _Device> _devices = {
  'iphone_se': (size: Size(375, 667), top: 20, bottom: 0),
  'iphone_13_mini': (size: Size(375, 812), top: 50, bottom: 34),
  'iphone_16e': (size: Size(390, 844), top: 47, bottom: 34),
  'iphone_17': (size: Size(402, 874), top: 62, bottom: 34),
  'iphone_17_pro_max': (size: Size(440, 956), top: 62, bottom: 34),
  'ipad_mini_landscape': (size: Size(1133, 744), top: 24, bottom: 20),
  'ipad_pro_13': (size: Size(1032, 1376), top: 24, bottom: 20),
};

final _boundary = GlobalKey();

void main() {
  setUpAll(() async {
    if (_capture) await loadMaterialIcons();
  });

  Future<void> open(
    WidgetTester tester, {
    required _Device device,
    required Locale locale,
    required Brightness brightness,
    double textScale = 1,
  }) async {
    const dpr = 3.0;
    tester.view.devicePixelRatio = dpr;
    tester.view.physicalSize = device.size * dpr;
    tester.view.padding = FakeViewPadding(
      top: device.top * dpr,
      bottom: device.bottom * dpr,
    );
    tester.view.viewPadding = tester.view.padding;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: brightness == Brightness.light
                ? AppTheme.light(AppFlavor.plum)
                : AppTheme.dark(AppFlavor.plum),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: locale,
            supportedLocales: [locale],
            // Uygulamanın kendi tavanı (`main.dart`).
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.5,
              child: child!,
            ),
            home: ChangeNotifierProvider<SubscriptionViewModel>.value(
              value: _FakeVM(),
              child: const PremiumScreen(),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!_capture) return;
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    File('build/paywall/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  }

  /// İçeriğin ne kadar küçültüldüğü: 1 ise doğal boyunda.
  double scaleOf(WidgetTester tester) {
    final box = tester.renderObject<RenderBox>(
      find.byKey(const Key('premium_fit')),
    );
    final child = (box as RenderFittedBox).child!;
    return box.size.height / child.size.height;
  }

  for (final MapEntry(key: name, value: device) in _devices.entries) {
    for (final locale in const [Locale('tr'), Locale('de')]) {
      for (final brightness in Brightness.values) {
        for (final textScale in const [1.0, 1.5]) {
          final label =
              '$name · ${locale.languageCode} · ${brightness.name} · '
              'yazı ${textScale}x';
          testWidgets(label, (tester) async {
            await open(
              tester,
              device: device,
              locale: locale,
              brightness: brightness,
              textScale: textScale,
            );
            expect(tester.takeException(), isNull, reason: 'taşma');
            await capture(
              tester,
              '${name}_${locale.languageCode}_${brightness.name}_$textScale',
            );

            expect(
              find.descendant(
                of: find.byType(PremiumScreen),
                matching: find.byType(Scrollable),
              ),
              findsNothing,
              reason: 'satış ekranı kaydırılmamalı',
            );

            final screen = Offset.zero & device.size;
            final context = tester.element(find.byType(PremiumScreen));
            String tr(String key) => context.tr(key);
            final mustSee = {
              'aylık fiyat': find.text('₺149,99'),
              'yıllık fiyat': find.text('₺1.299,99'),
              'yenileme koşulları': find.byKey(
                const Key('premium_renewal_summary'),
              ),
              'abone ol': find.text(tr('premium_subscribe_button')),
              'geri yükle': find.text(tr('premium_restore_short')),
              'yasal not': find.text(tr('premium_disclaimer')),
              'gizlilik': find.text(tr('premium_privacy')),
              'şartlar': find.text(tr('premium_terms')),
              'son özellik': find.text(tr('premium_feature_noads_title')),
            };
            for (final MapEntry(key: what, value: finder) in mustSee.entries) {
              expect(finder, findsOneWidget, reason: what);
              final rect = tester.getRect(finder);
              expect(
                screen.contains(rect.topLeft) &&
                    screen.contains(rect.bottomRight - const Offset(1, 1)),
                isTrue,
                reason: '$what ekranın dışında: $rect',
              );
            }

            // Telefonlarda normal yazıyla içerik doğal boyunda; küçültme
            // yalnızca büyük yazı ayarı için bir güvence.
            // Normal yazıda içerik doğal boyunda; küçültme büyük yazı ayarı
            // için bir güvence. Tek istisna en küçük telefonda en uzun dil:
            // Almanca başlık iki, yenileme notu beş satır.
            if (textScale == 1) {
              final floor = name == 'iphone_se' && locale.languageCode == 'de'
                  ? 0.9
                  : 0.999;
              expect(
                scaleOf(tester),
                greaterThanOrEqualTo(floor),
                reason: 'normal yazıda içerik küçültülmemeli',
              );
            }
          });
        }
      }
    }
  }
}
