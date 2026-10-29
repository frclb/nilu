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
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/account/reset_password_screen.dart';
import 'package:period_tracker/presentation/account/sign_in_screen.dart';
import 'package:period_tracker/presentation/account/verify_email_screen.dart';

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
      needsEmailVerification: user.needsEmailVerification,
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
        path: verifyEmailPath,
        name: RouteNames.verifyEmail,
        builder: (_, _) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: resetPasswordPath,
        name: RouteNames.resetPassword,
        builder: (_, state) =>
            ResetPasswordScreen(code: state.uri.queryParameters['code']),
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

  group('e-posta', () {
    Future<BuildContext> ac(
      WidgetTester tester, {
      Size size = const Size(390, 844),
      Locale locale = const Locale('tr'),
    }) async {
      await tester.runAsync(() => kur(onboarded: false));
      await pumpRouter(
        tester,
        routes: const [],
        router: yonlendirici('/sign_in'),
        size: size,
        locale: locale,
        userViewModel: user,
        accountViewModel: hesap,
      );
      // Liste görünmeyen satırı kurmuyor: önce kaydır.
      final dugme = find.byKey(const Key('sign_in_email'));
      await tester.scrollUntilVisible(
        dugme,
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('sign_in')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(dugme);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email_sign_in_sheet')), findsOneWidget);
      return tester.element(find.byKey(const Key('sign_in')));
    }

    Future<void> doldur(
      WidgetTester tester,
      String eposta,
      String sifre,
    ) async {
      await tester.enterText(find.byKey(const Key('email_field')), eposta);
      await tester.enterText(find.byKey(const Key('password_field')), sifre);
    }

    Future<void> bas(WidgetTester tester, Key key) async {
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
      await settleAsync(tester);
    }

    testWidgets('girişte ne saklandığı düğmelerin altında yazıyor', (
      tester,
    ) async {
      await tester.runAsync(() => kur(onboarded: false));
      await pumpRouter(
        tester,
        routes: const [],
        router: yonlendirici('/sign_in'),
        userViewModel: user,
        accountViewModel: hesap,
      );
      final not = find.byKey(const Key('sign_in_notice'));
      await tester.scrollUntilVisible(
        not,
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('sign_in')),
          matching: find.byType(Scrollable),
        ),
      );
      final ctx = tester.element(find.byKey(const Key('sign_in')));
      expect(find.text(ctx.tr('sign_in_notice')), findsOneWidget);
      expect(
        tester.getTopLeft(not).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const Key('sign_in_email'))).dy,
        ),
      );
    });

    testWidgets('Apple önce, e-posta en sonda', (tester) async {
      await tester.runAsync(() => kur(onboarded: false));
      await pumpRouter(
        tester,
        routes: const [],
        router: yonlendirici('/sign_in'),
        userViewModel: user,
        accountViewModel: hesap,
      );
      double y(String key) => tester.getTopLeft(find.byKey(Key(key))).dy;
      expect(y('sign_in_apple'), lessThan(y('sign_in_google')));
      expect(y('sign_in_google'), lessThan(y('sign_in_email')));
    });

    testWidgets('doğrulanmış hesapla girişten sonra kurulum başlıyor', (
      tester,
    ) async {
      await ac(tester);
      auth.emailVerified = true;
      await doldur(tester, 'ada@ornek.com', 'gizli-sifre');
      await bas(tester, const Key('email_submit'));

      expect(find.text('kurulum'), findsOneWidget);
      expect(find.byKey(const Key('email_sign_in_sheet')), findsNothing);
      final giris = auth.emailSignIns.single;
      expect(giris.email, 'ada@ornek.com');
      expect(giris.create, isFalse);
      expect(
        giris.lang,
        'tr',
        reason: 'Firebase e-postaları uygulamanın dilinde',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hesap oluşturma yeni hesap olarak gidiyor', (tester) async {
      final ctx = await ac(tester);
      await tester.tap(find.text(ctx.tr('email_mode_create')));
      await tester.pumpAndSettle();
      expect(find.text(ctx.tr('email_create_note')), findsOneWidget);

      await doldur(tester, 'ada@ornek.com', 'gizli-sifre');
      await bas(tester, const Key('email_submit'));

      expect(auth.emailSignIns.single.create, isTrue);
      // Adres doğrulanmadan uygulama açılmıyor.
      expect(find.byKey(const Key('verify_email')), findsOneWidget);
      expect(find.textContaining('ada@ornek.com'), findsOneWidget);
      expect(find.text('kurulum'), findsNothing);
    });

    group('doğrulama zorunlu', () {
      Future<BuildContext> dogrulamada(WidgetTester tester) async {
        final ctx = await ac(tester);
        await tester.tap(find.text(ctx.tr('email_mode_create')));
        await tester.pumpAndSettle();
        await doldur(tester, 'ada@ornek.com', 'gizli-sifre');
        await bas(tester, const Key('email_submit'));
        expect(find.byKey(const Key('verify_email')), findsOneWidget);
        return tester.element(find.byKey(const Key('verify_email')));
      }

      testWidgets('doğrulanmadan "Doğruladım" ekranda bırakıyor', (
        tester,
      ) async {
        await dogrulamada(tester);
        await bas(tester, const Key('verify_email_check'));
        expect(find.byKey(const Key('verify_email_not_yet')), findsOneWidget);
        expect(find.text('kurulum'), findsNothing);
      });

      testWidgets('başka cihazda doğrulandı: "Doğruladım" devam ettiriyor', (
        tester,
      ) async {
        await dogrulamada(tester);
        auth.emailVerified = true;
        await bas(tester, const Key('verify_email_check'));
        expect(find.text('kurulum'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('bağlantı uygulamayı açınca kendiliğinden devam ediyor', (
        tester,
      ) async {
        await dogrulamada(tester);
        await tester.runAsync(
          () => hesap.applyEmailVerification('dogrulama-kodu'),
        );
        await settleAsync(tester);
        expect(find.text('kurulum'), findsOneWidget);
      });

      testWidgets('yanlış kodlu bağlantı doğrulamıyor', (tester) async {
        await dogrulamada(tester);
        await tester.runAsync(() => hesap.applyEmailVerification('baska'));
        await settleAsync(tester);
        expect(find.byKey(const Key('verify_email')), findsOneWidget);
      });

      testWidgets('tekrar gönder bir dakika kapanıyor', (tester) async {
        await dogrulamada(tester);
        await bas(tester, const Key('verify_email_resend'));
        expect(auth.verificationSends, 1);
        final dugme = tester.widget<TextButton>(
          find.byKey(const Key('verify_email_resend')),
        );
        expect(dugme.onPressed, isNull);
      });

      testWidgets('farklı hesapla giriş: oturum kapanıp girişe dönülüyor', (
        tester,
      ) async {
        await dogrulamada(tester);
        await bas(tester, const Key('verify_email_other_account'));
        expect(find.byKey(const Key('sign_in')), findsOneWidget);
        expect(hesap.isSignedIn, isFalse);
      });
    });

    group('şifre yenileme bağlantısı', () {
      Future<BuildContext> yenile(
        WidgetTester tester,
        String kod, {
        Map<String, String> kodlar = const {},
      }) async {
        await tester.runAsync(() => kur(onboarded: false));
        auth.resetCodes.addAll(kodlar);
        await pumpRouter(
          tester,
          routes: const [],
          router: yonlendirici('$resetPasswordPath?code=$kod'),
          userViewModel: user,
          accountViewModel: hesap,
        );
        await settleAsync(tester);
        return tester.element(find.byKey(const Key('reset_password')));
      }

      testWidgets('yeni şifre uygulamada belirleniyor ve giriş yapılıyor', (
        tester,
      ) async {
        final ctx = await yenile(tester, 'k1', kodlar: {'k1': 'ada@ornek.com'});
        expect(find.textContaining('ada@ornek.com'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('reset_password_field')),
          'kisa',
        );
        await bas(tester, const Key('reset_password_submit'));
        expect(find.text(ctx.tr('email_error_password_short')), findsOneWidget);
        expect(auth.newPasswords, isEmpty);

        auth.emailVerified = true;
        await tester.enterText(
          find.byKey(const Key('reset_password_field')),
          'yeni-gizli-sifre',
        );
        await bas(tester, const Key('reset_password_submit'));
        expect(auth.newPasswords, {'ada@ornek.com': 'yeni-gizli-sifre'});
        expect(auth.emailSignIns.last.password, 'yeni-gizli-sifre');
        expect(find.text('kurulum'), findsOneWidget);
      });

      testWidgets('geçersiz bağlantı yeni bağlantı istemeyi söylüyor', (
        tester,
      ) async {
        await yenile(tester, 'yok');
        expect(find.byKey(const Key('reset_password_invalid')), findsOneWidget);
        await bas(tester, const Key('reset_password_back'));
        expect(find.byKey(const Key('sign_in')), findsOneWidget);
      });
    });

    testWidgets('biçim hatasında Firebase\'e gidilmiyor', (tester) async {
      final ctx = await ac(tester);
      await doldur(tester, 'ada', '');
      await bas(tester, const Key('email_submit'));
      expect(find.text(ctx.tr('email_error_invalid_email')), findsOneWidget);
      expect(find.text(ctx.tr('email_error_password_empty')), findsOneWidget);

      // Yeni hesapta kısa şifre de geri çevriliyor.
      await tester.tap(find.text(ctx.tr('email_mode_create')));
      await tester.pumpAndSettle();
      await doldur(tester, 'ada@ornek.com', 'kisa');
      await bas(tester, const Key('email_submit'));
      expect(find.text(ctx.tr('email_error_password_short')), findsOneWidget);

      expect(auth.emailSignIns, isEmpty);
      expect(find.text('kurulum'), findsNothing);
    });

    testWidgets('yanlış şifrede sayfa açık kalıyor, sebep yazıyor', (
      tester,
    ) async {
      final ctx = await ac(tester);
      auth.nextEmailError = EmailAuthError.invalidCredential;
      await doldur(tester, 'ada@ornek.com', 'yanlis-sifre');
      await bas(tester, const Key('email_submit'));

      expect(
        find.descendant(
          of: find.byKey(const Key('email_error')),
          matching: find.text(ctx.tr('email_error_invalid_credential')),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('email_sign_in_sheet')), findsOneWidget);
      expect(find.text('kurulum'), findsNothing);
    });

    testWidgets('şifremi unuttum: önce adres, sonra bağlantı', (tester) async {
      final ctx = await ac(tester);
      await bas(tester, const Key('email_forgot'));
      expect(find.text(ctx.tr('email_reset_need_email')), findsOneWidget);
      expect(auth.resetEmails, isEmpty);

      await tester.enterText(
        find.byKey(const Key('email_field')),
        ' ada@ornek.com ',
      );
      await bas(tester, const Key('email_forgot'));
      expect(auth.resetEmails, ['ada@ornek.com']);
      expect(find.byKey(const Key('email_notice')), findsOneWidget);
      expect(find.text(ctx.tr('email_reset_sent')), findsOneWidget);
    });

    for (final dil in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      testWidgets('$dil: e-posta sayfası küçük ekranda taşmıyor', (
        tester,
      ) async {
        final ctx = await ac(
          tester,
          size: const Size(320, 568),
          locale: Locale(dil),
        );
        await tester.tap(find.text(ctx.tr('email_mode_create')));
        await tester.pumpAndSettle();
        await bas(tester, const Key('email_submit'));
        expect(find.text(ctx.tr('email_error_invalid_email')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
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

  @override
  bool get needsEmailVerification =>
      auth.currentAccount?.needsEmailVerification ?? false;
}
