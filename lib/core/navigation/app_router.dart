import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import 'navigation_service.dart';
import 'tab_navigation_shell.dart';
import 'package:provider/provider.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../presentation/partner_match/partner_dashboard_screen.dart';

// Screens
import '../../presentation/onboarding_welcome/onboarding_welcome_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_last_period_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_cycle_length_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_success_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/calendar/calendar_screen.dart';
import '../../presentation/log_entry/log_entry_screen.dart';
import '../../presentation/insights/insights_screen.dart';
import '../../presentation/profile/notification_settings_screen.dart';
import '../../presentation/profile/personal_info_screen.dart';
import '../../presentation/profile/cycle_settings_screen.dart';
import '../../presentation/profile/privacy_security_screen.dart';
import '../../presentation/health_library/health_library_screen.dart';
import '../../presentation/profile/profile_settings_screen.dart';
import '../../presentation/partner_match/partner_match_screen.dart';
import '../../presentation/partner_match/partner_qr_gen_screen.dart';
import '../../presentation/partner_match/partner_scan_screen.dart';
import '../../presentation/partner_match/partner_support_screen.dart';
import '../../presentation/partner_match/partner_share_settings_screen.dart';
import '../../presentation/partner_match/partner_notification_settings_screen.dart';
import '../../presentation/partner_match/partner_important_days_screen.dart';
import '../../presentation/widgets_preview/widgets_preview_screen.dart';
import '../../presentation/exercise/exercise_detail_screen.dart';
import '../../presentation/recipe/recipe_detail_screen.dart';
import '../../presentation/yoga/yoga_detail_screen.dart';
import '../../presentation/legal/privacy_policy_screen.dart';
import '../../presentation/legal/terms_of_service_screen.dart';
import '../../presentation/premium/premium_screen.dart';

/// go_router yapılandırması — UserViewModel durumuna göre initialLocation belirlenir.
GoRouter createAppRouter(UserViewModel userViewModel) {
  return GoRouter(
    navigatorKey: NavigationService().navigatorKey,
    initialLocation: userViewModel.onboardingComplete ? '/home' : '/onboarding',
    refreshListenable: userViewModel,
    // Rota loglarını yalnızca debug derlemede yaz — release'te gürültü ve
    // gereksiz bilgi sızıntısı olmasın.
    debugLogDiagnostics: kDebugMode,
    routes: [
      // -----------------------------------------
      // 1️⃣ Onboarding Akışı
      // -----------------------------------------
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding_last_period',
        name: RouteNames.onboardingLastPeriod,
        builder: (context, state) => const OnboardingLastPeriodScreen(),
      ),
      GoRoute(
        path: '/onboarding_cycle_length',
        name: RouteNames.onboardingCycleLength,
        builder: (context, state) => const OnboardingCycleLengthScreen(),
      ),
      GoRoute(
        path: '/onboarding_success',
        name: RouteNames.onboardingSuccess,
        builder: (context, state) => const OnboardingSuccessScreen(),
      ),

      // -----------------------------------------
      // Alt Menülü Ana Sekmeler (Tab Bar)
      // -----------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return TabNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Ana Sayfa / Partner Durum
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) {
                  final isPartner = context.watch<UserViewModel>().isPartner;
                  return isPartner
                      ? const PartnerDashboardScreen()
                      : const HomeScreen();
                },
              ),
            ],
          ),
          // Tab 2: Takvim / Partner Takvim
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: RouteNames.calendar,
                builder: (context, state) {
                  final isPartner = context.watch<UserViewModel>().isPartner;
                  return isPartner
                      ? const PartnerImportantDaysScreen()
                      : const CalendarScreen();
                },
              ),
            ],
          ),
          // Tab 3: Health Library / Partner Rehberi
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/health-library',
                name: RouteNames.healthLibrary,
                builder: (context, state) {
                  final isPartner = context.watch<UserViewModel>().isPartner;
                  return isPartner
                      ? const PartnerSupportScreen()
                      : const HealthLibraryScreen();
                },
              ),
            ],
          ),
          // Tab 4: Profil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (context, state) => const ProfileSettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // -----------------------------------------
      // Sayfa Üzerine Binen Ekranlar (Modallar vb.)
      // -----------------------------------------

      // Log Entry Modal - Yukarıdan slayt geçişi ile
      GoRoute(
        path: '/log-entry',
        name: RouteNames.logEntry,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LogEntryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: '/insights',
        name: RouteNames.insights,
        builder: (context, state) => const InsightsScreen(),
      ),

      GoRoute(
        path: '/partner',
        name: RouteNames.partner,
        builder: (context, state) => const PartnerMatchScreen(),
      ),

      GoRoute(
        path: '/exercise_detail',
        name: RouteNames.exerciseDetail,
        builder: (context, state) => const ExerciseDetailScreen(),
      ),

      GoRoute(
        path: '/recipe_detail',
        name: RouteNames.recipeDetail,
        builder: (context, state) => const RecipeDetailScreen(),
      ),

      GoRoute(
        path: '/yoga_detail',
        name: RouteNames.yogaDetail,
        builder: (context, state) => const YogaDetailScreen(),
      ),

      GoRoute(
        path: '/partner_qr_gen',
        name: RouteNames.partnerQrGen,
        builder: (context, state) => const PartnerQrGenScreen(),
      ),

      GoRoute(
        path: '/partner_scan',
        name: RouteNames.partnerScan,
        builder: (context, state) => const PartnerScanScreen(),
      ),

      GoRoute(
        path: '/partner_support',
        name: RouteNames.partnerSupport,
        builder: (context, state) => const PartnerSupportScreen(),
      ),

      GoRoute(
        path: '/partner_share_settings',
        name: RouteNames.partnerShareSettings,
        builder: (context, state) => const PartnerShareSettingsScreen(),
      ),

      GoRoute(
        path: '/partner_notification_settings',
        name: RouteNames.partnerNotificationSettings,
        builder: (context, state) => const PartnerNotificationSettingsScreen(),
      ),

      GoRoute(
        path: '/partner_important_days',
        name: RouteNames.partnerImportantDays,
        builder: (context, state) => const PartnerImportantDaysScreen(),
      ),

      GoRoute(
        path: '/personal_info',
        name: RouteNames.personalInfo,
        builder: (context, state) => const PersonalInfoScreen(),
      ),

      GoRoute(
        path: '/cycle_settings',
        name: RouteNames.cycleSettings,
        builder: (context, state) => const CycleSettingsScreen(),
      ),

      GoRoute(
        path: '/privacy_security',
        name: RouteNames.privacySecurity,
        builder: (context, state) => const PrivacySecurityScreen(),
      ),

      GoRoute(
        path: '/notification_settings',
        name: RouteNames.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Legal
      GoRoute(
        path: '/privacy_policy',
        name: RouteNames.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms_of_service',
        name: RouteNames.termsOfService,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      // Premium
      GoRoute(
        path: '/premium',
        name: RouteNames.premium,
        builder: (context, state) => const PremiumScreen(),
      ),

      // Placeholder ekranlar
      GoRoute(
        path: '/widgets_preview',
        name: RouteNames.widgetsPreview,
        builder: (context, state) => const WidgetsPreviewScreen(),
      ),
    ],
  );
}
