import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/share_settings_repository.dart';
import 'package:period_tracker/domain/services/pairing_token.dart';
import 'package:period_tracker/domain/view_models/partner_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/home/widgets/intimacy_section.dart';
import 'package:period_tracker/presentation/partner_match/partner_dashboard_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_match_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_support_screen.dart';

import '../support/fake_partner_remote.dart';
import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Partner ekranları gerçekte olanı söylüyor mu?
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  void hazirla(Map<String, Object> prefs) {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      ...prefs,
    });
  }

  group('sahip', () {
    testWidgets('sunucu yokken davet yerine nedeni yazıyor', (tester) async {
      hazirla({});
      final screen = PartnerMatchScreen(
        remote: FakePartnerRemote(available: false),
      );
      await pumpScreen(tester, screen, size: const Size(390, 844));
      expect(find.byKey(const Key('partner_unavailable')), findsOneWidget);
      expect(find.byKey(const Key('partner_invite')), findsNothing);
      expect(find.byKey(const Key('partner_scan')), findsNothing);
    });

    testWidgets('sunucu varken davet edilebiliyor', (tester) async {
      hazirla({});
      final screen = PartnerMatchScreen(remote: FakePartnerRemote());
      await pumpScreen(tester, screen, size: const Size(390, 844));
      expect(find.byKey(const Key('partner_unavailable')), findsNothing);
      expect(find.byKey(const Key('partner_invite')), findsOneWidget);
    });

    testWidgets(
      'bağlıyken doğrulama kodu ve erişimi kaldırma var, kimlik yok',
      (tester) async {
        const partner = 'k3Jd9QzLm2Xp7Rt4Vb8Nc1Ys6Ae0';
        hazirla({'myId': 'sahip', 'partnerId': partner, 'hasPartner': true});
        final screen = PartnerMatchScreen(remote: FakePartnerRemote());
        await pumpScreen(tester, screen, size: const Size(390, 844));

        expect(find.byKey(const Key('connected_partner_card')), findsOneWidget);
        expect(find.byKey(const Key('partner_invite')), findsNothing);
        expect(find.byKey(const Key('partner_remove')), findsOneWidget);
        expect(
          find.textContaining(PairingToken.confirmationCode(partner)),
          findsOneWidget,
        );
        expect(find.textContaining(partner), findsNothing);
      },
    );

    testWidgets('paylaşım kapalı başlıyor; rıza vermeden açılmıyor', (
      tester,
    ) async {
      hazirla({'myId': 'sahip', 'partnerId': 'partner', 'hasPartner': true});
      final screen = PartnerMatchScreen(remote: FakePartnerRemote());
      await pumpScreen(tester, screen, size: const Size(390, 844));
      final ctx = tester.element(find.byWidget(screen));

      Switch anahtar() =>
          tester.widget<Switch>(find.byKey(const Key('partner_share_switch')));
      expect(anahtar().value, isFalse);

      await tester.ensureVisible(find.byKey(const Key('partner_share_switch')));
      await tester.tap(find.byKey(const Key('partner_share_switch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('intimacy_consent_dialog')), findsOneWidget);
      expect(find.text(ctx.tr('consent_special')), findsOneWidget);

      await tester.tap(find.text(ctx.tr('cancel')));
      await tester.pumpAndSettle();
      expect(anahtar().value, isFalse, reason: 'Rıza verilmedi');

      await tester.tap(find.byKey(const Key('partner_share_switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('intimacy_consent_accept')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      expect(anahtar().value, isTrue);
      expect(
        await tester.runAsync(
          () => const ShareSettingsRepository().consentedAt(),
        ),
        isNotNull,
      );
    });
  });

  group('ana ekrandaki yakınlık kartı', () {
    Future<void> ac(WidgetTester tester) => pumpScreen(
      tester,
      const Scaffold(body: SingleChildScrollView(child: IntimacySection())),
      size: const Size(390, 844),
    );

    Finder kart(WidgetTester tester) => find.text(
      tester
          .element(find.byType(IntimacySection))
          .tr('intimacy_sexual_desire_title'),
    );

    testWidgets('partner yokken görünmüyor', (tester) async {
      hazirla({});
      await ac(tester);
      expect(kart(tester), findsNothing);
    });

    testWidgets('partner var ama rıza yokken görünmüyor', (tester) async {
      hazirla({'myId': 'sahip', 'partnerId': 'partner', 'hasPartner': true});
      await ac(tester);
      expect(kart(tester), findsNothing);
    });

    testWidgets('partner ve rıza varken görünüyor', (tester) async {
      hazirla({
        'myId': 'sahip',
        'partnerId': 'partner',
        'hasPartner': true,
        ShareSettingsRepository.consentKey: '2026-10-08T10:00:00.000',
        ShareSettingsRepository.intimacyKey: true,
      });
      await ac(tester);
      expect(kart(tester), findsOneWidget);
    });
  });

  group('partner', () {
    testWidgets('onay beklerken kendi doğrulama kodunu görüyor', (
      tester,
    ) async {
      hazirla({
        'myId': 'partner-uid',
        'isPartner': true,
        'partnerId': 'sahip',
        'hasPartner': true,
      });
      // Onaydan önce kurallar okumayı reddediyor.
      final remote = FakePartnerRemote()
        ..statusStream = (_) => Stream.error(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
      const screen = PartnerDashboardScreen();
      await pumpScreen(
        tester,
        screen,
        size: const Size(390, 844),
        partnerViewModel: PartnerViewModel(
          firestore: remote,
          retryInterval: const Duration(hours: 1),
        ),
      );
      expect(find.byKey(const Key('pv_awaiting')), findsOneWidget);
      expect(
        find.textContaining(PairingToken.confirmationCode('partner-uid')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('pv_leave')), findsOneWidget);
    });

    testWidgets('rehber uydurma döngü bilgisi göstermiyor', (tester) async {
      hazirla({'isPartner': true, 'partnerId': 'sahip'});
      const screen = PartnerSupportScreen();
      await pumpScreen(tester, screen, size: const Size(390, 844));
      final ctx = tester.element(find.byWidget(screen));
      expect(find.text(ctx.tr('partner_guide_intro')), findsOneWidget);
      // Eski ekran "1. GÜN", "2,5 L" ve hormon düzeyi yazıyordu.
      expect(find.textContaining('2,5 L'), findsNothing);
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  });
}
