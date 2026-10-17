import 'package:flutter/widgets.dart';

import 'package:period_tracker/domain/models/article.dart';
import 'package:period_tracker/domain/services/session_plan.dart';
import 'package:period_tracker/presentation/appearance/appearance_screen.dart';
import 'package:period_tracker/presentation/assistant/assistant_screen.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/calendar/past_periods_screen.dart';
import 'package:period_tracker/presentation/health_check/heavy_bleeding_screen.dart';
import 'package:period_tracker/presentation/health_library/article_screen.dart';
import 'package:period_tracker/presentation/health_library/health_library_screen.dart';
import 'package:period_tracker/presentation/health_sync/health_sync_screen.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/insights/cycle_summary_screen.dart';
import 'package:period_tracker/presentation/insights/insights_screen.dart';
import 'package:period_tracker/presentation/insights/prediction_info_screen.dart';
import 'package:period_tracker/presentation/legal/privacy_policy_screen.dart';
import 'package:period_tracker/presentation/legal/terms_of_service_screen.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_birth_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_conception_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_cycle_length_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_goal_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_last_period_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_period_length_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_success_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_welcome_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_dashboard_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_match_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_qr_gen_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_scan_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_share_settings_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_support_screen.dart';
import 'package:period_tracker/presentation/pregnancy/care_list_screen.dart';
import 'package:period_tracker/presentation/pregnancy/care_summary_screen.dart';
import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';
import 'package:period_tracker/presentation/pregnancy/end_pregnancy_screen.dart';
import 'package:period_tracker/presentation/pregnancy/past_pregnancies_screen.dart';
import 'package:period_tracker/presentation/pregnancy/postpartum_home_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_home_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_months_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_setup_screen.dart';
import 'package:period_tracker/presentation/premium/premium_screen.dart';
import 'package:period_tracker/presentation/profile/cycle_settings_screen.dart';
import 'package:period_tracker/presentation/profile/notification_settings_screen.dart';
import 'package:period_tracker/presentation/profile/personal_info_screen.dart';
import 'package:period_tracker/presentation/profile/privacy_security_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';
import 'package:period_tracker/presentation/recipe/recipe_detail_screen.dart';
import 'package:period_tracker/presentation/session/session_screen.dart';
import 'package:period_tracker/presentation/splash/splash_screen.dart';
import 'package:period_tracker/presentation/widgets_preview/widgets_preview_screen.dart';
import 'package:period_tracker/presentation/yoga/yoga_detail_screen.dart';

/// Testte tek başına çizilebilen bütün ekranlar.
///
/// Her ekran testi (düzen, erişilebilirlik) aynı listeyi kullanıyor: yeni
/// bir ekran buraya eklenince hepsine birden giriyor. Liste iki dosyada
/// ayrı tutulsaydı biri eskirdi.
Map<String, Widget> allScreens() => <String, Widget>{
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
  'onboarding_welcome': const OnboardingWelcomeScreen(),
  'onboarding_last_period': const OnboardingLastPeriodScreen(),
  'onboarding_cycle_length': const OnboardingCycleLengthScreen(),
  'log_entry': const LogEntryScreen(),
  'pregnancy_setup': const PregnancySetupScreen(),
  'pregnancy_home': const PregnancyHomeScreen(),
  'postpartum_home': const PostpartumHomeScreen(),
  'care_list': const CareListScreen(),
  'care_summary': const CareSummaryScreen(),
  'pregnancy_months': const PregnancyMonthsScreen(),
  'end_pregnancy': const EndPregnancyScreen(),
  'cycle_summary': const CycleSummaryScreen(),
  'partner_match': const PartnerMatchScreen(),
  'partner_share_settings': const PartnerShareSettingsScreen(),
  'yoga_detail': const YogaDetailScreen(),
  'session': const SessionScreen(plan: SessionPlan.yoga),
  'danger_signs': const DangerSignsScreen(period: DangerPeriod.pregnancy),
};
