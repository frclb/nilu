import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/account/sign_in_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_birth_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_conception_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_cycle_length_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_goal_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_last_period_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_period_length_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_success_screen.dart';

import '../gallery/gallery_fonts.dart';
import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Tek ekran olması gereken ekranlar her cihazda **kaydırmadan** sığıyor.
///
/// Giriş ekranında "Hesap olmadan devam et" ve şartlar küçük telefonda
/// katlamanın altında kalıyordu: isteğe bağlı olduğu söylenen girişin
/// atlanma yolu görünmüyordu. Ekranlar `AppFitToScreen` ile sığıyor; burada
/// her öğenin ekranın içinde olduğu ve normal yazıda küçültme gerekmediği
/// ölçülüyor.
///
/// `--dart-define=GALLERY=true` ile her durumun görüntüsü `build/fit/`
/// altına yazılıyor.
const _capture = bool.fromEnvironment('GALLERY');

typedef _Device = ({Size size, double top, double bottom});

const Map<String, _Device> _devices = {
  'iphone_se': (size: Size(375, 667), top: 20, bottom: 0),
  'iphone_13_mini': (size: Size(375, 812), top: 50, bottom: 34),
  'iphone_16e': (size: Size(390, 844), top: 47, bottom: 34),
  'iphone_17_pro_max': (size: Size(440, 956), top: 62, bottom: 34),
  'ipad_mini_landscape': (size: Size(1133, 744), top: 24, bottom: 20),
};

/// Ekran, küçültme kutusunun anahtarı ve görünmesi gerekenler.
typedef _Case = ({
  Widget screen,
  Key fitKey,
  List<Finder> Function(BuildContext context) mustSee,
});

final Map<String, _Case> _screens = {
  'giriş': (
    screen: const SignInScreen(),
    fitKey: const Key('sign_in_fit'),
    mustSee: (context) => [
      find.byKey(const Key('sign_in_apple')),
      find.byKey(const Key('sign_in_google')),
      find.byKey(const Key('sign_in_email')),
      find.byKey(const Key('sign_in_skip')),
      find.byKey(const Key('sign_in_notice')),
      find.text(context.tr('terms_of_service_title')),
    ],
  ),
  'kurulum · hedef': (
    screen: const OnboardingGoalScreen(),
    fitKey: _onb,
    mustSee: (context) => [
      find.byKey(const Key('onboarding_goal_cycle')),
      find.byKey(const Key('onboarding_goal_postpartum')),
    ],
  ),
  'kurulum · son regl': (
    screen: const OnboardingLastPeriodScreen(),
    fitKey: _onb,
    mustSee: (context) => [
      find.text(context.tr('onb_last_period_hint')),
      find.text(context.tr('onb_continue')),
    ],
  ),
  'kurulum · regl süresi': (
    screen: const OnboardingPeriodLengthScreen(),
    fitKey: _onb,
    mustSee: (context) => [find.text(context.tr('onb_continue'))],
  ),
  'kurulum · döngü süresi': (
    screen: const OnboardingCycleLengthScreen(),
    fitKey: _onb,
    mustSee: (context) => [find.text(context.tr('onb_finish_setup'))],
  ),
  'kurulum · bebek': (
    screen: const OnboardingConceptionScreen(),
    fitKey: _onb,
    mustSee: (context) => const [],
  ),
  'kurulum · doğum': (
    screen: const OnboardingBirthScreen(),
    fitKey: _onb,
    mustSee: (context) => [
      find.byKey(const Key('onboarding_birth_continue')),
      find.text(context.tr('onb_birth_older')),
    ],
  ),
  'kurulum · hazır': (
    screen: const OnboardingSuccessScreen(),
    fitKey: _onb,
    mustSee: (context) => [find.text(context.tr('onboarding_success_cta'))],
  ),
};

const _onb = Key('onboarding_fit');

Future<void> _save(WidgetTester tester, String name) async {
  final view = tester.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final bytes = await tester.runAsync(() async {
    // Kök katman fiziksel piksellerde (`devicePixelRatio` 3).
    final image = await layer.toImage(
      Offset.zero & (view.size * 3),
      pixelRatio: 2 / 3,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File('build/fit/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  setUpAll(() async {
    mockMissingPlatformChannels();
    if (_capture) await loadMaterialIcons();
  });

  for (final MapEntry(key: screenName, value: c) in _screens.entries) {
    for (final MapEntry(key: name, value: device) in _devices.entries) {
      for (final locale in const [Locale('tr'), Locale('de')]) {
        testWidgets('$screenName · $name · ${locale.languageCode}', (
          tester,
        ) async {
          resetStores(onboarded: false);
          tester.view.padding = FakeViewPadding(
            top: device.top * 3,
            bottom: device.bottom * 3,
          );
          tester.view.viewPadding = tester.view.padding;
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);

          await pumpScreen(tester, c.screen, size: device.size, locale: locale);
          expect(tester.takeException(), isNull, reason: 'taşma');
          if (_capture) {
            await _save(tester, '${screenName}_${name}_${locale.languageCode}');
          }

          // Sayfa kaydırılmıyor. Çark ve takvim kendi içinde kayan
          // denetimler; sayıma girmiyorlar.
          for (final type in [SingleChildScrollView, ListView]) {
            expect(
              find.descendant(
                of: find.byWidget(c.screen),
                matching: find.byType(type),
              ),
              findsNothing,
              reason: 'ekran kaydırılmamalı',
            );
          }

          final context = tester.element(find.byWidget(c.screen));
          final screen = Offset.zero & device.size;
          for (final finder in c.mustSee(context)) {
            expect(finder, findsOneWidget);
            final rect = tester.getRect(finder);
            expect(
              screen.contains(rect.topLeft) &&
                  screen.contains(rect.bottomRight - const Offset(1, 1)),
              isTrue,
              reason: '$finder ekranın dışında: $rect',
            );
          }

          // Giriş ekranı Türkçede her cihazda doğal boyunda; Almanca en uzun
          // dil (yasal notu beş satır), küçük telefonda biraz küçülmesine
          // izin var. Kurulum adımlarında takvim ve çark var: 16e ve üstünde
          // doğal boyda, en küçük telefonlarda orantılı küçülüyor — kaydırma
          // yerine.
          final box =
              tester.renderObject(find.byKey(c.fitKey)) as RenderFittedBox;
          final scale = box.size.height / box.child!.size.height;
          final tr = locale.languageCode == 'tr';
          final small = device.size.height < 830;
          final floor = c.fitKey == _onb
              ? (tr ? (name == 'iphone_se' ? 0.78 : (small ? 0.9 : 0.96)) : 0.7)
              : (tr ? 0.999 : 0.85);
          expect(scale, greaterThanOrEqualTo(floor), reason: 'küçültüldü');
        });
      }
    }
  }
}
