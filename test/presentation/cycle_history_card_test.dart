import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/insights/widgets/cycle_history_card.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Bütün döngülerin listesi ve ortalaması herkese açık.
///
/// Ücretsiz kullanıcı önceden yalnızca son üç döngüyü görebiliyordu.
/// Kart abonelik bilgisi okumuyor; harness'teki abonelik varsayılan olarak
/// ücretsiz.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Future<BuildContext> ac(WidgetTester tester, List<PeriodLog> regller) async {
    await const PeriodRepository().savePeriodLogs(regller);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(
        const Scaffold(body: SingleChildScrollView(child: CycleHistoryCard())),
      ),
      size: const Size(390, 2400),
    );
    return tester.element(find.byType(CycleHistoryCard));
  }

  // Dokuz regl, sekiz tamamlanmış döngü: 28, 30, 26, 28, 31, 27, 29, 28.
  const araliklar = [28, 30, 26, 28, 31, 27, 29, 28];
  List<PeriodLog> regller() {
    var bas = daysAgo(400);
    final sonuc = <PeriodLog>[];
    for (var i = 0; i <= araliklar.length; i++) {
      sonuc.add(
        PeriodLog(
          id: 'p$i',
          startDate: bas,
          endDate: DateTime(bas.year, bas.month, bas.day + 4),
        ),
      );
      if (i < araliklar.length) {
        bas = DateTime(bas.year, bas.month, bas.day + araliklar[i]);
      }
    }
    return sonuc;
  }

  Finder satirlar() => find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('cycle_history_row_'),
  );

  testWidgets('ücretsiz kullanıcı bütün döngüleri ve ortalamayı görüyor', (
    tester,
  ) async {
    final ctx = await ac(tester, regller());
    expect(
      find.text(
        ctx.tr(
          'insights_history_stats',
          params: {'count': '8', 'avg': '28', 'min': '26', 'max': '31'},
        ),
      ),
      findsOneWidget,
    );
    expect(satirlar(), findsNWidgets(CycleHistoryCard.collapsedCount));

    await tester.tap(find.byKey(const Key('cycle_history_show_all')));
    await tester.pump();
    expect(satirlar(), findsNWidgets(8), reason: 'Kilit yok, hepsi açılıyor');
    expect(find.byKey(const Key('cycle_history_show_all')), findsNothing);
  });

  testWidgets('en yeni döngü üstte; regl süresi kayıtlıysa yazıyor', (
    tester,
  ) async {
    final ctx = await ac(tester, regller());
    final enYeniBas = regller()[7].startDate;
    expect(
      tester.getTopLeft(satirlar().first).dy,
      tester
          .getTopLeft(
            find.byKey(
              Key(
                'cycle_history_row_${enYeniBas.year}-${enYeniBas.month}-'
                '${enYeniBas.day}',
              ),
            ),
          )
          .dy,
    );
    expect(
      find.text(ctx.tr('insights_history_period', params: {'days': '5'})),
      findsWidgets,
    );
  });

  testWidgets('tek regl varken kart hiç çizilmiyor', (tester) async {
    await ac(tester, [PeriodLog(id: 'a', startDate: daysAgo(10))]);
    expect(find.byKey(const Key('cycle_history_card')), findsNothing);
  });
}
