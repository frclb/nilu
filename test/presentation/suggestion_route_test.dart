import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/services/phase_guide.dart';
import 'package:period_tracker/domain/services/session_plan.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/home/widgets/daily_suggestion_card.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Günün önerisi yalnızca uygulamada gerçekten olanı vaat etmeli.
///
/// Foliküler evrede "Enerji Artıran Egzersiz · 25 dk", yumurtlamada
/// "Yüksek Yoğunluklu Antrenman · 30 dk" yazıyordu; "Başla" ikisinde de
/// "Menstrüasyon Dönemi İçin · Hafif Akış Yogası" ekranını açıyordu.
/// Uygulamadaki tek rehberli seans yoga akışı (`SessionPlan.yoga`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  test('güç ve kardiyo için seans yok; yumuşak türlerde yoga var', () {
    expect(PhaseActivity.strength.hasSession, isFalse);
    expect(PhaseActivity.cardio.hasSession, isFalse);
    for (final a in [
      PhaseActivity.yinYoga,
      PhaseActivity.gentle,
      PhaseActivity.meditation,
    ]) {
      expect(a.hasSession, isTrue, reason: a.name);
    }
  });

  Future<BuildContext> kart(WidgetTester tester, int lastStartAgo) async {
    await seedCycles(lastStartAgo: lastStartAgo);
    await pumpScreen(
      tester,
      const Scaffold(body: SingleChildScrollView(child: DailySuggestionCard())),
      size: const Size(390, 844),
    );
    return tester.element(find.byType(DailySuggestionCard));
  }

  testWidgets('foliküler evrede süre ve "Başla" yok', (tester) async {
    // 28 günlük döngünün 8. günü: foliküler.
    final ctx = await kart(tester, 7);
    final guide = PhaseGuide.forPhase(CyclePhase.follicular);
    expect(find.text(ctx.tr(guide.activityTitleKey)), findsOneWidget);
    expect(find.byKey(const Key('suggestion_start')), findsNothing);
    expect(find.byIcon(Icons.schedule), findsNothing);
  });

  testWidgets('regl döneminde süre seansın kendisinden', (tester) async {
    final ctx = await kart(tester, 1);
    final guide = PhaseGuide.forPhase(CyclePhase.menstruation);
    expect(find.text(ctx.tr(guide.activityTitleKey)), findsOneWidget);
    expect(find.byKey(const Key('suggestion_start')), findsOneWidget);
    expect(
      find.text(
        ctx.tr(
          'duration_minutes',
          params: {'n': '${SessionPlan.yoga.total.inMinutes}'},
        ),
      ),
      findsOneWidget,
    );
  });
}
