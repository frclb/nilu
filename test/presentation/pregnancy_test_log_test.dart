import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/privacy_settings_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/domain/services/data_export_service.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/day_detail_bottom_sheet.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_masthead.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_setup_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gebelik testi kaydı.
///
/// Gecikmede kullanıcının ilk yaptığı şey çoğu zaman bir ev testi; sonucun
/// yazılacak yeri yoktu. Pozitif sonuç gebelik takibine **öneriyle**
/// bağlanıyor, evreyi kendiliğinden değiştirmiyor: yanlış pozitif ve erken
/// kayıp mümkün, kurulum zaten tarihleri soruyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Future<CalendarViewModel> sayfayiAc(WidgetTester tester, DateTime gun) async {
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DayDetailBottomSheet(date: gun),
                ),
                child: const Text('ac'),
              ),
            ),
          ),
        ),
      ),
    );
    final takvim = tester.element(find.text('ac')).read<CalendarViewModel>();
    await tester.tap(find.text('ac'));
    await settleAsync(tester);
    return takvim;
  }

  Future<void> dokun(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await settleAsync(tester);
  }

  Finder secenek(String kod) => find.byKey(Key('day_detail_preg_test_$kod'));
  final kart = find.byKey(const Key('day_detail_preg_test_positive_card'));

  group('gün sayfası', () {
    testWidgets('pozitif: kaydediliyor, öneri çıkıyor; evre kendiliğinden '
        'değişmiyor', (tester) async {
      await seedCycles(lastStartAgo: 33);
      final takvim = await sayfayiAc(tester, today);

      await dokun(tester, secenek('positive'));
      expect(takvim.getDailyLogForDate(today).pregnancyTest, 'positive');
      expect(kart, findsOneWidget);
      expect(takvim.lifeStage, LifeStage.cycle);

      await dokun(tester, find.byKey(const Key('day_detail_preg_test_start')));
      expect(find.byType(PregnancySetupScreen), findsOneWidget);
      expect(
        tester
            .element(find.byType(PregnancySetupScreen))
            .read<PregnancyViewModel>()
            .stage,
        LifeStage.cycle,
        reason: 'Gebelik ancak kurulum tamamlanınca açılmalı',
      );
    });

    testWidgets('seçili sonuca yeniden dokununca kalkıyor', (tester) async {
      await seedCycles(lastStartAgo: 33);
      final takvim = await sayfayiAc(tester, daysAgo(1));

      await dokun(tester, secenek('positive'));
      await dokun(tester, secenek('positive'));
      expect(takvim.getDailyLogForDate(daysAgo(1)).pregnancyTest, isNull);
      expect(kart, findsNothing);
    });

    testWidgets('negatif ve belirsizde öneri yok', (tester) async {
      await seedCycles(lastStartAgo: 33);
      final takvim = await sayfayiAc(tester, today);

      await dokun(tester, secenek('negative'));
      expect(takvim.getDailyLogForDate(today).pregnancyTest, 'negative');
      expect(kart, findsNothing);

      await dokun(tester, secenek('unclear'));
      expect(takvim.getDailyLogForDate(today).pregnancyTest, 'unclear');
      expect(kart, findsNothing);
    });

    testWidgets('gebelikte bölüm yok', (tester) async {
      await seedPregnancy();
      await sayfayiAc(tester, today);
      expect(secenek('positive'), findsNothing);
    });

    testWidgets('gelecek güne test sonucu girilemiyor', (tester) async {
      await seedCycles(lastStartAgo: 10);
      await sayfayiAc(tester, today.add(const Duration(days: 3)));
      expect(secenek('positive'), findsNothing);
    });

    testWidgets('cinsel aktivite seçimi geri alınabiliyor', (tester) async {
      await seedCycles(lastStartAgo: 10);
      await tester.runAsync(
        () => const PrivacySettingsRepository().setSexualActivityLogging(true),
      );
      final takvim = await sayfayiAc(tester, daysAgo(1));
      final ctx = tester.element(find.byType(DayDetailBottomSheet));
      final korunmali = find.text(
        ctx.tr(LogVocabulary.sexualActivityKey('protected')),
      );

      await dokun(tester, korunmali);
      expect(takvim.getDailyLogForDate(daysAgo(1)).sexualActivity, 'protected');

      await dokun(tester, korunmali);
      expect(
        takvim.getDailyLogForDate(daysAgo(1)).sexualActivity,
        isNull,
        reason: 'Seçim geri alınamıyordu',
      );
    });
  });

  group('cinsel aktivite alanı (gizlilik)', () {
    String baslik(WidgetTester tester) => tester
        .element(find.byType(DayDetailBottomSheet))
        .tr('day_detail_sexual_activity');

    testWidgets('varsayılan olarak gizli', (tester) async {
      await seedCycles(lastStartAgo: 10);
      await sayfayiAc(tester, daysAgo(1));
      expect(find.text(baslik(tester)), findsNothing);
    });

    testWidgets('Gizlilik\'te açılınca görünüyor', (tester) async {
      await seedCycles(lastStartAgo: 10);
      await tester.runAsync(
        () => const PrivacySettingsRepository().setSexualActivityLogging(true),
      );
      await sayfayiAc(tester, daysAgo(1));
      expect(find.text(baslik(tester)), findsOneWidget);
    });

    testWidgets('o günün kaydı varsa ayar kapalıyken de görünüyor', (
      tester,
    ) async {
      await seedCycles(lastStartAgo: 10);
      await tester.runAsync(
        () => const PeriodRepository().saveDailyLogs([
          DailyLog(date: daysAgo(1), sexualActivity: 'protected'),
        ]),
      );
      await sayfayiAc(tester, daysAgo(1));
      expect(
        find.text(baslik(tester)),
        findsOneWidget,
        reason: 'Kayıtlı değer görünmez olursa düzeltilemez',
      );
    });
  });

  group('ana ekran gecikme notu', () {
    Future<void> masthead(WidgetTester tester) => pumpRouter(
      tester,
      routes: pregnancyRoutes(
        const Scaffold(body: SingleChildScrollView(child: CycleMasthead())),
      ),
    );

    testWidgets('gecikmede not ve bugünü açan düğme', (tester) async {
      await seedCycles(lastStartAgo: 32);
      await masthead(tester);

      expect(find.byKey(const Key('home_late_note')), findsOneWidget);
      await dokun(tester, find.byKey(const Key('home_late_log_today')));

      final sayfa = tester.widget<DayDetailBottomSheet>(
        find.byType(DayDetailBottomSheet),
      );
      expect(sayfa.date, today);
      expect(secenek('positive'), findsOneWidget);
    });

    testWidgets('gecikme yokken not yok', (tester) async {
      await seedCycles(lastStartAgo: 10);
      await masthead(tester);
      expect(find.byKey(const Key('home_late_note')), findsNothing);
    });
  });

  group('kayıt ve dışa aktarma', () {
    test('gidiş-dönüşte korunuyor, tanınmayan değer düşüyor', () {
      final log = DailyLog(
        date: DateTime(2026, 3, 4),
        pregnancyTest: 'positive',
      );
      expect(DailyLog.fromJson(log.toJson()).pregnancyTest, 'positive');
      expect(log.hasContent, isTrue);

      final bozuk = DailyLog.fromMap({
        'date': '2026-03-04T00:00:00.000',
        'pregnancyTest': 'kesin-gebe',
      });
      expect(bozuk.pregnancyTest, isNull);
    });

    test('temizleme bayrakları yalnızca kendi alanını boşaltıyor', () {
      final log = DailyLog(
        date: DateTime(2026, 3, 4),
        pregnancyTest: 'negative',
        sexualActivity: 'protected',
        notes: 'not',
      );
      final a = log.copyWith(clearPregnancyTest: true);
      expect(a.pregnancyTest, isNull);
      expect(a.sexualActivity, 'protected');

      final b = log.copyWith(clearSexualActivity: true);
      expect(b.sexualActivity, isNull);
      expect(b.pregnancyTest, 'negative');
      expect(b.notes, 'not');
    });

    test('CSV sütunu ve değeri', () {
      final csv = DataExportService.buildCsv(
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 4), pregnancyTest: 'positive'),
        ],
        periodLogs: const [],
      );
      final satirlar = csv.split('\n');
      final baslik = satirlar.first.split(',');
      final i = baslik.indexOf('pregnancy_test');
      expect(i, isNonNegative);
      expect(satirlar[1].split('","')[i].replaceAll('"', ''), 'positive');
    });
  });
}
