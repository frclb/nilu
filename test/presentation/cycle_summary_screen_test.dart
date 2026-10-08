import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/insights/cycle_summary_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

class _Abone extends SubscriptionViewModel {
  _Abone({required this.premium});
  final bool premium;

  @override
  bool get isPremium => premium;

  @override
  bool get isLoading => false;
}

/// Hekim özeti ekranda ücretsiz; dosya olarak paylaşmak Premium.
///
/// Önceden özet yalnızca Premium dışa aktarmanın içindeydi: muayenede
/// döngüsünü soran hekime ücretsiz kullanıcının gösterecek bir şeyi yoktu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  final paylasilan = <(String, String)>[];
  setUp(() {
    paylasilan.clear();
    CycleSummaryScreen.share = (metin, ad) async => paylasilan.add((metin, ad));
  });

  Future<void> veri() async {
    await seedCycles();
    await const PeriodRepository().saveDailyLogs([
      DailyLog(
        date: daysAgo(20),
        flowIntensity: 'heavy',
        painLevel: 'severe',
        painLimitedActivity: true,
      ),
    ]);
  }

  for (final boyut in screenSizes.entries) {
    testWidgets('ücretsiz kullanıcı özeti görüyor — ${boyut.key}', (
      tester,
    ) async {
      await veri();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const CycleSummaryScreen()),
        size: boyut.value,
        subscriptionViewModel: _Abone(premium: false),
      );
      final ctx = tester.element(find.byType(CycleSummaryScreen));
      expect(tester.takeException(), isNull, reason: 'düzen hatası');
      expect(
        find.text(ctx.tr('export_section_clinical'), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(ctx.tr('export_section_cycles'), skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(
          ctx.tr('export_clinical_limited', params: {'n': '1'}),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets('ücretsiz kullanıcı paylaşınca Premium açılıyor', (tester) async {
    await veri();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CycleSummaryScreen()),
      subscriptionViewModel: _Abone(premium: false),
    );
    await tester.tap(find.byKey(const Key('cycle_summary_share')));
    await settleAsync(tester);
    expect(find.text(premiumMarker), findsOneWidget);
    expect(paylasilan, isEmpty);
  });

  testWidgets('Premium paylaşınca ekrandaki bölümler dosyada', (tester) async {
    await veri();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CycleSummaryScreen()),
      subscriptionViewModel: _Abone(premium: true),
    );
    final ctx = tester.element(find.byType(CycleSummaryScreen));
    await tester.tap(find.byKey(const Key('cycle_summary_share')));
    await settleAsync(tester);
    expect(paylasilan, hasLength(1));
    final (metin, ad) = paylasilan.single;
    expect(ad, startsWith('dongu-ozeti-'));
    expect(metin, contains(ctx.tr('export_section_clinical')));
    expect(
      metin,
      contains(ctx.tr('export_clinical_limited', params: {'n': '1'})),
    );
  });
}
