import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/article.dart';
import 'package:period_tracker/domain/view_models/intimacy_view_model.dart';
import 'package:period_tracker/domain/view_models/partner_view_model.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/domain/view_models/theme_view_model.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/appearance/appearance_screen.dart';
import 'package:period_tracker/presentation/assistant/assistant_screen.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/health_check/heavy_bleeding_screen.dart';
import 'package:period_tracker/presentation/health_library/article_screen.dart';
import 'package:period_tracker/presentation/health_library/health_library_screen.dart';
import 'package:period_tracker/presentation/health_sync/health_sync_screen.dart';
import 'package:period_tracker/presentation/legal/privacy_policy_screen.dart';
import 'package:period_tracker/presentation/legal/terms_of_service_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_support_screen.dart';
import 'package:period_tracker/presentation/premium/premium_screen.dart';
import 'package:period_tracker/presentation/profile/cycle_settings_screen.dart';
import 'package:period_tracker/presentation/profile/notification_settings_screen.dart';
import 'package:period_tracker/presentation/profile/personal_info_screen.dart';
import 'package:period_tracker/presentation/profile/privacy_security_screen.dart';
import 'package:period_tracker/presentation/widgets_preview/widgets_preview_screen.dart';

/// Her ekran çiziliyor mu?
///
/// Yayın öncesi en geniş ağ: cihaz taraması sekme gezinmesiyle ilerlediği
/// için ulaşamadığı ekranlar vardı — makale okuyucusu, premium ekranı,
/// asistan, hukuki metinler, widget önizlemesi. Bir ekranın hiç
/// çizilmemesi, oradaki bir taşmanın ya da eksik sağlayıcının yalnızca
/// kullanıcıda ortaya çıkması demek.
///
/// İddia sade: ekran çiziliyor ve hiçbir boyutta düzen hatası atmıyor.
/// Bu, içeriğin doğruluğunu sınamaz; her ekranın kendi testi ayrıca var.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // `local_auth` ve `home_widget` platform kanalları testte yok; onlara
    // dokunan ekranlar yükleme durumunda takılı kalıyordu.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'),
          (call) async => call.method == 'getAvailableBiometrics'
              ? <String>[]
              : false,
        );
  });

  /// Telefon, katlanabilir ve tablet.
  const sizes = <String, Size>{
    'iPhone 16e': Size(390, 844),
    'iPhone Duo (kapalı)': Size(466, 678),
    'iPad Pro 13"': Size(1032, 1376),
  };

  /// Uygulamadaki sağlayıcı kümesinin aynısı.
  Widget wrap(Widget screen) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserViewModel()),
      ChangeNotifierProvider(create: (_) => CalendarViewModel()),
      ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),
      ChangeNotifierProvider(create: (_) => ThemeViewModel()),
      ChangeNotifierProvider(create: (_) => IntimacyViewModel()),
      ChangeNotifierProvider(create: (_) => PartnerViewModel()),
    ],
    child: screen,
  );

  final screens = <String, Widget>{
    'assistant': const AssistantScreen(),
    'health_library': const HealthLibraryScreen(),
    'article': ArticleScreen(article: ArticleCatalog.all.first),
    'premium': const PremiumScreen(),
    'privacy_policy': const PrivacyPolicyScreen(),
    'terms_of_service': const TermsOfServiceScreen(),
    'privacy_security': const PrivacySecurityScreen(),
    'notification_settings': const NotificationSettingsScreen(),
    'cycle_settings': const CycleSettingsScreen(),
    'personal_info': const PersonalInfoScreen(),
    'appearance': const AppearanceScreen(),
    'health_sync': const HealthSyncScreen(),
    'heavy_bleeding': const HeavyBleedingScreen(),
    'partner_support': const PartnerSupportScreen(),
    'widgets_preview': const WidgetsPreviewScreen(),
  };

  for (final entry in screens.entries) {
    for (final size in sizes.entries) {
      testWidgets('${entry.key} — ${size.key}', (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});

        tester.view.physicalSize = size.value * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(AppFlavor.plum),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: const Locale('tr'),
              supportedLocales: const [Locale('tr')],
              home: wrap(entry.value),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 400));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Önce ekranın gerçekten çizildiği: `takeException` boş bir
        // ağaçta da null döner, yani bu doğrulama olmadan test hiçbir şey
        // sınamamış olurdu.
        expect(
          find.byWidget(entry.value),
          findsOneWidget,
          reason: '${entry.key}: ekran çizilmedi — iddia boşa gider',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} · ${size.key}: düzen hatası',
        );
      });
    }
  }
}
