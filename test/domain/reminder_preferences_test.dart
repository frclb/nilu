import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';

/// Kullanıcının seçtiği gün ve saatler plana birebir yansıyor mu, gecikme
/// hatırlatıcısı yalnızca gerektiğinde ve bir kez mi geliyor?
void main() {
  final now = DateTime(2026, 9, 18, 10);
  final today = DateTime(now.year, now.month, now.day);

  CycleInfo infoFor({int? daysLate, int? dayOfCycle}) {
    final start = daysLate != null
        ? today.subtract(Duration(days: 28 + daysLate))
        : today.subtract(Duration(days: dayOfCycle! - 1));
    return PredictionService().getCycleInfo([
      PeriodLog(
        id: 'a',
        startDate: start,
        endDate: start.add(const Duration(days: 4)),
      ),
    ], today: today);
  }

  List<ScheduledReminder> planFor(
    CycleInfo info,
    GeneralNotificationSettings settings, {
    CarePlanInput care = CarePlanInput.none,
    DateTime? at,
  }) => ReminderPlanner.plan(
    cycleInfo: info,
    settings: settings,
    now: at ?? now,
    care: care,
  );

  Iterable<ScheduledReminder> ofType(
    List<ScheduledReminder> plan,
    ReminderType type,
  ) => plan.where((r) => r.type == type);

  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  group('kaç gün önce', () {
    for (var lead = 1; lead <= 5; lead++) {
      test('$lead gün önce', () {
        final info = infoFor(dayOfCycle: 10);
        final first = ofType(
          planFor(
            info,
            GeneralNotificationSettings(
              fertileWindow: false,
              periodLeadDays: lead,
            ),
          ),
          ReminderType.periodApproaching,
        ).first;

        expect(
          day(first.when),
          day(info.predictedNextPeriod!).subtract(Duration(days: lead)),
        );
      });
    }
  });

  group('saat', () {
    const settings = GeneralNotificationSettings(
      dailyLogs: true,
      reminderMinuteOfDay: 7 * 60 + 30,
      dailyLogMinuteOfDay: 22 * 60 + 15,
    );

    test('regl, doğurganlık ve gecikme seçilen saatte', () {
      final plan = planFor(infoFor(dayOfCycle: 5), settings);
      for (final type in [
        ReminderType.periodApproaching,
        ReminderType.fertileWindow,
        ReminderType.periodLate,
      ]) {
        final reminders = ofType(plan, type);
        expect(reminders, isNotEmpty, reason: type.name);
        for (final r in reminders) {
          expect((r.when.hour, r.when.minute), (7, 30), reason: type.name);
        }
      }
    });

    test('günlük kayıt kendi saatinde', () {
      final r = ofType(
        planFor(infoFor(dayOfCycle: 5), settings),
        ReminderType.dailyLog,
      ).single;
      expect(r.when, DateTime(2026, 9, 18, 22, 15));
    });

    test('günlük kayıt saati geçtiyse ertesi gün aynı saatte', () {
      final r = ofType(
        planFor(
          infoFor(dayOfCycle: 5),
          settings,
          at: DateTime(2026, 9, 18, 23),
        ),
        ReminderType.dailyLog,
      ).single;
      expect(r.when, DateTime(2026, 9, 19, 22, 15));
    });

    test('bakım penceresi seçilen saatte, randevu akşamı 20.00 kalıyor', () {
      final gebelik = Pregnancy.fromLmp(
        lmp: DateTime(2026, 7, 1),
        cycleLength: 28,
        confirmedAt: DateTime(2026, 8, 10),
        id: 'g',
      );
      final randevu = CareEvent.custom(
        pregnancyId: 'g',
        title: 'Kontrol',
        scheduledAt: DateTime(2026, 10, 2, 14),
      );
      final plan = planFor(
        CycleInfo(),
        settings,
        care: CarePlanInput(
          stage: LifeStage.pregnancy,
          pregnancy: gebelik,
          events: [randevu],
        ),
      );
      final r = ofType(plan, ReminderType.care).single;
      expect(
        r.when,
        DateTime(2026, 10, 1, 20),
        reason: '"Yarın randevun var" sabah söylenirse bir gün erken olur',
      );
    });
  });

  group('gecikme hatırlatıcısı', () {
    const settings = GeneralNotificationSettings(
      periodReminders: false,
      fertileWindow: false,
    );

    test('beklenen günden üç gün sonra, bir kez', () {
      final info = infoFor(dayOfCycle: 20);
      final late = ofType(
        planFor(info, settings),
        ReminderType.periodLate,
      ).toList();

      expect(late, hasLength(1));
      expect(
        day(late.single.when),
        day(
          info.predictedNextPeriod!,
        ).add(const Duration(days: ReminderPlanner.lateAfterDays)),
      );
      expect(late.single.titleKey, 'notif_late_title');
      expect(late.single.bodyKey, 'notif_late_body');
    });

    test('gecikmenin ikinci gününde hâlâ bekliyor', () {
      final late = ofType(
        planFor(infoFor(daysLate: 2), settings),
        ReminderType.periodLate,
      );
      expect(late, hasLength(1));
      expect(day(late.single.when), today.add(const Duration(days: 1)));
    });

    test('günü geçtiyse yeniden kurulmuyor', () {
      expect(
        ofType(
          planFor(infoFor(daysLate: 4), settings),
          ReminderType.periodLate,
        ),
        isEmpty,
        reason: 'Her açılışta "gecikti" demek dürtmek olur',
      );
    });

    test('anahtar kapalıyken yok', () {
      expect(
        ofType(
          planFor(
            infoFor(dayOfCycle: 20),
            settings.copyWith(lateReminder: false),
          ),
          ReminderType.periodLate,
        ),
        isEmpty,
      );
    });

    test('gebelikte ve lohusalıkta yok', () {
      for (final stage in [LifeStage.pregnancy, LifeStage.postpartum]) {
        expect(
          ofType(
            planFor(
              infoFor(dayOfCycle: 20),
              settings,
              care: CarePlanInput(stage: stage, pregnancy: null, events: []),
            ),
            ReminderType.periodLate,
          ),
          isEmpty,
          reason: stage.name,
        );
      }
    });

    test('gizli bildirimde içerik görünmüyor', () {
      final late = ofType(
        planFor(infoFor(dayOfCycle: 20), settings.copyWith(discreet: true)),
        ReminderType.periodLate,
      ).single;
      expect(late.titleKey, 'notif_discreet_title');
      expect(late.bodyKey, 'notif_discreet_body');
    });
  });

  group('imza', () {
    String sign(GeneralNotificationSettings s) => ReminderPlanner.signature(
      cycleInfo: infoFor(dayOfCycle: 10),
      settings: s,
      now: now,
      care: CarePlanInput.none,
    );

    const base = GeneralNotificationSettings();

    test('gün, saat ve gecikme anahtarı değişince plan yenileniyor', () {
      for (final changed in [
        base.copyWith(periodLeadDays: 4),
        base.copyWith(reminderMinuteOfDay: 8 * 60),
        base.copyWith(dailyLogMinuteOfDay: 21 * 60),
        base.copyWith(lateReminder: false),
      ]) {
        expect(sign(changed), isNot(sign(base)));
      }
    });
  });

  group('bozuk kayıt', () {
    test('aralık dışı değerler sınıra çekiliyor', () {
      expect(GeneralNotificationSettings.clampLeadDays(0), 1);
      expect(GeneralNotificationSettings.clampLeadDays(9), 5);
      expect(GeneralNotificationSettings.clampMinuteOfDay(-5), 0);
      expect(GeneralNotificationSettings.clampMinuteOfDay(5000), 24 * 60 - 1);
    });
  });
}
