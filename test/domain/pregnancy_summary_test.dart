import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';
import 'package:period_tracker/domain/services/pregnancy_summary.dart';

/// Randevu özeti: hekimin önüne giden sayılar doğru dönemden mi?
///
/// Yanlış dönem iki yönde de zararlı: gebelikten önceki bir kanama
/// "gebelikte kanama" diye listelenirse hekim yanlış yönlenir; gebelikteki
/// bir kanama dışarıda kalırsa en önemli bilgi kaybolur.
void main() {
  final bugun = DateTime(2026, 10, 2);
  DateTime once(int n) => bugun.subtract(Duration(days: n));

  // 24+2 haftalık gebelik.
  final gebelik = Pregnancy.fromLmp(
    lmp: once(170),
    cycleLength: 28,
    confirmedAt: once(120),
    id: 'g1',
    careTemplate: 'tr',
  );

  PregnancySummary ozet(
    List<DailyLog> logs, {
    Pregnancy? p,
    LifeStage stage = LifeStage.pregnancy,
    List<CareEvent> events = const [],
  }) => PregnancySummary.build(
    pregnancy: p ?? gebelik,
    stage: stage,
    events: events,
    logs: logs,
    today: bugun,
  );

  group('gebelikte kanama', () {
    test('lekelenme dahil, yalnızca gebelik süresince', () {
      final o = ozet([
        DailyLog(date: once(200), flowIntensity: 'heavy'), // gebelikten önce
        DailyLog(date: once(60), flowIntensity: 'spotting'),
        DailyLog(date: once(5), flowIntensity: 'light'),
        DailyLog(date: once(4), flowIntensity: 'none'),
      ]);
      expect(o.flowDays.map((f) => (f.date, f.flow)), [
        (once(5), 'light'),
        (once(60), 'spotting'),
      ]);
    });

    test('gelecek tarihli kayıt sayılmıyor', () {
      final o = ozet([
        DailyLog(
          date: bugun.add(const Duration(days: 1)),
          flowIntensity: 'light',
        ),
      ]);
      expect(o.flowDays, isEmpty);
    });
  });

  group('tansiyon', () {
    test('en yeniden eskiye; yüksekler sayılıyor', () {
      final o = ozet([
        DailyLog(date: once(30), systolic: 118, diastolic: 76),
        DailyLog(date: once(10), systolic: 142, diastolic: 88),
        DailyLog(date: once(2), systolic: 120, diastolic: 92),
        DailyLog(date: once(300), systolic: 165, diastolic: 112), // önce
      ]);
      expect(o.bloodPressures.map((r) => r.systolic), [120, 142, 118]);
      expect(o.bloodPressureCount, 3);
      expect(o.highBloodPressureCount, 2);
    });

    test('en fazla on ölçüm listeleniyor, sayım hepsini kapsıyor', () {
      final o = ozet([
        for (var i = 0; i < 14; i++)
          DailyLog(date: once(i), systolic: 150, diastolic: 95),
      ]);
      expect(o.bloodPressures.length, PregnancySummary.maxReadings);
      expect(o.bloodPressureCount, 14);
      expect(o.highBloodPressureCount, 14);
    });
  });

  group('kilo', () {
    test('ilk, son ve değişim', () {
      final o = ozet([
        DailyLog(date: once(90), weightKg: 62),
        DailyLog(date: once(40), weightKg: 63.2),
        DailyLog(date: once(3), weightKg: 64.5),
      ]);
      expect(o.firstWeight!.kg, 62);
      expect(o.lastWeight!.kg, 64.5);
      expect(o.weightChange, closeTo(2.5, 1e-9));
    });

    test('tek ölçümde değişim yok', () {
      final o = ozet([DailyLog(date: once(3), weightKg: 64.5)]);
      expect(o.lastWeight!.kg, 64.5);
      expect(o.weightChange, isNull);
    });
  });

  group('belirtiler', () {
    test('son 14 gün, gün sayısıyla, çoktan aza', () {
      final o = ozet([
        DailyLog(date: once(0), symptoms: const ['nausea', 'heartburn']),
        DailyLog(date: once(1), symptoms: const ['nausea']),
        DailyLog(date: once(13), symptoms: const ['nausea', 'headache']),
        DailyLog(date: once(14), symptoms: const ['headache']), // pencere dışı
      ]);
      expect(o.recentSymptoms.map((b) => (b.code, b.days)), [
        ('nausea', 3),
        // Eşitlikte sözlük sırası: aynı veri her seferinde aynı özet.
        ('headache', 1),
        ('heartburn', 1),
      ]);
    });
  });

  group('kontroller', () {
    final kalemler = CareTemplates.generate(
      gebelik,
      CareTemplates.turkeyAntenatal,
    );

    test('yapılanlar, sıradakiler ve notlar', () {
      final ilk = kalemler.firstWhere((e) => e.code == 'tr_visit_1');
      final ikinci = kalemler.firstWhere((e) => e.code == 'tr_visit_2');
      final events = [
        for (final e in kalemler)
          if (e.id == ilk.id)
            e.copyWith(done: true)
          else if (e.id == ikinci.id)
            e.copyWith(note: '  Demir ilacını sor  ')
          else
            e,
      ];
      final o = ozet(const [], events: events);

      expect(o.doneCare.map((e) => e.code), ['tr_visit_1']);
      expect(o.upcomingCare, isNotEmpty);
      expect(
        o.upcomingCare.length,
        lessThanOrEqualTo(PregnancySummary.maxUpcoming),
      );
      expect(
        o.upcomingCare.every((e) => e.isPendingOn(gebelik, bugun)),
        isTrue,
      );
      expect(o.notedCare.map((e) => e.code), ['tr_visit_2']);
    });

    test('başka gebeliğin kalemi karışmıyor', () {
      final baska = CareEvent.custom(pregnancyId: 'eski', title: 'Eski');
      final o = ozet(const [], events: [baska.copyWith(done: true)]);
      expect(o.doneCare, isEmpty);
    });
  });

  group('sıralama (CareOrder)', () {
    // 24. haftada D vitamini (12–40) tarih sırasında 24–28. hafta
    // izleminin önündeydi; "sıradaki" kart gebeliğin sonuna kadar onu
    // gösterecekti.
    final kalemler = CareTemplates.generate(
      gebelik,
      CareTemplates.turkeyAntenatal,
    );

    test('destekler en sonda, diğerleri son güne göre', () {
      final sira = CareOrder.sorted(kalemler, gebelik);
      final ilkDestek = sira.indexWhere(
        (e) => e.category == CareCategory.supplement,
      );
      expect(ilkDestek, greaterThan(0));
      expect(
        sira
            .skip(ilkDestek)
            .every((e) => e.category == CareCategory.supplement),
        isTrue,
        reason: 'Desteklerden sonra izlem ya da tarama gelmemeli',
      );
      final digerleri = sira.take(ilkDestek).toList();
      for (var i = 1; i < digerleri.length; i++) {
        expect(
          CareOrder.deadline(
            digerleri[i - 1],
            gebelik,
          ).isAfter(CareOrder.deadline(digerleri[i], gebelik)),
          isFalse,
          reason: 'Son gün sırası bozuk',
        );
      }
    });

    test('özetin sıradakileri destekle başlamıyor', () {
      final o = ozet(const [], events: kalemler);
      expect(o.upcomingCare, isNotEmpty);
      // 24+2: 2. izlem bu hafta bitiyor; şeker yükleme testi ve 3. izlem
      // 28. haftada. Uzun pencereli tetanoz ve destekler sonra.
      expect(o.upcomingCare.map((e) => e.code), [
        'tr_visit_2',
        'tr_screen_ogtt',
        'tr_visit_3',
      ]);
    });

    test('yalnızca destek kaldıysa sıradaki o', () {
      final destekler = kalemler
          .where((e) => e.category == CareCategory.supplement)
          .toList();
      final o = ozet(const [], events: destekler);
      expect(o.upcomingCare, isNotEmpty);
    });
  });

  group('isPendingOn (panodaki "sıradaki" ve özet aynı kural)', () {
    final kalem = CareEvent.custom(pregnancyId: 'g1', title: 'Kontrol');

    test('yapılmış kalem bekleyen değil', () {
      expect(
        kalem
            .copyWith(scheduledAt: once(-3), done: true)
            .isPendingOn(gebelik, bugun),
        isFalse,
      );
    });

    test('randevu bugün ya da ileride ise bekliyor, geçtiyse değil', () {
      expect(
        kalem.copyWith(scheduledAt: bugun).isPendingOn(gebelik, bugun),
        isTrue,
      );
      expect(
        kalem.copyWith(scheduledAt: once(-1)).isPendingOn(gebelik, bugun),
        isTrue,
      );
      expect(
        kalem.copyWith(scheduledAt: once(1)).isPendingOn(gebelik, bugun),
        isFalse,
      );
    });

    test('randevusuz şablon kalemi: penceresi bitmediyse bekliyor', () {
      final sablon = CareTemplates.generate(
        gebelik,
        CareTemplates.turkeyAntenatal,
      );
      final ogtt = sablon.firstWhere(
        (e) => e.code == 'tr_screen_ogtt',
      ); // 24–28
      final ilk = sablon.firstWhere((e) => e.code == 'tr_visit_1'); // < 14
      expect(ogtt.isPendingOn(gebelik, bugun), isTrue);
      expect(ilk.isPendingOn(gebelik, bugun), isFalse);
    });
  });

  group('lohusalık', () {
    final dogum = once(10);
    final biten = gebelik.ended(outcome: PregnancyOutcome.birth, at: dogum);

    test('lohia doğumdan sonraki günlerden; tansiyon doğumdan beri', () {
      final o = ozet(
        [
          DailyLog(date: once(30), flowIntensity: 'spotting'), // gebelikte
          DailyLog(date: dogum, flowIntensity: 'heavy'), // doğum günü
          DailyLog(date: once(8), flowIntensity: 'heavy'),
          DailyLog(date: once(2), flowIntensity: 'light'),
          DailyLog(date: once(20), systolic: 150, diastolic: 95), // gebelikte
          DailyLog(date: once(3), systolic: 145, diastolic: 92),
        ],
        p: biten,
        stage: LifeStage.postpartum,
      );
      expect(o.flowDays.map((f) => (f.date, f.flow)), [
        (once(2), 'light'),
        (once(8), 'heavy'),
      ]);
      expect(o.bloodPressures.map((r) => r.systolic), [145]);
      expect(o.daysSinceBirth, 10);
    });

    test('gebelik kalemleri gizli, lohusa kalemleri görünür', () {
      final events = [
        ...CareTemplates.generate(
          gebelik,
          CareTemplates.turkeyAntenatal,
        ).map((e) => e.copyWith(done: true)),
        ...CareTemplates.generate(biten, CareTemplates.turkeyPostnatal),
      ];
      final o = ozet(
        const [],
        p: biten,
        stage: LifeStage.postpartum,
        events: events,
      );
      expect(o.doneCare, isEmpty, reason: 'Gebelik kalemleri listede');
      expect(
        o.upcomingCare.every((e) => e.anchor == CareAnchor.postpartum),
        isTrue,
      );
    });
  });
}
