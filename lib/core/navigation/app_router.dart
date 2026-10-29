import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import 'navigation_service.dart';
import 'tab_navigation_shell.dart';
import 'package:provider/provider.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../presentation/pregnancy/care_list_screen.dart';
import '../../presentation/pregnancy/care_summary_screen.dart';
import '../../presentation/pregnancy/danger_signs_screen.dart';
import '../../presentation/pregnancy/end_pregnancy_screen.dart';
import '../../presentation/pregnancy/past_pregnancies_screen.dart';
import '../../presentation/pregnancy/postpartum_home_screen.dart';
import '../../presentation/pregnancy/pregnancy_home_screen.dart';
import '../../presentation/pregnancy/pregnancy_months_screen.dart';
import '../../presentation/pregnancy/pregnancy_setup_screen.dart';
import '../../presentation/partner_match/partner_dashboard_screen.dart';

// Screens
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_welcome_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_goal_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_conception_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_birth_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_last_period_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_period_length_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_cycle_length_screen.dart';
import '../../presentation/onboarding_welcome/onboarding_success_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/calendar/calendar_screen.dart';
import '../../presentation/log_entry/log_entry_screen.dart';
import '../../presentation/appearance/appearance_screen.dart';
import '../../presentation/assistant/assistant_screen.dart';
import '../../presentation/health_sync/health_sync_screen.dart';
import '../../presentation/insights/insights_screen.dart';
import '../../presentation/profile/notification_settings_screen.dart';
import '../../presentation/profile/personal_info_screen.dart';
import '../../presentation/profile/cycle_settings_screen.dart';
import '../../presentation/calendar/past_periods_screen.dart';
import '../../presentation/insights/prediction_info_screen.dart';
import '../../presentation/profile/privacy_security_screen.dart';
import '../../presentation/account/account_screen.dart';
import '../../presentation/account/sign_in_screen.dart';
import '../../presentation/health_library/health_library_screen.dart';
import '../../presentation/profile/profile_settings_screen.dart';
import '../../presentation/partner_match/partner_match_screen.dart';
import '../../presentation/partner_match/partner_qr_gen_screen.dart';
import '../../presentation/partner_match/partner_scan_screen.dart';
import '../../presentation/partner_match/partner_support_screen.dart';
import '../../presentation/partner_match/partner_share_settings_screen.dart';
import '../../presentation/widgets_preview/widgets_preview_screen.dart';
import '../../presentation/recipe/recipe_detail_screen.dart';
import '../../presentation/yoga/yoga_detail_screen.dart';
import '../../presentation/legal/privacy_policy_screen.dart';
import '../../presentation/legal/terms_of_service_screen.dart';
import '../../presentation/premium/premium_screen.dart';
import '../../presentation/insights/cycle_summary_screen.dart';

/// Onboarding tamamlanmadan da erişilebilen yollar.
///
/// `/partner_scan` buradadır çünkü partner, karşılama ekranından QR okutarak
/// giriş yapar; `/account_restore` da karşılama ekranından açılıyor (yeni
/// cihazda buluttaki kayıtları geri almak); `/splash` durum yüklenirken
/// beklenen yerdir.
const Set<String> preOnboardingPaths = {
  '/splash',
  '/onboarding',
  '/onboarding_goal',
  '/onboarding_pregnancy',
  '/onboarding_conception',
  '/onboarding_birth',
  '/onboarding_last_period',
  '/onboarding_period_length',
  '/onboarding_cycle_length',
  '/onboarding_success',
  '/partner_scan',
  '/account_restore',
  '/sign_in',
  '/privacy_policy',
  '/terms_of_service',
};

const String splashPath = '/splash';
const String onboardingPath = '/onboarding';
const String homePath = '/home';
const String signInPath = '/sign_in';

/// Oturum açmadan da erişilebilen yollar.
///
/// Uygulama Apple ya da Google hesabıyla kullanılıyor. Karşılama ekranı,
/// giriş ekranı ve yasal metinler girişten önce okunabilmeli. Partner
/// okutma ekranı ve buluttan geri yükleme kendi giriş düğmelerini
/// gösteriyor: oradan girişe yönlendirmek akışı ikiye bölerdi.
const Set<String> signedOutPaths = {
  '/splash',
  '/onboarding',
  signInPath,
  '/partner_scan',
  '/account_restore',
  '/privacy_policy',
  '/terms_of_service',
};

