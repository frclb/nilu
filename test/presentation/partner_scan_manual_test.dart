import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:period_tracker/domain/services/pairing_token.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/partner_match/partner_scan_screen.dart';

import '../support/fake_partner_remote.dart';
import 'screen_harness.dart';

/// Eşleşme kodu elle yazılabiliyor mu?
///
/// TestFlight bulgusu: "manuel ekleme yapılmıyor". Davet ekranı kodun
/// tamamını "kamera çalışmazsa elle yazılsın" diye gösteriyordu ama okutma
/// ekranında yazılacak bir yer yoktu; kamera izni reddedilmişse eşleşmenin
/// hiçbir yolu kalmıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  const kod = 'ABCDEFGHJKMNPQRSTUVW';

  Future<FakePartnerRemote> ac(WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final remote = FakePartnerRemote()..tokens[kod] = 'sahip';
    final user = UserViewModel(auth: _Hesap('ben'), firestore: remote);
    await pumpScreen(
      tester,
      PartnerScanScreen(remote: remote),
      size: const Size(390, 844),
      userViewModel: user,
    );
    expect(find.byKey(const Key('partner_scan_manual')), findsOneWidget);
    await tester.tap(find.byKey(const Key('partner_scan_manual')));
    // Sayfa aşağıdan kayarak açılıyor; bitene kadar düğmeler ekran dışında.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.byKey(const Key('partner_scan_manual_field')), findsOneWidget);
    return remote;
  }

  testWidgets('elle yazılan kod çözülüyor ve onay soruluyor', (tester) async {
    final remote = await ac(tester);
    final context = tester.element(find.byType(PartnerScanScreen));

    // Mesajla gelmiş gibi: küçük harf, tireli.
    await tester.enterText(
      find.byKey(const Key('partner_scan_manual_field')),
      'abcd-efgh jkmn-pqrs tuvw',
    );
    await tester.tap(find.byKey(const Key('partner_scan_manual_submit')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(remote.calls, contains('resolvePairingToken'));
    expect(
      find.text(context.tr('partner_scan_success_title')),
      findsOneWidget,
      reason: 'Geçerli kod onay sayfasına götürmeli',
    );
    expect(find.text(PairingToken.forDisplay(kod)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('biçimi bozuk kod sunucuya gitmeden reddediliyor', (
    tester,
  ) async {
    final remote = await ac(tester);
    final context = tester.element(find.byType(PartnerScanScreen));

    await tester.enterText(
      find.byKey(const Key('partner_scan_manual_field')),
      'ABC123',
    );
    await tester.tap(find.byKey(const Key('partner_scan_manual_submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(context.tr('partner_scan_manual_invalid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('partner_scan_manual_field')),
      findsOneWidget,
      reason: 'Sayfa açık kalmalı ki kullanıcı düzeltebilsin',
    );
    expect(remote.calls, isNot(contains('resolvePairingToken')));
    expect(tester.takeException(), isNull);
  });
}

class _Hesap extends FirebaseAuthDataSource {
  _Hesap(this.uid);

  final String uid;

  @override
  String? get accountUid => uid;
}
