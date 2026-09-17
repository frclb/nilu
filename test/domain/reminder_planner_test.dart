import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';

final DateTime now = DateTime(2026, 3, 1, 12);

CycleInfo cycle({
  DateTime? nextPeriod,
  DateTime? fertileStart,
  List<PredictedCycle> future = const [],
}) => CycleInfo(
  predictedNextPeriod: nextPeriod,
  fertileWindowStart: fertileStart,
  futurePredictions: future,
);

List<ScheduledReminder> plan({
  CycleInfo? info,
  GeneralNotificationSettings settings = const GeneralNotificationSettings(),
  DateTime? at,
}) => ReminderPlanner.plan(
  cycleInfo: info ?? cycle(),
  settings: settings,
  now: at ?? now,
);

List<ScheduledReminder> ofType(
  List<ScheduledReminder> all,
  ReminderType type,
) => all.where((r) => r.type == type).toList();

void main() {
  group('regl hatırlatıcısı', () {
    test('tahmini regl tarihinden 2 gün önce sabah planlanır', () {
      final result = plan(
        info: cycle(nextPeriod: DateTime(2026, 3, 20)),
        settings: const GeneralNotificationSettings(fertileWindow: false),
      );

      final period = ofType(result, ReminderType.periodApproaching);
      expect(period, hasLength(1));
      expect(period.single.when, DateTime(2026, 3, 18, 9));
    });

    test('ayar kapalıysa planlanmaz', () {
      final result = plan(
        info: cycle(nextPeriod: DateTime(2026, 3, 20)),
        settings: const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
        ),
      );
      expect(ofType(result, ReminderType.periodApproaching), isEmpty);
    });

    test('tahmin yoksa planlanmaz', () {
      final result = plan(settings: const GeneralNotificationSettings());
      expect(ofType(result, ReminderType.periodApproaching), isEmpty);
    });

    test('geçmişte kalan tarih planlanmaz', () {
      // Regl 2 gün sonra: hatırlatma zamanı (2 gün önce) çoktan geçmiş.
      final result = plan(
        info: cycle(nextPeriod: DateTime(2026, 3, 2)),
        settings: const GeneralNotificationSettings(fertileWindow: false),
      );
      expect(ofType(result, ReminderType.periodApproaching), isEmpty);
    });

    test('ileri döngüler de planlanır', () {
      final result = plan(
        info: cycle(
          nextPeriod: DateTime(2026, 3, 20),
          future: [
            PredictedCycle(startDate: DateTime(2026, 4, 17)),
            PredictedCycle(startDate: DateTime(2026, 5, 15)),
          ],
        ),
        settings: const GeneralNotificationSettings(fertileWindow: false),
      );

      final period = ofType(result, ReminderType.periodApproaching);
      expect(period, hasLength(3));
      expect(period.map((r) => r.when), [
        DateTime(2026, 3, 18, 9),
        DateTime(2026, 4, 15, 9),
        DateTime(2026, 5, 13, 9),
      ]);
    });

    test('iOS bildirim sınırına karşı en fazla 3 döngü planlanır', () {
      final result = plan(
        info: cycle(
          nextPeriod: DateTime(2026, 3, 20),
          future: List.generate(
            10,
            (i) => PredictedCycle(startDate: DateTime(2026, 4, 17 + i * 28)),
          ),
        ),
        settings: const GeneralNotificationSettings(fertileWindow: false),
      );
      expect(
        ofType(result, ReminderType.periodApproaching).length,
        ReminderPlanner.maxCycles,
      );
    });
  });

  group('doğurganlık hatırlatıcısı', () {
    test('pencere başlangıcı sabahına planlanır', () {
      final result = plan(
        info: cycle(fertileStart: DateTime(2026, 3, 10)),
        settings: const GeneralNotificationSettings(periodReminders: false),
      );

      final fertile = ofType(result, ReminderType.fertileWindow);
      expect(fertile, hasLength(1));
      expect(fertile.single.when, DateTime(2026, 3, 10, 9));
    });

    test('ayar kapalıysa planlanmaz', () {
      final result = plan(
        info: cycle(fertileStart: DateTime(2026, 3, 10)),
        settings: const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
        ),
      );
      expect(ofType(result, ReminderType.fertileWindow), isEmpty);
    });

    test('ileri döngülerin pencereleri de planlanır', () {
      final result = plan(
        info: cycle(
          fertileStart: DateTime(2026, 3, 10),
          future: [
            PredictedCycle(
              startDate: DateTime(2026, 4, 17),
              fertileStart: DateTime(2026, 4, 7),
            ),
          ],
        ),
        settings: const GeneralNotificationSettings(periodReminders: false),
      );
      expect(ofType(result, ReminderType.fertileWindow), hasLength(2));
    });
  });

  group('günlük kayıt hatırlatıcısı', () {
    test('bugünün saati geçmediyse bugüne planlanır', () {
      final result = plan(
        at: DateTime(2026, 3, 1, 12),
        settings: const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
          dailyLogs: true,
        ),
      );
      final daily = ofType(result, ReminderType.dailyLog);
      expect(daily, hasLength(1));
      expect(daily.single.when, DateTime(2026, 3, 1, 20));
    });

    test('saat geçtiyse yarına planlanır', () {
      final result = plan(
        at: DateTime(2026, 3, 1, 21),
        settings: const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
          dailyLogs: true,
        ),
      );
      expect(
        ofType(result, ReminderType.dailyLog).single.when,
        DateTime(2026, 3, 2, 20),
      );
    });

    test('varsayılan olarak kapalıdır', () {
      expect(
        ofType(plan(), ReminderType.dailyLog),
        isEmpty,
        reason: 'dailyLogs varsayılanı false',
      );
    });
  });

  group('plan bütünlüğü', () {
    test('zamana göre sıralıdır', () {
      final result = plan(
        at: DateTime(2026, 3, 1, 8),
        info: cycle(
          nextPeriod: DateTime(2026, 3, 20),
          fertileStart: DateTime(2026, 3, 10),
        ),
        settings: const GeneralNotificationSettings(dailyLogs: true),
      );

      for (var i = 1; i < result.length; i++) {
        expect(
          result[i].when.isBefore(result[i - 1].when),
          isFalse,
          reason: 'sıralama bozuk: ${result[i - 1]} -> ${result[i]}',
        );
      }
    });

    test('kimlikler benzersizdir (bildirimler birbirini ezmez)', () {
      final result = plan(
        info: cycle(
          nextPeriod: DateTime(2026, 3, 20),
          fertileStart: DateTime(2026, 3, 10),
          future: [
            PredictedCycle(
              startDate: DateTime(2026, 4, 17),
              fertileStart: DateTime(2026, 4, 7),
            ),
          ],
        ),
        settings: const GeneralNotificationSettings(dailyLogs: true),
      );

      final ids = result.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('tüm hatırlatıcılar gelecektedir', () {
      final result = plan(
        info: cycle(
          nextPeriod: DateTime(2026, 3, 20),
          fertileStart: DateTime(2026, 3, 10),
        ),
        settings: const GeneralNotificationSettings(dailyLogs: true),
      );

      for (final r in result) {
        expect(r.when.isAfter(now), isTrue, reason: '$r geçmişte');
      }
    });

    test('hepsi kapalıyken plan boştur', () {
      final result = plan(
        info: cycle(
          nextPeriod: DateTime(2026, 3, 20),
          fertileStart: DateTime(2026, 3, 10),
        ),
        settings: const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
          dailyLogs: false,
        ),
      );
      expect(result, isEmpty);
    });

    test('her hatırlatıcının başlık ve gövde anahtarı vardır', () {
      final result = plan(
        info: cycle(
          nextPeriod: DateTime(2026, 3, 20),
          fertileStart: DateTime(2026, 3, 10),
        ),
        settings: const GeneralNotificationSettings(dailyLogs: true),
      );

      for (final r in result) {
        expect(r.titleKey, isNotEmpty);
        expect(r.bodyKey, isNotEmpty);
      }
    });
  });

  group('imza', () {
    const on = GeneralNotificationSettings(
      periodReminders: true,
      fertileWindow: true,
      dailyLogs: true,
    );

    test('aynı girdi aynı imzayı verir', () {
      final info = cycle(
        nextPeriod: DateTime(2026, 4, 1),
        fertileStart: DateTime(2026, 3, 12),
      );
      expect(
        ReminderPlanner.signature(cycleInfo: info, settings: on, now: now),
        ReminderPlanner.signature(cycleInfo: info, settings: on, now: now),
      );
    });

    test('tahmin kayınca imza değişir', () {
      // Düzeltilen hata: kullanıcı takvimde regl işaretleyince tahminler
      // kayıyor ama planlanmış bildirimler eski tarihte kalıyordu.
      expect(
        ReminderPlanner.signature(
          cycleInfo: cycle(nextPeriod: DateTime(2026, 4, 1)),
          settings: on,
          now: now,
        ),
        isNot(
          ReminderPlanner.signature(
            cycleInfo: cycle(nextPeriod: DateTime(2026, 3, 25)),
            settings: on,
            now: now,
          ),
        ),
      );
    });

    test('doğurganlık penceresi kayınca imza değişir', () {
      expect(
        ReminderPlanner.signature(
          cycleInfo: cycle(fertileStart: DateTime(2026, 3, 12)),
          settings: on,
          now: now,
        ),
        isNot(
          ReminderPlanner.signature(
            cycleInfo: cycle(fertileStart: DateTime(2026, 3, 15)),
            settings: on,
            now: now,
          ),
        ),
      );
    });

    test('ileri tahminler değişince imza değişir', () {
      expect(
        ReminderPlanner.signature(cycleInfo: cycle(), settings: on, now: now),
        isNot(
          ReminderPlanner.signature(
            cycleInfo: cycle(
              future: [PredictedCycle(startDate: DateTime(2026, 5, 1))],
            ),
            settings: on,
            now: now,
          ),
        ),
      );
    });

    test('ayar değişince imza değişir', () {
      final info = cycle(nextPeriod: DateTime(2026, 4, 1));
      expect(
        ReminderPlanner.signature(cycleInfo: info, settings: on, now: now),
        isNot(
          ReminderPlanner.signature(
            cycleInfo: info,
            settings: on.copyWith(periodReminders: false),
            now: now,
          ),
        ),
      );
    });

    test('günün saati imzayı değiştirmez', () {
      // İmza yalnızca tarihe bakmalı; yoksa her yeniden hesapta bekleyen tüm
      // bildirimler gereksizce iptal edilip yeniden yazılırdı.
      expect(
        ReminderPlanner.signature(
          cycleInfo: cycle(nextPeriod: DateTime(2026, 4, 1, 3)),
          settings: on,
          now: now,
        ),
        ReminderPlanner.signature(
          cycleInfo: cycle(nextPeriod: DateTime(2026, 4, 1, 22)),
          settings: on,
          now: now,
        ),
      );
    });
  });
}
