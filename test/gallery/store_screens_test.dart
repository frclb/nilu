import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/core/platform/app_platform.dart';
import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/profile_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_layout.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/assistant/assistant_screen.dart';
import 'package:period_tracker/presentation/log_entry/widgets/symptoms_section.dart';
import 'package:period_tracker/presentation/insights/widgets/cycle_trend_card.dart';
import 'package:period_tracker/presentation/home/widgets/home_hero_card.dart';
import 'package:period_tracker/presentation/health_library/widgets/health_library_featured_article.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/health_library/health_library_screen.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/home/widgets/custom_bottom_nav.dart';
import 'package:period_tracker/presentation/home/widgets/side_nav_rail.dart';
import 'package:period_tracker/presentation/insights/insights_screen.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_home_screen.dart';
import 'package:period_tracker/presentation/profile/privacy_security_screen.dart';

import '../presentation/pregnancy_fixtures.dart';
import '../presentation/screen_harness.dart';
import 'gallery_fonts.dart';

/// Mağaza ekran görüntüleri için ham ekranlar: altı dil, dört cihaz.
///
/// Normal test paketinde **atlanıyor**; yalnızca istenince koşuyor:
///
///     flutter test test/gallery/store_screens_test.dart --dart-define=STORE=true
///
/// Çıktı `build/store_raw/<cihaz>/<dil>/<ekran>.png`, cihazın gerçek piksel
/// boyutunda. Çerçeve, başlık ve durum çubuğu `tool/store_screenshots.py`
/// ile ekleniyor.
///
/// Simülatörde altı dili ve iki cihazı tek tek gezmek yüzlerce dokunuş
/// demekti ve tasarım her değiştiğinde baştan yapılmalıydı. Burada ekranlar
/// uygulamanın kendi widget'larıyla, aynı demo veriyle çiziliyor; tasarım
/// değişince komut yeniden koşuluyor.
const _enabled = bool.fromEnvironment('STORE');

final _boundary = GlobalKey();

/// Mantıksal boyut, piksel oranı ve güvenli alan.
///
/// Güvenli alan durum çubuğunun ve ana ekran çizgisinin kapladığı yer:
/// ekranlar onu gerçek cihazdaki gibi boş bırakıyor, durum çubuğunu betik
/// sonradan çiziyor.
typedef _Device = ({
  Size size,
  double ratio,
  EdgeInsets padding,
  TargetPlatform platform,
});

const Map<String, _Device> _devices = {
  // iPhone 17 Pro Max — 1320×2868, App Store'un 6,9" boyutu.
  'iphone': (
    size: Size(440, 956),
    ratio: 3,
    padding: EdgeInsets.only(top: 62, bottom: 34),
    platform: TargetPlatform.iOS,
  ),
  // iPad Pro 13" — 2064×2752.
  'ipad': (
    size: Size(1032, 1376),
    ratio: 2,
    padding: EdgeInsets.only(top: 24, bottom: 20),
    platform: TargetPlatform.iOS,
  ),
  // Android telefon, Pixel sınıfı.
  'android': (
    size: Size(412, 915),
    ratio: 3,
    padding: EdgeInsets.only(top: 40, bottom: 24),
    platform: TargetPlatform.android,
  ),
  // 10" Android tablet.
  'android_tablet': (
    size: Size(800, 1280),
    ratio: 2,
    padding: EdgeInsets.only(top: 28, bottom: 24),
    platform: TargetPlatform.android,
  ),
};

/// Demo kullanıcının adı; her dilde o dilin okuruna tanıdık gelen bir ad.
const _names = {
  'tr': 'Ayşe',
  'en': 'Emma',
  'de': 'Lena',
  'es': 'Lucía',
  'fr': 'Camille',
  'pt': 'Ana',
};

/// Türkçe dışındaki dillerde kullanıcının kendi eklediği randevular.
const _appointments = {
  'en': ('Prenatal checkup', 'Glucose tolerance test'),
  'de': ('Vorsorgeuntersuchung', 'Zuckerbelastungstest'),
  'es': ('Control prenatal', 'Prueba de glucosa'),
  'fr': ('Consultation prénatale', 'Test de glycémie'),
  'pt': ('Consulta de pré-natal', 'Teste de glicose'),
};

typedef _Shot = ({
  Widget screen,

  /// Alt menüde (ya da yan menüde) seçili sekme; menüsüz ekranlarda `null`.
  int? tab,
  bool pregnant,
});

