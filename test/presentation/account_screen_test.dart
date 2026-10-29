import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/data/datasources/remote/account_auth.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/sync_snapshot.dart';
import 'package:period_tracker/domain/view_models/account_view_model.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/account/account_screen.dart';
import 'package:period_tracker/presentation/profile/privacy_security_screen.dart';

import '../support/fake_sync.dart';
import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Hesap ekranı: Apple önce, rıza kutusu işaretlenmeden eşitleme açılmıyor,
/// kapatınca bulut kopyası siliniyor, geri yükleme kurulumu atlıyor ve
/// "Tüm verilerimi sil" doğrulamadan vazgeçilince hiçbir şeyi silmiyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);

  late FakeAccountAuth auth;
  late FakeRemote bulut;

  setUp(() {
    auth = FakeAccountAuth();
    bulut = FakeRemote();
  });

  AccountViewModel hesap() => AccountViewModel(
    auth: auth,
    remote: bulut,
    debounce: const Duration(days: 1),
  );

  final kayit = PeriodLog(
    id: 'p1',
    startDate: daysAgo(30),
    endDate: daysAgo(26),
  );

  Future<BuildContext> ac(
    WidgetTester tester, {
    bool restore = false,
    AccountViewModel? vm,
    UserViewModel? user,
  }) async {
    await pumpRouter(
      tester,
      accountViewModel: vm ?? hesap(),
      userViewModel: user,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => AccountScreen(restore: restore),
        ),
        GoRoute(
          path: '/home',
          name: RouteNames.home,
          builder: (_, _) => const Scaffold(body: Text(homeMarker)),
        ),
        GoRoute(
          path: '/onboarding_goal',
          name: RouteNames.onboardingGoal,
          builder: (_, _) => const Scaffold(body: Text('kurulum')),
        ),
        GoRoute(
          path: '/privacy_policy',
          name: RouteNames.privacyPolicy,
          builder: (_, _) => const Scaffold(body: Text('politika')),
        ),
      ],
    );
    return tester.element(find.byType(AccountScreen));
  }

  /// Rıza sayfasında kutuyu işaretleyip eşitlemeyi açar.
  Future<void> rizaVer(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sync_consent_checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sync_consent_accept')));
    await settleAsync(tester, rounds: 6);
  }

  testWidgets('girişsiz: Apple düğmesi Google\'ın üstünde, veri gitmiyor', (
    tester,
  ) async {
    resetStores();
    await ac(tester);

    final apple = tester.getTopLeft(find.byKey(const Key('account_apple')));
    final google = tester.getTopLeft(find.byKey(const Key('account_google')));
    expect(apple.dy, lessThan(google.dy), reason: 'App Store 4.8');

    await tester.tap(find.byKey(const Key('account_apple')));
    await settleAsync(tester);
    expect(find.byKey(const Key('account_sync_switch')), findsOneWidget);
    expect(bulut.uploads, 0, reason: 'Giriş tek başına veri göndermiyor');
  });

  testWidgets('rıza kutusu işaretlenmeden eşitleme açılmıyor', (tester) async {
    resetStores();
    await const PeriodRepository().savePeriodLogs([kayit]);
    final ctx = await ac(tester);
    await tester.tap(find.byKey(const Key('account_google')));
    await settleAsync(tester);

    await tester.tap(find.byKey(const Key('account_sync_switch')));
    await tester.pumpAndSettle();
    expect(find.text(ctx.tr('sync_consent_title')), findsOneWidget);

    final kabul = tester.widget<FilledButton>(
      find.byKey(const Key('sync_consent_accept')),
    );
    expect(kabul.onPressed, isNull, reason: 'Kutucuk kendiliğinden işaretli');

    await rizaVer(tester);
    expect(bulut.uploads, 1);
    expect(ctx.read<AccountViewModel>().syncEnabled, isTrue);
  });

  testWidgets('rıza sayfasından vazgeçince hiçbir şey gitmiyor', (
    tester,
  ) async {
    resetStores();
    await const PeriodRepository().savePeriodLogs([kayit]);
    final ctx = await ac(tester);
    await tester.tap(find.byKey(const Key('account_apple')));
    await settleAsync(tester);
    await tester.tap(find.byKey(const Key('account_sync_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ctx.tr('cancel')));
    await settleAsync(tester);

    expect(bulut.uploads, 0);
    expect(ctx.read<AccountViewModel>().syncEnabled, isFalse);
  });

  testWidgets('kapatınca buluttaki kopya siliniyor', (tester) async {
    resetStores();
    await const PeriodRepository().savePeriodLogs([kayit]);
    final ctx = await ac(tester);
    await tester.tap(find.byKey(const Key('account_apple')));
    await settleAsync(tester);
    await tester.tap(find.byKey(const Key('account_sync_switch')));
    await rizaVer(tester);

    await tester.tap(find.byKey(const Key('account_sync_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ctx.tr('account_sync_off_action')));
    await settleAsync(tester);

    expect(bulut.data['hesap-1']!.$1.disabled, isTrue);
    expect(bulut.data['hesap-1']!.$2, isEmpty);
    expect(find.text(ctx.tr('account_sync_off_done')), findsOneWidget);
    expect(
      await const PeriodRepository().getPeriodLogs(),
      hasLength(1),
      reason: 'Cihazdaki kayıt duruyor',
    );
  });

  testWidgets('hesap silmede doğrulamadan vazgeçilirse hiçbir şey silinmiyor', (
    tester,
  ) async {
    resetStores();
    final ctx = await ac(tester);
    await tester.tap(find.byKey(const Key('account_apple')));
    await settleAsync(tester);
    auth.reauthOk = false;

    final sil = find.byKey(const Key('account_delete'));
    await tester.scrollUntilVisible(sil, 200);
    await tester.tap(sil);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ctx.tr('account_delete')).last);
    await settleAsync(tester);

    expect(find.text(ctx.tr('account_delete_cancelled')), findsOneWidget);
    expect(ctx.read<AccountViewModel>().isSignedIn, isTrue);
  });

  testWidgets('e-posta hesabını silmek şifre istiyor', (tester) async {
    resetStores();
    final ctx = await ac(tester);
    final eposta = find.byKey(const Key('account_email'));
    await tester.scrollUntilVisible(eposta, 200);
    await tester.ensureVisible(eposta);
    await tester.pumpAndSettle();
    await tester.tap(eposta);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'ada@ornek.com',
    );
    await tester.enterText(
      find.byKey(const Key('password_field')),
      'gizli-sifre',
    );
    await tester.ensureVisible(find.byKey(const Key('email_submit')));
    await tester.tap(find.byKey(const Key('email_submit')));
    await settleAsync(tester);
    expect(find.text(ctx.tr('account_provider_email')), findsOneWidget);

    final sil = find.byKey(const Key('account_delete'));
    Future<void> silmeyiOnayla() async {
      await tester.scrollUntilVisible(sil, 200);
      await tester.tap(sil);
      await tester.pumpAndSettle();
      await tester.tap(find.text(ctx.tr('account_delete')).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account_delete_password')), findsOneWidget);
    }

    // Şifreden vazgeçilirse hiçbir şey silinmiyor.
    await silmeyiOnayla();
    await tester.tap(find.text(ctx.tr('cancel')).last);
    await settleAsync(tester);
    expect(auth.reauthCalls, 0);
    expect(ctx.read<AccountViewModel>().isSignedIn, isTrue);

    await silmeyiOnayla();
    await tester.enterText(
      find.byKey(const Key('account_delete_password')),
      'gizli-sifre',
    );
    await tester.tap(find.text(ctx.tr('account_delete')).last);
    await settleAsync(tester);
    expect(auth.reauthPassword, 'gizli-sifre');
    expect(find.text(ctx.tr('account_delete_done')), findsOneWidget);
    expect(ctx.read<AccountViewModel>().isSignedIn, isFalse);
  });

  group('geri yükleme (yeni cihaz)', () {
    testWidgets('bulutta kayıt varsa kurulum atlanıyor', (tester) async {
      resetStores(onboarded: false);
      final kopya = SyncSnapshot(periodLogs: [kayit]);
      await bulut.upload('hesap-1', kopya.encode(), kopya.hash);
      final user = UserViewModel();

      final ctx = await ac(tester, restore: true, user: user);
      final geldi = ctx.tr('account_restore_done');
      await tester.tap(find.byKey(const Key('account_apple')));
      await rizaVer(tester);

      expect(find.text(homeMarker), findsOneWidget);
      expect(user.onboardingComplete, isTrue);
      expect(await const PeriodRepository().getPeriodLogs(), hasLength(1));
      expect(bulut.uploads, 1, reason: 'Boş cihaz buluta yazmadı');
      expect(find.text(geldi), findsOneWidget);
    });

    testWidgets('bulutta kayıt yoksa kurulum sürüyor', (tester) async {
      resetStores(onboarded: false);
      final user = UserViewModel();

      await ac(tester, restore: true, user: user);
      await tester.tap(find.byKey(const Key('account_google')));
      await rizaVer(tester);

      expect(find.text('kurulum'), findsOneWidget);
      expect(user.onboardingComplete, isFalse);
    });
  });

  testWidgets('"Tüm verilerimi sil": doğrulamadan vazgeçilirse cihazdaki '
      'veri de kalıyor', (tester) async {
    resetStores();
    await const PeriodRepository().savePeriodLogs([kayit]);
    final vm = hesap();
    await pumpRouter(
      tester,
      accountViewModel: vm,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PrivacySecurityScreen()),
        GoRoute(
          path: '/onboarding',
          name: RouteNames.onboarding,
          builder: (_, _) => const Scaffold(body: Text('onboarding')),
        ),
      ],
    );
    await tester.runAsync(() => vm.signIn(AccountProvider.apple));
    await tester.pump();
    auth.reauthOk = false;
    final ctx = tester.element(find.byType(PrivacySecurityScreen));

    final sil = find.text(ctx.tr('privacy_delete_account'));
    await tester.scrollUntilVisible(sil, 300);
    await tester.tap(sil);
    await tester.pumpAndSettle();
    expect(find.text(ctx.tr('privacy_delete_signed_in')), findsOneWidget);
    await tester.tap(find.text(ctx.tr('privacy_delete_confirm')));
    await settleAsync(tester, rounds: 6);

    expect(auth.reauthCalls, 1);
    expect(find.text('onboarding'), findsNothing);
    expect(
      await tester.runAsync(() => const PeriodRepository().getPeriodLogs()),
      hasLength(1),
    );
  });
}
