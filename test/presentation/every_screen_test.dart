import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screen_harness.dart';

import 'package:period_tracker/domain/models/article.dart';
import 'package:period_tracker/presentation/appearance/appearance_screen.dart';
import 'package:period_tracker/presentation/assistant/assistant_screen.dart';
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
import 'package:period_tracker/presentation/calendar/past_periods_screen.dart';
import 'package:period_tracker/presentation/insights/prediction_info_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_birth_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_conception_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_goal_screen.dart';
import 'package:period_tracker/presentation/pregnancy/past_pregnancies_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_period_length_screen.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/insights/insights_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_success_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_dashboard_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_qr_gen_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_scan_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';
import 'package:period_tracker/presentation/recipe/recipe_detail_screen.dart';
import 'package:period_tracker/presentation/splash/splash_screen.dart';

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

  setUpAll(mockMissingPlatformChannels);

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
    'past_periods': const PastPeriodsScreen(),
    'prediction_info': const PredictionInfoScreen(),
    'personal_info': const PersonalInfoScreen(),
    'appearance': const AppearanceScreen(),
    'health_sync': const HealthSyncScreen(),
    'heavy_bleeding': const HeavyBleedingScreen(),
    'partner_support': const PartnerSupportScreen(),
    'widgets_preview': const WidgetsPreviewScreen(),
    'onboarding_goal': const OnboardingGoalScreen(),
    'onboarding_conception': const OnboardingConceptionScreen(),
    'onboarding_birth': const OnboardingBirthScreen(),
    'past_pregnancies': const PastPregnanciesScreen(),
    'onboarding_period_length': const OnboardingPeriodLengthScreen(),
    'splash': const SplashScreen(),
    'home': const HomeScreen(),
    'calendar': const CalendarScreen(),
    'insights': const InsightsScreen(),
    'profile_settings': const ProfileSettingsScreen(),
    'recipe_detail': const RecipeDetailScreen(),
    'onboarding_success': const OnboardingSuccessScreen(),
    'partner_dashboard': const PartnerDashboardScreen(),
    'partner_qr_gen': const PartnerQrGenScreen(),
    'partner_scan': const PartnerScanScreen(),
  };

  for (final entry in screens.entries) {
    for (final size in screenSizes.entries) {
      testWidgets('${entry.key} — ${size.key}', (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});

        await pumpScreen(tester, entry.value, size: size.value);

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
