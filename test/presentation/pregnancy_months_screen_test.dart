import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/models/pregnancy_month.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/pregnancy/care_text.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_months_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Ay ay gebelik: dokuz ay, her ayın haftaları, tarihleri ve kontrolleri.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Finder ay(int n) => find.byKey(Key('preg_month_$n'), skipOffstage: false);

  Finder ayda(int n, String metin) => find.descendant(
    of: ay(n),
    matching: find.text(metin, skipOffstage: false),
  );

  Future<void> goster(WidgetTester tester, int n) async {
    await tester.scrollUntilVisible(find.byKey(Key('preg_month_$n')), 200);
  }

  for (final boyut in screenSizes.entries) {
    testWidgets('24+2 haftalık gebe — ${boyut.key}', (tester) async {
      await seedPregnancy(weeks: 24, days: 2);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PregnancyMonthsScreen()),
        size: boyut.value,
      );
      expect(find.byType(PregnancyMonthsScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'düzen hatası');
      final ctx = tester.element(find.byType(PregnancyMonthsScreen));

      for (var n = 1; n <= 9; n++) {
        await goster(tester, n);
        expect(ay(n), findsOneWidget, reason: '$n. ay yok');
        expect(ayda(n, ctx.monthLabel(n)), findsOneWidget);
      }
      await goster(tester, 6);
      expect(
        ayda(6, ctx.upper(ctx.tr('care_group_now'))),
        findsOneWidget,
        reason: '24+2 altıncı ay',
      );
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets('kontroller kendi aylarında; yapılanlar işaretli', (
    tester,
  ) async {
    final g = await seedPregnancy(weeks: 24, days: 2);
    final kalemler = await const CareRepository().getAll();
    final ikinci = kalemler.firstWhere((e) => e.code == 'tr_visit_2');
    await const CareRepository().upsert(ikinci.copyWith(done: true));

    // Uzun ekran: dokuz ay birden çiziliyor, kaydırma gerekmiyor.
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancyMonthsScreen()),
      size: const Size(390, 4200),
    );
    final ctx = tester.element(find.byType(PregnancyMonthsScreen));
    final vm = ctx.read<PregnancyViewModel>();

    // Her şablon kalemi pencere başına göre tam olarak bir aya düşüyor.
    for (final e in vm.currentEvents) {
      if (e.anchor == CareAnchor.postpartum) continue;
      final m = PregnancyMonthsScreen.monthOf(e, g);
      expect(m, isNotNull, reason: e.code);
      expect(
        ayda(m!.number, ctx.careTitle(e)),
        findsOneWidget,
        reason: '${e.code} ${m.number}. ayda görünmeli',
      );
    }

    // 2. izlem (18. haftada başlıyor) 5. ayda ve yapıldı işaretli.
    expect(
      PregnancyMonthsScreen.monthOf(ikinci, g)!.number,
      PregnancyMonth.of(const GestationalAge(18, 0)).number,
    );
    final satir = find.ancestor(
      of: ayda(5, ctx.careTitle(ikinci)),
      matching: find.byType(Row),
    );
    expect(
      find.descendant(
        of: satir.first,
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('randevusu olan kendi kalemi randevusunun ayında', (
    tester,
  ) async {
    final g = await seedPregnancy(weeks: 24, days: 2);
    // 8. ayın içinde bir gün.
    final tarih = PregnancyMonth.all[7].startIn(g).add(const Duration(days: 3));
    await const CareRepository().upsert(
      CareEvent.custom(
        pregnancyId: g.id,
        title: 'Diş kontrolü',
        scheduledAt: tarih,
      ),
    );
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancyMonthsScreen()),
      size: const Size(390, 4200),
    );
    expect(ayda(8, 'Diş kontrolü'), findsOneWidget);
  });
}
