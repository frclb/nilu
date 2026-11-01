import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/datasources/remote/account_auth.dart';
import 'package:period_tracker/domain/view_models/account_view_model.dart';
import 'package:period_tracker/presentation/home/widgets/home_header.dart';

import '../support/fake_sync.dart';
import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Ad hesaptan geliyor; giriş ve çıkışta ekrandaki ad hemen değişiyor.
///
/// Sekmeler açık kalıyor ve adı yalnızca ilk açılışta okuyordu: çıkıştan
/// sonra önceki kişinin adı, uygulama yeniden başlayana kadar ana ekranda
/// duruyordu.
void main() {
  setUpAll(mockMissingPlatformChannels);

  testWidgets('çıkışta selamlamadan ad kalkıyor, girişte geliyor', (
    tester,
  ) async {
    resetStores(onboarded: true);
    final auth = FakeAccountAuth()..nextDisplayName = 'Ada Yılmaz';
    final hesap = AccountViewModel(
      auth: auth,
      remote: FakeRemote(),
      debounce: const Duration(days: 1),
    );

    // `wrapWithProviders` hesabı kendisi kuruyor; burada sahte hesap
    // gerekiyor, o yüzden ekranın üstüne ayrıca veriliyor.
    await pumpScreen(
      tester,
      ChangeNotifierProvider<AccountViewModel>.value(
        value: hesap,
        child: const Scaffold(body: HomeHeader()),
      ),
      size: const Size(390, 844),
    );

    await tester.runAsync(() => hesap.signIn(AccountProvider.apple));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.text('Ada Yılmaz'), findsOneWidget);

    await tester.runAsync(hesap.signOut);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.text('Ada Yılmaz'), findsNothing, reason: 'eski ad kaldı');
  });
}