const Map<String, _Shot> _shots = {
  'home': (screen: HomeScreen(), tab: 0, pregnant: false),
  'calendar': (screen: CalendarScreen(), tab: 1, pregnant: false),
  'log_entry': (screen: LogEntryScreen(), tab: null, pregnant: false),
  'insights': (screen: InsightsScreen(), tab: 2, pregnant: false),
  'pregnancy_home': (screen: PregnancyHomeScreen(), tab: 0, pregnant: true),
  'privacy_security': (
    screen: PrivacySecurityScreen(),
    tab: null,
    pregnant: false,
  ),
  'assistant': (screen: AssistantScreen(), tab: null, pregnant: false),
  'health_library': (screen: HealthLibraryScreen(), tab: 3, pregnant: false),
};

/// Görselde ekrandan dışarı büyütülecek öğe.
///
/// Konumu testte ölçülüyor ve ham ekranın yanına yazılıyor: dil değişip
/// metin kaydığında da betik doğru yeri kesiyor.
final Map<String, Finder Function()> _callouts = {
  'home': () => find.byType(HomeHeroCard),
  'calendar': () => find.byType(CalendarGrid),
  'log_entry': () => find.byType(SymptomsSection),
  'insights': () => find.byType(CycleTrendCard),
  'pregnancy_home': () => find.byType(HomeHeroCard),
  'privacy_security': () => find.byType(SwitchListTile),
  'assistant': () =>
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_TurnView'),
  'health_library': () => find.byType(HealthLibraryFeaturedArticle),
};

/// Öğenin ekrandaki dikdörtgeni (mantıksal piksel); ekranda yoksa `null`.
List<double>? _rectOf(WidgetTester tester, String shot) {
  final finder = _callouts[shot]?.call();
  if (finder == null || finder.evaluate().isEmpty) return null;
  final r = tester.getRect(finder.first);
  return [r.left, r.top, r.right, r.bottom];
}

DateTime _ago(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
}

/// Galeriyle aynı kullanıcı: 6 döngü (27–30 gün), son regl 20 gün önce.
/// Bugünün kaydı dolu, kayıt ekranı seçili hâliyle görünsün diye.
Future<void> _seed(String lang, {required bool pregnant}) async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({
    'onboarding_complete': true,
    // Gizlilik ekranında kilit açık görünsün; cihazda Face ID var (bkz.
    // `_mockBiometrics`).
    'app_lock_enabled': true,
  });
  await CycleSettingsRepository().saveCycleSettings(
    cycleLength: 29,
    periodLength: 5,
  );
  await const ProfileRepository().save(name: _names[lang]);
  final starts = [20, 49, 77, 106, 133, 163];
  await const PeriodRepository().savePeriodLogs([
    for (final (i, s) in starts.indexed)
      PeriodLog(id: 'p$i', startDate: _ago(s), endDate: _ago(s - 4)),
  ]);
  await const PeriodRepository().saveDailyLogs([
    DailyLog(
      date: _ago(0),
      symptoms: const ['bloating', 'fatigue'],
      moods: const ['calm'],
    ),
    DailyLog(
      date: _ago(3),
      symptoms: const ['cramps', 'headache'],
      moods: const ['happy'],
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
  if (pregnant) {
    // Türkiye izlem takvimi yalnızca Türkçede; diğer dillerde kullanıcı
    // randevularını kendisi ekliyor — burada da iki randevu eklenmiş.
    final tr = lang == 'tr';
    final g = await seedPregnancy(
      weeks: 24,
      days: 3,
      template: tr ? 'tr' : null,
    );
    if (!tr) {
      final (visit, screening) = _appointments[lang]!;
      await const CareRepository().addMissing([
        CareEvent(
          id: 'c1',
          pregnancyId: g.id,
          title: visit,
          category: CareCategory.visit,
          anchor: CareAnchor.gestation,
          fromDay: 171,
          toDay: 177,
          scheduledAt: _ago(-4).add(const Duration(hours: 10)),
        ),
        CareEvent(
          id: 'c2',
          pregnancyId: g.id,
          title: screening,
          category: CareCategory.screening,
          anchor: CareAnchor.gestation,
          fromDay: 168,
          toDay: 196,
        ),
      ]);
    }
  }
}

void _mockBiometrics(TargetPlatform platform) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/local_auth'),
        (call) async => switch (call.method) {
          'getAvailableBiometrics' => <String>[
            platform == TargetPlatform.iOS ? 'face' : 'fingerprint',
          ],
          _ => true,
        },
      );
}