/// Yönlendirme kararı — saf fonksiyon.
///
/// Router'ın `redirect` geri çağrısından ayrı tutulur ki widget ağacı
/// kurmadan, tüm durum bileşimleri için test edilebilsin.
///
/// Dönen değer null ise gezinmeye izin verilir.
String? resolveRedirect({
  required bool isLoaded,
  required bool onboardingComplete,
  required String location,
  bool needsSignIn = false,
}) {
  // Durum depodan okunana kadar splash'te bekle. Erken karar verirsek dönen
  // kullanıcıyı yanlışlıkla onboarding'e düşürürüz.
  if (!isLoaded) {
    return location == splashPath ? null : splashPath;
  }

  // Okuma bitti: splash'ten gidilecek yere geç.
  //
  // Kök adres ("/") da splash gibi: Android'de uygulamayı bir sistem
  // ekranı (Health Connect'in politika bağlantısı) yeni bir pencerede
  // açınca Flutter "/" ile başlıyor; rota olmadığı için "sayfa bulunamadı"
  // çıkıyordu.
  if (location == splashPath || location == '/') {
    return onboardingComplete ? homePath : onboardingPath;
  }

  // Onboarding tamamlanmışken karşılama ekranında kalınmaz.
  //
  // Uygulama her zaman splash'ten başlamayabilir: web'de URL hash'i, mobilde
  // derin bağlantı doğrudan `/onboarding`'e düşürebilir. Bu kural olmadan
  // dönen kullanıcı karşılama ekranında takılıp kalıyordu.
  // (Akışın ara adımları hariç tutulur; onboarding tamamlanır tamamlanmaz
  // başarı ekranından atılmamak için.)
  if (onboardingComplete && location == onboardingPath) {
    return homePath;
  }

  // Onboarding tamamlanmadan uygulamanın gövdesine girilemez.
  // (Çıkış yapıldığında bayrak sıfırlandığı için kullanıcı burada kalır.)
  if (!onboardingComplete && !preOnboardingPaths.contains(location)) {
    return onboardingPath;
  }

  // Oturum yoksa giriş ekranı. Kurulumdan önce de sonra da: çıkış yapan
  // ya da hesabını silen kullanıcı da buraya düşüyor.
  //
  // [needsSignIn] yalnızca hesap hizmeti hazırken doğru: Firebase
  // başlamadan karar verilmiyor, başlayınca `refreshListenable` yönlendirmeyi
  // yeniden çalıştırıyor.
  //
  // Girişten sonra nereye gidileceğine giriş ekranı karar veriyor, burası
  // değil: ekran karşılamanın üstüne itildiğinde `refreshListenable`
  // yönlendirmeyi alttaki karşılama konumu için çalıştırıyor ve kullanıcı
  // giriş ekranında kalıyordu.
  if (needsSignIn && !signedOutPaths.contains(location)) {
    return signInPath;
  }

  return null;
}

