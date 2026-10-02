import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';

/// Gebelik ve lohusalık hatırlatıcıları.
///
/// En kötü senaryo planda yazılı (`LIFE_STAGES.md` §2): düşükten iki hafta
/// sonra kilit ekranına "18–22. hafta: anomali taraması" bildirimi gelmesi.
/// Bu dosyanın asıl işi o senaryonun **imkânsız** olduğunu göstermek.
void main() {
  final sat = DateTime(2026, 1, 1);
  final gebelik = Pregnancy.fromLmp(
    lmp: sat,
    cycleLength: 28,
    confirmedAt: DateTime(2026, 2, 10),
    id: 'g1',
  );
  final olaylar = [
    ...CareTemplates.generate(gebelik, CareTemplates.turkeyAntenatal),
    ...CareTemplates.generate(gebelik, CareTemplates.turkeyPostnatal),
  ];

  const ayar = GeneralNotificationSettings();
  final simdi = DateTime(2026, 2, 15, 12);

  List<ScheduledReminder> plan({
    required CarePlanInput care,
    GeneralNotificationSettings settings = ayar,
    DateTime? now,
  }) => ReminderPlanner.plan(
    cycleInfo: CycleInfo(),
    settings: settings,
    now: now ?? simdi,
    care: care,
  );

  Iterable<ScheduledReminder> bakim(List<ScheduledReminder> p) =>
      p.where((r) => r.type == ReminderType.care);

  group('gebelikte', () {
    final girdi = CarePlanInput(
      stage: LifeStage.pregnancy,
      pregnancy: gebelik,
      events: olaylar,
    );

    test('gelecek pencereler için hatırlatıcı kuruluyor', () {
      final p = bakim(plan(care: girdi));
      expect(p, isNotEmpty);
      expect(
        p.every((r) => r.when.isAfter(simdi)),
        isTrue,
        reason: 'Geçmişe bildirim kurulmaz',
      );
    });

    test('pencere başında sabah 9\'da', () {
      final anomali = olaylar.singleWhere((e) => e.code == 'tr_screen_anomaly');
      final beklenen = anomali.windowStart(gebelik)!;
      expect(
        bakim(plan(care: girdi)).map((r) => r.when),
        contains(DateTime(beklenen.year, beklenen.month, beklenen.day, 9)),
      );
    });

    test('doğum sonu kalemleri gebelikte planlanmıyor', () {
      // Doğum tarihi bilinmiyor; pencere uydurulmamalı.
      final pp = olaylar.where((e) => e.anchor == CareAnchor.postpartum);
      final kodlar = bakim(plan(care: girdi)).map((r) => r.titleKey);
      for (final e in pp) {
        expect(kodlar, isNot(contains('care_${e.code}_title')));
      }
    });

    test('yapılan ve kapatılan kalemler hatırlatılmıyor', () {
      final anomaliId = olaylar
          .singleWhere((e) => e.code == 'tr_screen_anomaly')
          .id;
      final ogttId = olaylar.singleWhere((e) => e.code == 'tr_screen_ogtt').id;
      final degisik = [
        for (final e in olaylar)
          e.id == anomaliId
              ? e.copyWith(done: true)
              : e.id == ogttId
              ? e.copyWith(reminderOn: false)
              : e,
      ];
      final p = bakim(
        plan(
          care: CarePlanInput(
            stage: LifeStage.pregnancy,
            pregnancy: gebelik,
            events: degisik,
          ),
        ),
      ).map((r) => r.titleKey);

      expect(p, isNot(contains('care_tr_screen_anomaly_title')));
      expect(p, isNot(contains('care_tr_screen_ogtt_title')));
    });

    test('randevu saati varsa bir önceki akşam hatırlatılıyor', () {
      final randevu = DateTime(2026, 5, 12, 10, 30);
      final ikinci = olaylar
          .singleWhere((e) => e.code == 'tr_visit_2')
          .copyWith(scheduledAt: randevu);
      final p = bakim(
        plan(
          care: CarePlanInput(
            stage: LifeStage.pregnancy,
            pregnancy: gebelik,
            events: [ikinci],
          ),
        ),
      ).toList();

      expect(p, hasLength(1));
      expect(p.single.when, DateTime(2026, 5, 11, 20));
      expect(p.single.bodyKey, 'notif_care_tomorrow_body');
    });

    test('kullanıcının kendi randevusu kendi adıyla', () {
      final dis = CareEvent.custom(
        pregnancyId: 'g1',
        title: 'Diş hekimi',
        scheduledAt: DateTime(2026, 3, 4, 14),
      );
      final p = bakim(
        plan(
          care: CarePlanInput(
            stage: LifeStage.pregnancy,
            pregnancy: gebelik,
            events: [dis],
          ),
        ),
      ).single;
      expect(p.literalTitle, 'Diş hekimi');
    });

    test('başka bir gebeliğin kalemleri planlanmıyor', () {
      final baska = CareTemplates.generate(
        Pregnancy.fromLmp(
          lmp: sat,
          cycleLength: 28,
          confirmedAt: DateTime(2026, 2, 1),
          id: 'eski',
        ),
        CareTemplates.turkeyAntenatal,
      );
      expect(
        bakim(
          plan(
            care: CarePlanInput(
              stage: LifeStage.pregnancy,
              pregnancy: gebelik,
              events: baska,
            ),
          ),
        ),
        isEmpty,
      );
    });

    test('ana anahtar kapalıysa hiçbiri', () {
      expect(
        bakim(
          plan(
            care: girdi,
            settings: ayar.copyWith(careReminders: false),
          ),
        ),
        isEmpty,
      );
    });
  });

  group('gebelik bittiğinde', () {
    test('düşükten sonra tek bir bakım hatırlatıcısı kalmıyor', () {
      final biten = gebelik.ended(
        outcome: PregnancyOutcome.miscarriage,
        at: DateTime(2026, 2, 26),
      );
      final p = plan(
        care: CarePlanInput(
          stage: LifeStage.cycle,
          pregnancy: biten,
          events: olaylar,
        ),
        now: DateTime(2026, 3, 12),
      );

      expect(
        bakim(p),
        isEmpty,
        reason:
            'Düşükten sonra "anomali taraması zamanı" bildirimi en kötü '
            'senaryo. Döngü evresinde hiçbir bakım kalemi planlanmamalı.',
      );
    });

    test('doğumdan sonra yalnızca lohusa izlemleri', () {
      final dogum = DateTime(2026, 10, 5);
      final biten = gebelik.ended(outcome: PregnancyOutcome.birth, at: dogum);
      final p = bakim(
        plan(
          care: CarePlanInput(
            stage: LifeStage.postpartum,
            pregnancy: biten,
            events: olaylar,
          ),
          now: DateTime(2026, 10, 6, 12),
        ),
      ).toList();

      expect(p, isNotEmpty);
      expect(
        p.map((r) => r.titleKey),
        everyElement(startsWith('care_tr_pp_')),
        reason: 'Doğumdan sonra gebelik taraması hatırlatılmamalı',
      );
    });

    test('evre değişince imza değişiyor', () {
      // Hatırlatıcılar yalnızca imza değişince yeniden yazılıyor. Düşükten
      // önce ve sonra döngü tahmini olmadığı için döngü kısmı aynı kalıyor;
      // gebelik imzaya girmezse plan hiç yenilenmez ve eski bildirimler
      // olduğu gibi durur.
      final once = ReminderPlanner.signature(
        cycleInfo: CycleInfo(),
        settings: ayar,
        now: simdi,
        care: CarePlanInput(
          stage: LifeStage.pregnancy,
          pregnancy: gebelik,
          events: olaylar,
        ),
      );
      final sonra = ReminderPlanner.signature(
        cycleInfo: CycleInfo(),
        settings: ayar,
        now: simdi,
        care: CarePlanInput(
          stage: LifeStage.cycle,
          pregnancy: gebelik.ended(
            outcome: PregnancyOutcome.miscarriage,
            at: DateTime(2026, 2, 14),
          ),
          events: olaylar,
        ),
      );
      expect(sonra, isNot(once));
    });

    test('lohusalık bitince (42. gün) imza değişiyor', () {
      // Gebelik, doğum tarihi ve kalemler aynı; yalnızca evre değişiyor.
      // Evre imzada olmasaydı lohusalık bittiğinde plan yenilenmez,
      // lohusalığa ait bildirimler döngü evresinde de dururdu.
      final dogum = gebelik.ended(
        outcome: PregnancyOutcome.birth,
        at: DateTime(2026, 10, 5),
      );
      String imza(LifeStage evre) => ReminderPlanner.signature(
        cycleInfo: CycleInfo(),
        settings: ayar,
        now: simdi,
        care: CarePlanInput(stage: evre, pregnancy: dogum, events: olaylar),
      );
      expect(imza(LifeStage.cycle), isNot(imza(LifeStage.postpartum)));
    });

    test('randevu değişince imza değişiyor', () {
      CarePlanInput girdi(DateTime? saat) => CarePlanInput(
        stage: LifeStage.pregnancy,
        pregnancy: gebelik,
        events: [olaylar.first.copyWith(scheduledAt: saat)],
      );
      String imza(DateTime? saat) => ReminderPlanner.signature(
        cycleInfo: CycleInfo(),
        settings: ayar,
        now: simdi,
        care: girdi(saat),
      );
      expect(imza(DateTime(2026, 3, 1, 10)), isNot(imza(null)));
    });
  });

  group('gizli bildirim', () {
    final girdi = CarePlanInput(
      stage: LifeStage.pregnancy,
      pregnancy: gebelik,
      events: [
        ...olaylar,
        CareEvent.custom(
          pregnancyId: 'g1',
          title: 'Gebelik kontrolü — Dr. Ayşe',
          scheduledAt: DateTime(2026, 3, 4, 14),
        ),
      ],
    );

    test('hiçbir bildirim içeriğini ele vermiyor', () {
      final p = plan(
        care: girdi,
        settings: ayar.copyWith(discreet: true, dailyLogs: true),
      );

      expect(p, isNotEmpty);
      for (final r in p) {
        expect(r.titleKey, 'notif_discreet_title', reason: '$r');
        expect(r.bodyKey, 'notif_discreet_body', reason: '$r');
        expect(
          r.literalTitle,
          isNull,
          reason:
              'Kullanıcının yazdığı "Gebelik kontrolü" kilit ekranına '
              'düşmemeli',
        );
      }
    });

    test('kapalıyken içerik görünüyor', () {
      final p = bakim(plan(care: girdi));
      expect(p.map((r) => r.titleKey), contains('care_tr_screen_anomaly_title'));
    });

    test('gizlilik ayarı imzaya giriyor', () {
      String imza(bool gizli) => ReminderPlanner.signature(
        cycleInfo: CycleInfo(),
        settings: ayar.copyWith(discreet: gizli),
        now: simdi,
        care: CarePlanInput.none,
      );
      expect(
        imza(true),
        isNot(imza(false)),
        reason: 'Ayarı açınca zaten kurulmuş açık metinli bildirimler '
            'yeniden yazılmalı',
      );
    });
  });
}