/// Uygulamanın kabuğu: dar ekranda alt menü, genişte yan menü.
/// `TabNavigationShell` ile aynı karar; yönlendirici olmadan.
Widget _shell(Widget screen, int? tab) {
  if (tab == null) return screen;
  return Builder(
    builder: (context) {
      if (context.layoutClass != LayoutClass.expanded) {
        return Scaffold(
          body: screen,
          bottomNavigationBar: CustomBottomNav(selectedIndex: tab),
        );
      }
      return Scaffold(
        body: Row(
          children: [
            SafeArea(right: false, child: SideNavRail(selectedIndex: tab)),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: screen),
          ],
        ),
      );
    },
  );
}

/// Ekranı veri yüklendikten sonra kurar.
///
/// Uygulamada kayıt ekranına ve "Verine sor"a ana sayfadan geçiliyor; veri
/// o sırada çoktan yüklenmiş oluyor. Burada ekran doğrudan açıldığı için
/// beklenmezse kayıt ekranı bugünün kaydını, "Verine sor" döngüleri
/// görmüyordu.
class _AfterLoad extends StatelessWidget {
  const _AfterLoad({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarViewModel>();
    final pregnancy = context.watch<PregnancyViewModel>();
    if (calendar.isLoading || !pregnancy.loaded) return const SizedBox.shrink();
    return child;
  }
}

/// Emojiler için yedek yazı tipi.
///
/// Cihazda sistem kendiliğinden emoji yazı tipine düşüyor; testte böyle bir
/// yedek yok, emoji yazı tipinin adı verilmeli.
ThemeData _withEmoji(ThemeData theme) {
  const fallback = ['Apple Color Emoji'];
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: fallback),
    primaryTextTheme: theme.primaryTextTheme.apply(
      fontFamilyFallback: fallback,
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Shot shot, {
  required _Device device,
  required String lang,
}) async {
  tester.view.physicalSize = device.size * device.ratio;
  tester.view.devicePixelRatio = device.ratio;
  final p = device.padding * device.ratio;
  final padding = FakeViewPadding(top: p.top, bottom: p.bottom);
  tester.view.padding = padding;
  tester.view.viewPadding = padding;
  addTearDown(tester.view.reset);

  final locale = Locale(lang);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _withEmoji(AppTheme.light(AppFlavor.plum)),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: locale,
          supportedLocales: [locale],
          home: wrapWithProviders(
            _AfterLoad(child: _shell(shot.screen, shot.tab)),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  // Halkanın açılış dizisi ve bugünün üç nabzı bitsin: görüntü yarım bir
  // canlandırma karesinde kalmasın.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// "Verine sor": boş giriş yerine üç soru ve cevabı görünsün.
///
/// İlki giriş ekranındaki örneğe dokunarak, sonrakiler yazıp göndererek —
/// kullanıcının yapacağı gibi.
Future<void> _askExamples(WidgetTester tester) async {
  final context = tester.element(find.byType(AssistantScreen));
  final examples = context.tr('assistant_examples').split('|');
  await tester.tap(find.text(examples[0]).first);
  await tester.pump(const Duration(milliseconds: 300));
  for (final i in const [3, 5]) {
    await tester.enterText(find.byType(TextField), examples[i]);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 300));
  }
  // Klavye kapalı görünsün.
  FocusManager.instance.primaryFocus?.unfocus();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> _capture(WidgetTester tester, String path, double ratio) async {
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
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
    if (_enabled) {
      await loadMaterialIcons();
      await loadSystemEmoji();
    }
  });

  for (final device in _devices.entries) {
    for (final lang in AppLocalizations.supportedLanguageCodes) {
      for (final shot in _shots.entries) {
        testWidgets(
          'mağaza · ${device.key} · $lang · ${shot.key}',
          skip: !_enabled,
          (tester) async {
            // Galerideki gibi: gölgeler gerçek görünsün; platform cihazın
            // platformu olsun (kaydırma, geçişler, simge seçimi). İkisi de
            // test bitmeden geri alınmalı.
            debugDisableShadows = false;
            debugDefaultTargetPlatformOverride = device.value.platform;
            AppPlatform.debugAndroid =
                device.value.platform == TargetPlatform.android;
            _mockBiometrics(device.value.platform);

            await _seed(lang, pregnant: shot.value.pregnant);
            await _pump(tester, shot.value, device: device.value, lang: lang);
            if (shot.key == 'assistant') await _askExamples(tester);
            final base = 'build/store_raw/${device.key}/$lang/${shot.key}';
            await _capture(tester, '$base.png', device.value.ratio);
            File('$base.json').writeAsStringSync(
              jsonEncode({
                'ratio': device.value.ratio,
                'callout': _rectOf(tester, shot.key),
              }),
            );
            tester.takeException();

            debugDefaultTargetPlatformOverride = null;
            AppPlatform.debugAndroid = null;
            debugDisableShadows = true;
          },
        );
      }
    }
  }
}
