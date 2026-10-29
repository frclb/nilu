import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:period_tracker/data/repositories/pairing_repository.dart';
import 'package:period_tracker/domain/services/pairing_token.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/partner_match/partner_scan_screen.dart';

import '../support/fake_partner_remote.dart';
import 'screen_harness.dart';

/// Partner davet bağlantısı: tek kullanımlık, bir saatlik, ilk açana bağlı.
///
/// Sunucu tarafı `firebase_tests/rules.test.js`'te ("davet bağlantısı");
/// burada uygulamanın bağlantıyı nasıl işlediği.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);

  const kod = 'ABCDEFGHJKMNPQRSTUVW';

  group('bağlantı', () {
    test('kodun bağlantısı ve geri okunması', () {
      final link = PairingToken.inviteLink(kod);
      expect(link, 'https://frclb.github.io/nilu/p/#$kod');
      expect(PairingToken.fromInviteLink(Uri.parse(link)), kod);
      // Sitedeki "Nilu'da aç" düğmesi.
      expect(PairingToken.fromInviteLink(Uri.parse('nilu://p#$kod')), kod);
      // Mesajda küçük harfe ya da gruplara dönmüş olabilir.
      expect(
        PairingToken.fromInviteLink(
          Uri.parse('https://frclb.github.io/nilu/p/#abcd-efgh-jkmn-pqrs-tuvw'),
        ),
        kod,
      );
    });

    test('başka adres ve bozuk kod kabul edilmiyor', () {
      for (final link in [
        'https://ornek.com/nilu/p/#$kod',
        'https://frclb.github.io/nilu/tr/#$kod',
        'https://frclb.github.io/nilu/p/#ABC',
        'https://frclb.github.io/nilu/p/',
        'nilu://x#$kod',
      ]) {
        expect(
          PairingToken.fromInviteLink(Uri.parse(link)),
          isNull,
          reason: link,
        );
      }
    });
  });

  group('sahip', () {
    test('yeni davet öncekini siliyor; kapatınca kod kalmıyor', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final remote = FakePartnerRemote();
      final pairing = PairingRepository(remote: remote);

      final ilk = await pairing.createInvite('sahip');
      final ikinci = await pairing.createInvite('sahip');
      expect(ilk, isNotNull);
      expect(ikinci, isNot(ilk));
      expect(remote.invites.keys, [ikinci]);
      expect(await pairing.existingInvite(), ikinci);

      await pairing.closeInvite(ikinci!);
      expect(remote.invites, isEmpty);
      expect(await pairing.existingInvite(), isNull);
    });

    test('yayımlanamazsa bağlantı yok', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final remote = FakePartnerRemote(writesSucceed: false);
      expect(
        await PairingRepository(remote: remote).createInvite('sahip'),
        isNull,
      );
    });
  });

  group('bağlantıyı açan partner', () {
    late FakePartnerRemote remote;

    Future<BuildContext> ac(WidgetTester tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final user = UserViewModel(auth: _Hesap('ben'), firestore: remote);
      await pumpRouter(
        tester,
        userViewModel: user,
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                PartnerScanScreen(remote: remote, initialCode: kod),
          ),
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            builder: (_, _) => const Scaffold(body: Text('ana ekran')),
          ),
        ],
      );
      return tester.element(find.byType(PartnerScanScreen));
    }

    setUp(() => remote = FakePartnerRemote()..tokens[kod] = 'sahip');

    testWidgets('kod kendiliğinden işleniyor; onaylayınca bağlantı bu '
        'kişiye bağlanıyor', (tester) async {
      remote.invites[kod] = (createdAt: DateTime.now(), usedBy: null);
      final context = await ac(tester);
      expect(
        find.text(context.tr('partner_scan_success_title')),
        findsOneWidget,
        reason: 'Bağlantıdan gelen kod onay sayfasını açmalı',
      );

      await tester.tap(find.text(context.tr('partner_scan_confirm')));
      await settleAsync(tester);
      expect(remote.calls, contains('requestPairing+claim'));
      expect(remote.invites[kod]?.usedBy, 'ben');
      expect(find.text('ana ekran'), findsOneWidget);
    });

    testWidgets('kullanılmış bağlantı reddediliyor', (tester) async {
      remote.invites[kod] = (createdAt: DateTime.now(), usedBy: 'baskasi');
      final context = await ac(tester);
      expect(find.text(context.tr('partner_scan_error_used')), findsOneWidget);
      expect(find.text(context.tr('partner_scan_success_title')), findsNothing);
      expect(remote.calls, isNot(contains('requestPairing+claim')));
    });

    testWidgets('süresi dolmuş bağlantı reddediliyor', (tester) async {
      remote.invites[kod] = (
        createdAt: DateTime.now().subtract(const Duration(minutes: 61)),
        usedBy: null,
      );
      final context = await ac(tester);
      expect(
        find.text(context.tr('partner_scan_error_expired')),
        findsOneWidget,
      );
      expect(find.text(context.tr('partner_scan_success_title')), findsNothing);
    });

    testWidgets('QR kodu bağlantı gibi işaretlenmiyor', (tester) async {
      final context = await ac(tester);
      expect(
        find.text(context.tr('partner_scan_success_title')),
        findsOneWidget,
      );
      await tester.tap(find.text(context.tr('partner_scan_confirm')));
      await settleAsync(tester);
      expect(remote.calls, contains('requestPairing'));
      expect(remote.calls, isNot(contains('requestPairing+claim')));
    });
  });
}

class _Hesap extends FirebaseAuthDataSource {
  _Hesap(this.uid);

  final String uid;

  @override
  String? get accountUid => uid;
}