/// go_router yapılandırması.
///
/// Yönlendirme `initialLocation` ile değil `redirect` ile yapılır: durum
/// depodan **asenkron** okunduğu için router kurulurken `onboardingComplete`
/// henüz varsayılan değerindedir. `redirect` her gezinmede güncel durumu
/// okur ve `refreshListenable` sayesinde durum değişince yeniden çalışır.
///
/// ⚠️ Bu fonksiyon uygulama ömrü boyunca **bir kez** çağrılmalıdır
/// (bkz. `main.dart`). Her build'de yeniden çağrılırsa yeni bir GoRouter
/// üretilir; gezinme yığını sıfırlanır ve kullanıcı bulunduğu ekrandan
/// koparılır — durum değişince ana ekrana geri sıçramasının sebebi buydu.
///
/// [navigatorKey] yalnızca testler için vardır: `NavigationService` bir
/// singleton olduğu için aynı `GlobalKey`'i paylaşan iki router aynı süreçte
/// yaşayamaz. Uygulamada varsayılan bırakılmalıdır.
GoRouter createAppRouter(
  UserViewModel userViewModel, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey ?? NavigationService().navigatorKey,
    initialLocation: splashPath,
    refreshListenable: userViewModel,
    redirect: (context, state) => resolveRedirect(
      isLoaded: userViewModel.isLoaded,
      onboardingComplete: userViewModel.onboardingComplete,
      location: state.matchedLocation,
      needsSignIn: userViewModel.needsSignIn,
    ),
    // Rota loglarını yalnızca debug derlemede yaz — release'te gürültü ve
    // gereksiz bilgi sızıntısı olmasın.
    debugLogDiagnostics: kDebugMode,
    routes: [
      // Durum yüklenirken beklenen ara ekran.
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // -----------------------------------------
      // 1️⃣ Onboarding Akışı
      // -----------------------------------------
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding_goal',
        name: RouteNames.onboardingGoal,
        builder: (context, state) => const OnboardingGoalScreen(),
      ),
      // "Hamileyim" yolu: uygulamanın gebelik kurulumu, kurulum kipinde.
      // `/pregnancy/setup` onboarding'den önce açılamıyor (redirect) ve bitince
      // ana ekrana gidiyor; kurulumu tamamlayacak olan ise son ekran.
      GoRoute(
        path: '/onboarding_pregnancy',
        name: RouteNames.onboardingPregnancy,
        builder: (context, state) =>
            const PregnancySetupScreen(fromOnboarding: true),
      ),
      // "Bebek istiyorum": ne zamandır denendiği, sonra döngü soruları.
      GoRoute(
        path: '/onboarding_conception',
        name: RouteNames.onboardingConception,
        builder: (context, state) => const OnboardingConceptionScreen(),
      ),
      // "Yakın zamanda doğum yaptım": doğum günü, sonra son ekran.
      GoRoute(
        path: '/onboarding_birth',
        name: RouteNames.onboardingBirth,
        builder: (context, state) => const OnboardingBirthScreen(),
      ),
      GoRoute(
        path: '/onboarding_last_period',
        name: RouteNames.onboardingLastPeriod,
        builder: (context, state) => const OnboardingLastPeriodScreen(),
      ),
      GoRoute(
        path: '/onboarding_period_length',
        name: RouteNames.onboardingPeriodLength,
        builder: (context, state) => const OnboardingPeriodLengthScreen(),
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
                  if (isPartner) return const PartnerDashboardScreen();
                  // Partner modunun kalıbı: aynı sekme, evreye göre ekran.
                  // Yönlendirici yapısına dokunulmuyor.
                  final gebelik = context.watch<PregnancyViewModel>();
                  // Splash yalnızca kullanıcı durumunu bekliyor. Gebelik
                  // kaydı ondan sonra okunursa gebe kullanıcı açılışta bir an
                  // regl tahminli ana ekranı görürdü.
                  if (!gebelik.loaded) return const Scaffold();
                  return switch (gebelik.stage) {
                    LifeStage.cycle => const HomeScreen(),
                    LifeStage.pregnancy => const PregnancyHomeScreen(),
                    LifeStage.postpartum => const PostpartumHomeScreen(),
                  };
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
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          // Tab 3: İçgörüler.
          //
          // Bu ekran daha önce kök seviyede bir rotaydı ama hiçbir yerden
          // bağlantısı yoktu — kullanıcı ona hiçbir zaman ulaşamıyordu.
          // Sekmeye alındı; partner modunda gösterilmez (bkz.
          // `CustomBottomNav`, partner listesi bu dalı atlar).
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                name: RouteNames.insights,
                // Gebelik ve lohusalıkta döngü analizi anlamsız (trend yok,
                // tahmin yok); sekmenin yerini randevular alıyor.
                builder: (context, state) =>
                    context.watch<PregnancyViewModel>().stage == LifeStage.cycle
                    ? const InsightsScreen()
                    : const CareListScreen(),
              ),
            ],
          ),
          // Tab 4: Health Library / Partner Rehberi
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
          // Tab 5: Profil
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
          // `?date=2026-10-05`: takvimden geçmiş bir güne kayıt.
          child: LogEntryScreen(
            date: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
          ),
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
        path: '/assistant',
        name: RouteNames.assistant,
        builder: (context, state) => const AssistantScreen(),
      ),
      GoRoute(
        path: '/pregnancy/setup',
        name: RouteNames.pregnancySetup,
        builder: (context, state) => const PregnancySetupScreen(),
      ),
      GoRoute(
        path: '/pregnancy/months',
        name: RouteNames.pregnancyMonths,
        builder: (context, state) => const PregnancyMonthsScreen(),
      ),
      GoRoute(
        path: '/pregnancy/end',
        name: RouteNames.endPregnancy,
        builder: (context, state) => const EndPregnancyScreen(),
      ),
      // Geçmiş gebelikler ve her birinin kaydı (randevu özetinin geçmiş
      // kipi). Evreden bağımsız: biten gebelik her evrede açılabilmeli.
      GoRoute(
        path: '/pregnancy/history',
        name: RouteNames.pastPregnancies,
        builder: (context, state) => const PastPregnanciesScreen(),
      ),
      GoRoute(
        path: '/pregnancy/history/:id',
        name: RouteNames.pastPregnancy,
        builder: (context, state) =>
            CareSummaryScreen(pregnancyId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/care',
        name: RouteNames.careList,
        builder: (context, state) => const CareListScreen(),
      ),
      GoRoute(
        path: '/care/summary',
        name: RouteNames.careSummary,
        builder: (context, state) => const CareSummaryScreen(),
      ),
      GoRoute(
        path: '/danger',
        name: RouteNames.dangerSigns,
        builder: (context, state) {
          final istenen = state.uri.queryParameters['period'];
          final evre = context.read<PregnancyViewModel>().stage;
          // Parametre yoksa ya da tanınmıyorsa o anki evreye göre: lohusa
          // bir anneye gebelik listesi göstermek yanlış olurdu.
          final donem =
              DangerPeriod.values.where((d) => d.name == istenen).firstOrNull ??
              (evre == LifeStage.postpartum
                  ? DangerPeriod.postpartum
                  : DangerPeriod.pregnancy);
          return DangerSignsScreen(period: donem);
        },
      ),

      GoRoute(
        path: '/health_sync',
        name: RouteNames.healthSync,
        builder: (context, state) => const HealthSyncScreen(),
      ),

      GoRoute(
        path: '/appearance',
        name: RouteNames.appearance,
        builder: (context, state) => const AppearanceScreen(),
      ),

      GoRoute(
        path: '/partner',
        name: RouteNames.partner,
        builder: (context, state) => const PartnerMatchScreen(),
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
        // `k`: davet bağlantısından gelen kod (bkz. `main.dart`).
        builder: (context, state) =>
            PartnerScanScreen(initialCode: state.uri.queryParameters['k']),
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
        path: '/past_periods',
        name: RouteNames.pastPeriods,
        builder: (context, state) => const PastPeriodsScreen(),
      ),

      GoRoute(
        path: '/prediction_info',
        name: RouteNames.predictionInfo,
        builder: (context, state) => const PredictionInfoScreen(),
      ),

      GoRoute(
        path: '/privacy_security',
        name: RouteNames.privacySecurity,
        builder: (context, state) => const PrivacySecurityScreen(),
      ),

      GoRoute(
        path: '/account',
        name: RouteNames.account,
        builder: (context, state) => const AccountScreen(),
      ),
      // Karşılama ekranından: yeni cihazda kayıtları buluttan geri almak.
      GoRoute(
        path: '/account_restore',
        name: RouteNames.accountRestore,
        builder: (context, state) => const AccountScreen(restore: true),
      ),

      // Giriş: uygulama Apple ya da Google hesabıyla kullanılıyor. Oraya
      // yönlendirme `resolveRedirect`'te; giriş bitince de oradan çıkılıyor.
      GoRoute(
        path: '/sign_in',
        name: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
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
        path: '/cycle-summary',
        name: RouteNames.cycleSummary,
        builder: (context, state) => const CycleSummaryScreen(),
      ),

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
