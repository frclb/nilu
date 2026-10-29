import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/core/navigation/app_router.dart';
import 'package:period_tracker/core/navigation/navigation_service.dart';
import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/data/datasources/remote/account_auth.dart';
import 'package:period_tracker/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:period_tracker/domain/view_models/account_view_model.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/presentation/account/sign_in_screen.dart';

import '../support/fake_partner_remote.dart';
import '../support/fake_sync.dart';
import 'screen_harness.dart';

/// Uygulama girişten sonra kullanılıyor mu?
///
/// TestFlight bulgusu: "normal kullanıcı Apple ya da Google ile giriş
/// yapmadan girebiliyor". Yönlendirme kararı `app_router_test`'te saf
/// fonksiyon olarak sınanıyor; burada gerçek yönlendirici, gerçek giriş
/// ekranı ve girişten sonra kimliğin tazelenmesi birlikte.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);

  late FakeAccountAuth auth;
  late AccountViewModel hesap;
  late UserViewModel user;

  Future<void> kur({required bool onboarded}) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': onboarded});
    auth = FakeAccountAuth();
    hesap = AccountViewModel(auth: auth, debounce: const Duration(days: 1));
    user = UserViewModel(auth: _Oturum(auth), firestore: FakePartnerRemote());
    // Uygulamada `CloudSyncTrigger` bağlıyor.
    hesap.onIdentityChanged = user.refreshAuthState;
    while (!user.isLoaded) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  GoRouter yonlendirici(String baslangic) => GoRouter(
    navigatorKey: NavigationService().navigatorKey,
    initialLocation: baslangic,
    refreshListenable: user,
    redirect: (_, state) => resolveRedirect(
      isLoaded: user.isLoaded,
      onboardingComplete: user.onboardingComplete,
      location: state.matchedLocation,
      needsSignIn: user.needsSignIn,
    ),
    routes: [
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.pushNamed(RouteNames.onboardingGoal),
            child: const Text('karşılama'),
          ),
        ),
      ),
      GoRoute(
        path: '/sign_in',
        name: RouteNames.signIn,
        builder: (_, _) => const SignInScreen(),
      ),
      GoRoute(
        path: '/onboarding_goal',
        name: RouteNames.onboardingGoal,
        builder: (_, _) => const Scaffold(body: Text('kurulum')),
      ),
      GoRoute(
        path: '/home',
        name: RouteNames.home,
        builder: (_, _) => const Scaffold(body: Text('ana ekran')),
      ),
      for (final (yol, ad) in [
        ('/privacy_policy', RouteNames.privacyPolicy),
        ('/terms_of_service', RouteNames.termsOfService),
      ])
        GoRoute(
          path: yol,
          name: ad,
          builder: (_, _) => Scaffold(body: Text(ad)),
        ),
    ],
  );

  Future<void> girisYap(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('sign_in_apple')));
    await settleAsync(tester);
  }

  testWidgets('kurulum girişten sonra başlıyor', (tester) async {
    await tester.runAsync(() => kur(onboarded: false));
    await pumpRouter(
      tester,
      routes: const [],
      router: yonlendirici('/onboarding'),
      userViewModel: user,
      accountViewModel: hesap,
    );

    await tester.tap(find.text('karşılama'));
    await settleAsync(tester);
    expect(find.byKey(const Key('sign_in')), findsOneWidget);
    expect(find.text('kurulum'), findsNothing);

    await girisYap(tester);
    expect(find.text('kurulum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('çıkış yapmış kullanıcı ana ekrana girişle dönüyor', (
    tester,
  ) async {
    await tester.runAsync(() => kur(onboarded: true));
    await pumpRouter(
      tester,
      routes: const [],
      router: yonlendirici('/home'),
      userViewModel: user,
      accountViewModel: hesap,
    );
    expect(find.byKey(const Key('sign_in')), findsOneWidget);
    expect(find.text('ana ekran'), findsNothing);

    await girisYap(tester);
    expect(find.text('ana ekran'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('vazgeçilen giriş ekranda bırakıyor', (tester) async {
    await tester.runAsync(() => kur(onboarded: true));
    auth.nextStatus = SignInStatus.cancelled;
    await pumpRouter(
      tester,
      routes: const [],
      router: yonlendirici('/home'),
      userViewModel: user,
      accountViewModel: hesap,
    );
    await girisYap(tester);
    expect(find.byKey(const Key('sign_in')), findsOneWidget);
    expect(find.text('ana ekran'), findsNothing);
  });

  // Uzun dillerde ve küçük ekranda taşma yok: ekran kayıyor.
  for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
    testWidgets('$dil: küçük ekranda taşmadan çiziliyor', (tester) async {
      await tester.runAsync(() => kur(onboarded: false));
      await pumpRouter(
        tester,
        routes: const [],
        router: yonlendirici('/sign_in'),
        size: const Size(320, 568),
        locale: Locale(dil),
        userViewModel: user,
        accountViewModel: hesap,
      );
      expect(find.byKey(const Key('sign_in')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

/// Oturum sahte girişin durumundan okunuyor: giriş yapılınca kimlik değişir.
class _Oturum extends FirebaseAuthDataSource {
  _Oturum(this.auth);

  final FakeAccountAuth auth;

  @override
  String? get accountUid => auth.currentAccount?.uid;
}
