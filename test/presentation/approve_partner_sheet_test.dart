import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/partner_match/widgets/approve_partner_sheet.dart';

import 'screen_harness.dart';

/// Sahip partnerini onaylarken neyi paylaştığını görüyor mu?
///
/// TestFlight bulgusu: onay erişimi veriyordu ama sahip partnerin neyi
/// göreceğini görmüyordu; onaydan sonra da hiçbir şey gitmiyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);

  const sayfa = Key('partner_approve_sheet');

  /// Sayfayı açar; kapanınca kararı listeye ekler.
  Future<List<ApproveDecision?>> ac(
    WidgetTester tester, {
    required bool consentGiven,
    String? sexualDesire,
    List<String> affectionNeeds = const ['attention'],
    Size size = const Size(390, 844),
    Locale locale = const Locale('tr'),
  }) async {
    await pumpScreen(
      tester,
      const Scaffold(body: SizedBox.expand()),
      size: size,
      locale: locale,
    );
    final kararlar = <ApproveDecision?>[];
    showApprovePartnerSheet(
      tester.element(find.byType(Scaffold)),
      code: '1234',
      sexualDesire: sexualDesire,
      affectionNeeds: affectionNeeds,
      consentGiven: consentGiven,
    ).then(kararlar.add);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(find.byKey(sayfa), findsOneWidget);
    return kararlar;
  }

  Future<void> bas(WidgetTester tester, String key) async {
    final hedef = find.byKey(Key(key));
    await tester.ensureVisible(hedef);
    await tester.pump();
    await tester.tap(hedef);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  testWidgets('seçimler görünüyor, değiştiriliyor ve paylaşılıyor', (
    tester,
  ) async {
    final kararlar = await ac(tester, consentGiven: false);
    final context = tester.element(find.byKey(sayfa));

    // Mevcut seçim işaretli; neyin gitmediği ve rızanın maddeleri yazıyor.
    expect(
      tester
          .widget<FilterChip>(
            find.byKey(const Key('partner_approve_attention')),
          )
          .selected,
      isTrue,
    );
    expect(find.text(context.tr('partner_approve_not_shared')), findsOneWidget);
    expect(find.text(context.tr('consent_special')), findsOneWidget);

    await bas(tester, 'partner_approve_feel_closer');
    await bas(tester, 'partner_approve_hug');
    await bas(tester, 'partner_approve_share');

    final karar = kararlar.single!;
    expect(karar.share, isTrue);
    expect(karar.sexualDesire, 'feel_closer');
    expect(karar.affectionNeeds, ['attention', 'hug']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('seçili istek ikinci dokunuşta kalkıyor; boşsa söyleniyor', (
    tester,
  ) async {
    final kararlar = await ac(
      tester,
      consentGiven: true,
      sexualDesire: 'passionate',
      affectionNeeds: const [],
    );
    expect(find.byKey(const Key('partner_approve_nothing')), findsNothing);
    await bas(tester, 'partner_approve_passionate');
    expect(find.byKey(const Key('partner_approve_nothing')), findsOneWidget);
    await bas(tester, 'partner_approve_share');
    expect(kararlar.single!.sexualDesire, isNull);
  });

  testWidgets('rıza önceden verildiyse maddeler tekrar edilmiyor; '
      'paylaşmadan onaylanabiliyor', (tester) async {
    final kararlar = await ac(tester, consentGiven: true);
    final context = tester.element(find.byKey(sayfa));
    expect(find.text(context.tr('consent_special')), findsNothing);

    await bas(tester, 'partner_approve_only');
    expect(kararlar.single!.share, isFalse);
  });

  for (final dil in ['de', 'fr']) {
    testWidgets('$dil: küçük ekranda taşmıyor', (tester) async {
      await ac(
        tester,
        consentGiven: false,
        size: const Size(320, 568),
        locale: Locale(dil),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
