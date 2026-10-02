import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/localization/date_names.dart';
import 'package:period_tracker/presentation/pregnancy/care_summary_screen.dart';
import 'package:period_tracker/presentation/pregnancy/past_pregnancies_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Geçmiş gebelikler.
///
/// Gebelik bitince kayıt silinmiyordu ("geçmişte kalır") ama bir daha
/// görülemiyordu. Liste ve her gebeliğin kaydı: kayıt gebeliğin kendi
/// dönemini göstermeli — öncesi ve doğumdan sonrası karışırsa "gebelikte
/// kanama" ya da "gebelikte tansiyon" yanlış olur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  // Doğumla biten: 400 gün önce başladı, 127 gün önce 39+1'de doğum.
  final dogumBasi = today.plusDays(-400);
  final dogumla = Pregnancy.fromLmp(
    lmp: dogumBasi,
    cycleLength: 28,
    confirmedAt: dogumBasi.plusDays(50),
    id: 'dogum',
    careTemplate: 'tr',
  ).ended(outcome: PregnancyOutcome.birth, at: dogumBasi.plusDays(274));

  // Düşükle biten: 9+1'de, 60 gün önce.
  final dusukBasi = today.plusDays(-124);
  final dusukle = Pregnancy.fromLmp(
    lmp: dusukBasi,
    cycleLength: 28,
    confirmedAt: dusukBasi.plusDays(40),
    id: 'dusuk',
  ).ended(outcome: PregnancyOutcome.miscarriage, at: dusukBasi.plusDays(64));

  // Nasıl bittiği söylenmemiş: 8+0'da, 600 gün önce.
  final soylenmeyenBasi = today.plusDays(-656);
  final soylenmeyen =
      Pregnancy.fromLmp(
        lmp: soylenmeyenBasi,
        cycleLength: 28,
        confirmedAt: soylenmeyenBasi.plusDays(40),
        id: 'soylenmeyen',
      ).ended(
        outcome: PregnancyOutcome.undisclosed,
        at: soylenmeyenBasi.plusDays(56),
      );

  Future<void> kaydet(List<Pregnancy> gebelikler) async {
    for (final g in gebelikler) {
      await const PregnancyRepository().upsert(g);
    }
  }

  Finder kart(String id) => find.byKey(Key('past_preg_$id'));

  String aralik(BuildContext ctx, Pregnancy g) {
    String ay(DateTime d) => '${ctx.monthName(d.month)} ${d.year}';
    return '${ay(g.gestationStart)} – ${ay(g.endedAt!)}';
  }

  group('liste', () {
    testWidgets('en son biten önce; nasıl bittiği yalnızca söylendiyse', (
      tester,
    ) async {
      await kaydet([soylenmeyen, dogumla, dusukle]);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PastPregnanciesScreen()),
      );
      final ctx = tester.element(find.byType(PastPregnanciesScreen));

      final ustler = [
        for (final id in ['dusuk', 'dogum', 'soylenmeyen'])
          tester.getTopLeft(kart(id)).dy,
      ];
      expect(ustler, orderedEquals([...ustler]..sort()), reason: 'Sıra');

      String hafta(String ga) =>
          ctx.tr('past_preg_weeks_short', params: {'ga': ga});
      expect(find.text(aralik(ctx, dogumla)), findsOneWidget);
      expect(
        find.text('${ctx.tr('preg_outcome_birth')} · ${hafta('39+1')}'),
        findsOneWidget,
      );
      expect(
        find.text('${ctx.tr('preg_outcome_miscarriage')} · ${hafta('9+1')}'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: kart('soylenmeyen'),
          matching: find.text(hafta('8+0')),
        ),
        findsOneWidget,
      );
      expect(
        find.text(ctx.tr('preg_outcome_undisclosed'), skipOffstage: false),
        findsNothing,
        reason: '"Belirtmek istemiyorum" diyene etiket konmamalı',
      );
      expect(rawKeysOnScreen(tester), isEmpty);
    });

    testWidgets('süren gebelik listede yok', (tester) async {
      await seedPregnancy();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PastPregnanciesScreen()),
      );
      final ctx = tester.element(find.byType(PastPregnanciesScreen));
      expect(find.text(ctx.tr('past_preg_empty')), findsOneWidget);
      expect(kart('g1'), findsNothing);
    });
  });

  group('kayıt', () {
    Future<BuildContext> ac(WidgetTester tester, String id) async {
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PastPregnanciesScreen()),
        size: const Size(390, 3000),
      );
      await tester.tap(kart(id));
      await settleAsync(tester);
      return tester.element(find.byType(CareSummaryScreen));
    }

    String tamTarih(BuildContext ctx, DateTime d) =>
        '${d.day} ${ctx.monthName(d.month)} ${d.year}';

    testWidgets('gebeliğin kendi dönemi: öncesi ve doğumdan sonrası yok', (
      tester,
    ) async {
      await kaydet([dogumla]);
      final doguM = dogumla.endedAt!;
      await const PeriodRepository().saveDailyLogs([
        // Gebelikten önce: sayılmamalı.
        DailyLog(
          date: dogumBasi.plusDays(-10),
          systolic: 150,
          diastolic: 100,
          notes: 'gebelikten önce',
        ),
        // Gebeliğin başında: son 14 günde değil ama gebelikte.
        DailyLog(date: dogumBasi.plusDays(40), symptoms: const ['nausea']),
        DailyLog(
          date: dogumBasi.plusDays(200),
          systolic: 142,
          diastolic: 91,
          weightKg: 70,
          notes: 'bebek çok hareketli',
        ),
        DailyLog(date: dogumBasi.plusDays(260), weightKg: 79.5),
        // Doğum günü ve sonrası lohusalık: gebelik kaydına girmemeli.
        DailyLog(date: doguM, flowIntensity: 'heavy', systolic: 120),
        DailyLog(
          date: doguM.plusDays(5),
          systolic: 160,
          diastolic: 105,
          notes: 'doğumdan sonra',
        ),
      ]);
      await const CareRepository().upsert(
        CareEvent.custom(
          pregnancyId: 'dogum',
          title: 'Diş kontrolü',
          scheduledAt: dogumBasi.plusDays(150),
        ).copyWith(done: true, note: 'dolgu yapıldı'),
      );
      final ctx = await ac(tester, 'dogum');

      expect(find.text(ctx.tr('past_preg_record_title')), findsOneWidget);
      expect(
        find.text(
          ctx.tr('care_summary_birth', params: {'date': tamTarih(ctx, doguM)}),
        ),
        findsOneWidget,
      );
      expect(
        find.text(ctx.tr('past_preg_weeks_at_end', params: {'ga': '39+1'})),
        findsOneWidget,
      );

      // Tansiyon: yalnızca gebelikteki ölçüm, tarihi yılıyla.
      expect(
        find.text(
          ctx.tr(
            'care_summary_bp_high_count',
            params: {'high': '1', 'total': '1'},
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text('${tamTarih(ctx, dogumBasi.plusDays(200))} — 142/91 mmHg'),
        findsOneWidget,
      );
      expect(find.textContaining('160/105'), findsNothing);
      expect(find.textContaining('150/100'), findsNothing);

      // Kanama: doğum günündeki lohia gebelikte kanama değil.
      expect(
        find.textContaining(ctx.tr(LogVocabulary.flowKey('heavy'))),
        findsNothing,
        reason: 'Doğum günü lohusalığın ilk günü',
      );

      // Belirtiler bütün gebelik boyunca; başlık da öyle söylüyor.
      expect(
        find.text(ctx.upper(ctx.tr('past_preg_section_symptoms'))),
        findsOneWidget,
      );
      expect(
        find.textContaining(ctx.tr(LogVocabulary.symptomKey('nausea'))),
        findsOneWidget,
      );

      // Kontrol ve notu; "sıradakiler" yok (gebelik bitti).
      expect(find.text('✓ Diş kontrolü'), findsOneWidget);
      expect(find.text('Diş kontrolü: dolgu yapıldı'), findsOneWidget);
      expect(find.text(ctx.tr('care_summary_upcoming')), findsNothing);

      // Günlük notlar: yalnızca gebelikteki.
      expect(
        find.text(
          '${tamTarih(ctx, dogumBasi.plusDays(200))} — bebek çok hareketli',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('gebelikten önce'), findsNothing);
      expect(find.textContaining('doğumdan sonra'), findsNothing);
      expect(rawKeysOnScreen(tester), isEmpty);
    });

    testWidgets('düşük: bitiş satırında söylediği sonuç', (tester) async {
      await kaydet([dusukle]);
      final ctx = await ac(tester, 'dusuk');
      expect(
        find.text(
          ctx.tr(
            'past_preg_ended_with',
            params: {
              'outcome': ctx.tr('preg_outcome_miscarriage'),
              'date': tamTarih(ctx, dusukle.endedAt!),
            },
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('söylenmeyen: yalnızca bitiş tarihi', (tester) async {
      await kaydet([soylenmeyen]);
      final ctx = await ac(tester, 'soylenmeyen');
      expect(
        find.text(
          ctx.tr(
            'past_preg_ended',
            params: {'date': tamTarih(ctx, soylenmeyen.endedAt!)},
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining(ctx.tr('preg_outcome_undisclosed')),
        findsNothing,
      );
    });

    testWidgets('paylaşmak Premium; ekranda görmek herkese açık', (
      tester,
    ) async {
      await kaydet([dogumla]);
      await ac(tester, 'dogum');
      await tester.tap(find.byKey(const Key('care_summary_share')));
      await settleAsync(tester);
      expect(find.text(premiumMarker), findsOneWidget);
    });
  });

  testWidgets('süren gebeliğin randevu özetinde günlük not bölümü yok', (
    tester,
  ) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CareSummaryScreen()),
      size: const Size(390, 3000),
    );
    final ctx = tester.element(find.byType(CareSummaryScreen));
    expect(find.text(ctx.tr('care_summary_title')), findsOneWidget);
    expect(
      find.text(ctx.upper(ctx.tr('past_preg_section_daily_notes'))),
      findsNothing,
    );
  });

  group('profil', () {
    for (final durum in ['döngü', 'gebelik']) {
      testWidgets('$durum: biten gebelik varsa "geçmiş gebelikler" var', (
        tester,
      ) async {
        await kaydet([dusukle]);
        if (durum == 'gebelik') await seedPregnancy();
        await pumpRouter(
          tester,
          routes: pregnancyRoutes(const ProfileSettingsScreen()),
        );
        final ctx = tester.element(find.byType(ProfileSettingsScreen));
        final satir = find.text(ctx.tr('past_preg_title'));
        await tester.scrollUntilVisible(satir, 300);
        await tester.tap(satir);
        await settleAsync(tester);
        expect(find.byType(PastPregnanciesScreen), findsOneWidget);
        expect(kart('dusuk'), findsOneWidget);
      });
    }

    testWidgets('biten gebelik yoksa satır yok', (tester) async {
      await seedCycles();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const ProfileSettingsScreen()),
      );
      final ctx = tester.element(find.byType(ProfileSettingsScreen));
      expect(
        find.text(ctx.tr('past_preg_title'), skipOffstage: false),
        findsNothing,
      );
    });
  });
}
