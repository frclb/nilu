import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/profile_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';

import '../presentation/all_screens.dart';
import '../presentation/pregnancy_fixtures.dart';
import '../presentation/screen_harness.dart';

/// Ekran galerisi: her ekranı PNG olarak çizer — gözle inceleme için.
///
/// Normal test paketinde **atlanıyor**; yalnızca istenince koşuyor:
///
///     flutter test test/gallery --dart-define=GALLERY=true
///
/// Çıktı `build/gallery/{light,dark,tall}/<ekran>.png`. Tasarım
/// yenilemesinde 51 ekranı simülatörde tek tek açmak yerine hepsini bir
/// seferde tasarım görselleriyle yan yana koymak için yazıldı. Bir şey
/// iddia etmiyor; düzen hataları zaten `every_screen_test`'te yakalanıyor.
///
/// Yazı tipleri gerçek (bkz. `flutter_test_config.dart`); Material
/// simgeleri Flutter SDK'nın kendi yazı tipinden yükleniyor.
const _enabled = bool.fromEnvironment('GALLERY');

final _boundary = GlobalKey();

DateTime _ago(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
}

/// Gerçekçi bir kullanıcı: 6 döngü (27–30 gün), son regl 20 gün önce,
/// son günlerde belirtiler.
Future<void> _seedCycleUser() async {
  await CycleSettingsRepository().saveCycleSettings(
    cycleLength: 29,
    periodLength: 5,
  );
  await const ProfileRepository().save(name: 'Ayşe');
  final starts = [20, 49, 77, 106, 133, 163];
  await const PeriodRepository().savePeriodLogs([
    for (final (i, s) in starts.indexed)
      PeriodLog(id: 'p$i', startDate: _ago(s), endDate: _ago(s - 4)),
  ]);
  await const PeriodRepository().saveDailyLogs([
    DailyLog(
      date: _ago(3),
      symptoms: const ['cramps', 'headache'],
      moods: const ['happy'],
      notes: 'Akşam yürüyüşü iyi geldi.',
    ),
    DailyLog(
      date: _ago(19),
      symptoms: const ['cramps', 'fatigue'],
      moods: const ['calm'],
      flowIntensity: 'medium',
    ),
    DailyLog(
      date: _ago(20),
      symptoms: const ['cramps', 'bloating', 'backache'],
      flowIntensity: 'heavy',
    ),
    DailyLog(
      date: _ago(48),
      symptoms: const ['cramps', 'fatigue'],
      flowIntensity: 'medium',
    ),
  ]);
}

const _pregnancyScreens = {
  'pregnancy_home',
  'care_list',
  'care_summary',
  'pregnancy_months',
  'end_pregnancy',
  'danger_signs',
};

Future<void> _seedFor(String screen) async {
  resetStores(onboarded: true);
  await _seedCycleUser();
  if (_pregnancyScreens.contains(screen)) {
    await seedPregnancy(weeks: 24, days: 3);
  } else if (screen == 'postpartum_home') {
    await seedPostpartum(daysSinceBirth: 12);
  } else if (screen == 'past_pregnancies') {
    await seedPostpartum(daysSinceBirth: 120);
  }
}

Future<void> _loadMaterialIcons() async {
  // flutter_tester: <flutter>/bin/cache/artifacts/engine/<platform>/…
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  final candidates = [
    '${artifacts.path}/material_fonts/MaterialIcons-Regular.otf',
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final loader = FontLoader('MaterialIcons')
      ..addFont(file.readAsBytes().then(ByteData.sublistView));
    await loader.load();
    return;
  }
  // ignore: avoid_print
  print('Uyarı: MaterialIcons bulunamadı; simgeler kutu olarak çizilecek.');
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  required bool dark,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  const locale = Locale('tr');
  await tester.runAsync(() async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark
              ? AppTheme.dark(AppFlavor.plum)
              : AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: locale,
          supportedLocales: const [locale],
          home: wrapWithProviders(screen),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _capture(WidgetTester tester, String path) async {
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    mockMissingPlatformChannels();
    if (_enabled) await _loadMaterialIcons();
  });

  const variants = {
    'light': (Size(390, 844), false),
    'tall': (Size(390, 2000), false),
    'dark': (Size(390, 844), true),
  };

  final screens = allScreens();
  for (final entry in screens.entries) {
    for (final variant in variants.entries) {
      testWidgets('galeri · ${entry.key} · ${variant.key}', skip: !_enabled, (
        tester,
      ) async {
        await _seedFor(entry.key);
        final (size, dark) = variant.value;
        await _pump(tester, entry.value, size: size, dark: dark);
        await _capture(tester, 'build/gallery/${variant.key}/${entry.key}.png');
        // Taşma gibi düzen hataları galeriyi durdurmasın; zaten
        // `every_screen_test` onları yakalıyor.
        tester.takeException();
      });
    }
  }
}
