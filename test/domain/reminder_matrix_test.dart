import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';

/// Bildirim planının döngü durumlarıyla uyumu.
///
/// Hatırlatıcılar günler öncesinden cihaza yazılıyor ve kullanıcının kilit
/// ekranına düşüyor. Ekrandaki bir tutarsızlığı kullanıcı açıp görüyor;
/// yanlış bir bildirimi ise istemeden alıyor. Bu yüzden buradaki iddialar
/// ekran matrislerinden daha sıkı.
void main() {
  /// Sabit bir an: plan "şimdi"ye göre üretiliyor, testler bugüne göre
  /// kaymamalı.
  final now = DateTime(2026, 9, 18, 10);
  final today = DateTime(now.year, now.month, now.day);

  const allOn = GeneralNotificationSettings(
    periodReminders: true,
    fertileWindow: true,
    dailyLogs: true,
  );

  CycleInfo infoFor({int? daysLate, int? dayOfCycle, bool hormonal = false}) {
    final start = daysLate != null
        ? today.subtract(Duration(days: 28 + daysLate))
        : today.subtract(Duration(days: dayOfCycle! - 1));
    return PredictionService().getCycleInfo(
      [
        PeriodLog(
          id: 'a',
          startDate: start,
          endDate: start.add(const Duration(days: 4)),
        ),
      ],
      hormonalContraception: hormonal,
      today: today,
    );
  }

  List<ScheduledReminder> planFor(
    CycleInfo info, {
    GeneralNotificationSettings settings = allOn,
  }) => ReminderPlanner.plan(
    cycleInfo: info,
    settings: settings,
    now: now,
    care: CarePlanInput.none,
  );

  Iterable<ScheduledReminder> ofType(
    List<ScheduledReminder> plan,
    ReminderType type,
  ) => plan.where((r) => r.type == type);

  group('aynı bildirim iki kez planlanmıyor', () {
    // `predictedNextPeriod` ile `futurePredictions[0]` aynı tarih: ikisi de
    // `lastStart + döngüUzunluğu`. Tekilleştirilmediği için plana iki ayrı
    // kimlikle aynı an giriyordu — kullanıcı sabah dokuzda birbirinin
    // kopyası iki "Reglin yaklaşıyor" bildirimi alıyordu.
    for (final day in [1, 5, 12, 20, 26]) {
      test('döngünün $day. gününde', () {
        final plan = planFor(infoFor(dayOfCycle: day));
        final times = plan.map((r) => r.when).toList();

        expect(
          times.toSet(),
          hasLength(times.length),
          reason: 'aynı ana iki bildirim düşüyor: $plan',
        );
      });
    }

    test('kimlikler benzersiz', () {
      // Aynı kimlik platformda üzerine yazar; farklı kimlik ayrı bildirim
      // demek. İkisi de sessizce yanlış sonuç verir.
      final plan = planFor(infoFor(dayOfCycle: 12));
      final ids = plan.map((r) => r.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('gecikmede tahmine dayalı bildirim yok', () {
    // Ajandadaki hatanın aynısı, ama bu kez bildirim olarak gidiyor:
    // gelmemiş bir döngünün doğurganlık penceresi için "Doğurganlık
    // pencerene giriyorsun" push'u atılıyordu.
    for (final late in [1, 3, 10, 45]) {
      test('$late gün gecikme', () {
        final plan = planFor(infoFor(daysLate: late));

        expect(
          ofType(plan, ReminderType.fertileWindow),
          isEmpty,
          reason: 'gecikmede doğurganlık penceresi bildirilmemeli',
        );
        expect(
          ofType(plan, ReminderType.periodApproaching),
          isEmpty,
          reason: 'gecikmişken "reglin yaklaşıyor" demek anlamsız',
        );
      });
    }

    test('günlük kayıt hatırlatıcısı gecikmeden etkilenmiyor', () {
      // Tahmine dayanmıyor; gecikme onu susturmamalı.
      final plan = planFor(infoFor(daysLate: 5));
      expect(ofType(plan, ReminderType.dailyLog), hasLength(1));
    });

    test('gecikme yokken tahminler planlanıyor', () {
      // Karşı taraf: kural fazla geniş olsaydı hiçbir hatırlatıcı çıkmazdı.
      final plan = planFor(infoFor(dayOfCycle: 12));
      expect(ofType(plan, ReminderType.periodApproaching), isNotEmpty);
      expect(ofType(plan, ReminderType.fertileWindow), isNotEmpty);
    });
  });

  group('imza gecikmeyi görüyor', () {
    test('gecikince plan yeniden yazılıyor', () {
      // Asıl senaryo **aynı** döngünün iki farklı anda imzalanması: tahmin
      // edilen tarihler değişmiyor, yalnızca o tarih geride kalıyor.
      //
      // İmza yalnızca tahmin edilen tarihleri içeriyordu. Kullanıcı
      // gecikmeye düştüğünde imza aynı kaldığı için plan yenilenmiyor ve
      // daha önce yazılmış yanlış bildirimler öylece duruyordu.
      //
      // İki ayrı döngüyü karşılaştırmak bu iddiayı sınamaz: onların
      // tarihleri zaten farklı olduğu için imza ne olursa olsun değişir.
      final info = infoFor(dayOfCycle: 28); // regl yarın bekleniyor
      final afterDueDate = now.add(const Duration(days: 3));

      expect(
        info.daysLateAt(now),
        0,
        reason: 'kurulum: ilk anda gecikme olmamalı',
      );
      expect(
        info.daysLateAt(afterDueDate),
        greaterThan(0),
        reason: 'kurulum: ikinci anda gecikmiş olmalı',
      );

      expect(
        ReminderPlanner.signature(
          cycleInfo: info,
          settings: allOn,
          now: now,
          care: CarePlanInput.none,
        ),
        isNot(
          ReminderPlanner.signature(
            cycleInfo: info,
            settings: allOn,
            now: afterDueDate,
            care: CarePlanInput.none,
          ),
        ),
      );
    });

    test('aynı durumda imza değişmiyor', () {
      // Her açılışta bekleyen bildirimleri iptal edip yeniden yazmak pahalı.
      final info = infoFor(dayOfCycle: 12);
      expect(
        ReminderPlanner.signature(
          cycleInfo: info,
          settings: allOn,
          now: now,
          care: CarePlanInput.none,
        ),
        ReminderPlanner.signature(
          cycleInfo: info,
          settings: allOn,
          now: now.add(const Duration(hours: 3)),
          care: CarePlanInput.none,
        ),
      );
    });

    test('ayar değişince imza değişiyor', () {
      final info = infoFor(dayOfCycle: 12);
      expect(
        ReminderPlanner.signature(
          cycleInfo: info,
          settings: allOn,
          now: now,
          care: CarePlanInput.none,
        ),
        isNot(
          ReminderPlanner.signature(
            cycleInfo: info,
            settings: const GeneralNotificationSettings(fertileWindow: false),
            now: now,
            care: CarePlanInput.none,
          ),
        ),
      );
    });
  });

  group('anahtarlar plana birebir yansıyor', () {
    final cases = <String, (GeneralNotificationSettings, Set<ReminderType>)>{
      'hepsi kapalı': (
        const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
          dailyLogs: false,
          lateReminder: false,
        ),
        {},
      ),
      'yalnızca regl': (
        const GeneralNotificationSettings(
          periodReminders: true,
          fertileWindow: false,
          dailyLogs: false,
          lateReminder: false,
        ),
        {ReminderType.periodApproaching},
      ),
      'yalnızca doğurganlık': (
        const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: true,
          dailyLogs: false,
          lateReminder: false,
        ),
        {ReminderType.fertileWindow},
      ),
      'yalnızca günlük kayıt': (
        const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
          dailyLogs: true,
          lateReminder: false,
        ),
        {ReminderType.dailyLog},
      ),
      'yalnızca gecikme': (
        const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
          dailyLogs: false,
          lateReminder: true,
        ),
        {ReminderType.periodLate},
      ),
      'hepsi açık': (
        allOn,
        {
          ReminderType.periodApproaching,
          ReminderType.periodLate,
          ReminderType.fertileWindow,
          ReminderType.dailyLog,
        },
      ),
    };

    for (final entry in cases.entries) {
      test(entry.key, () {
        final (settings, expected) = entry.value;
        final plan = planFor(infoFor(dayOfCycle: 12), settings: settings);

        expect(plan.map((r) => r.type).toSet(), expected);
      });
    }
  });

  group('hormonal doğum kontrolü', () {
    test('doğurganlık anahtarı açık olsa da bildirim yok', () {
      // Doğurganlık verisi kaynakta hiç üretilmiyor; anahtar açık kalsa
      // bile plana giremez.
      final plan = planFor(infoFor(dayOfCycle: 12, hormonal: true));
      expect(ofType(plan, ReminderType.fertileWindow), isEmpty);
    });

    test('regl hatırlatıcısı çalışmaya devam ediyor', () {
      final plan = planFor(infoFor(dayOfCycle: 12, hormonal: true));
      expect(ofType(plan, ReminderType.periodApproaching), isNotEmpty);
    });
  });

  group('zamanlama kuralları', () {
    test('geçmişe hiçbir şey planlanmıyor', () {
      for (final day in [1, 12, 26, 28]) {
        for (final r in planFor(infoFor(dayOfCycle: day))) {
          expect(
            r.when.isAfter(now),
            isTrue,
            reason: '$day. gün: ${r.type.name} geçmişe planlandı',
          );
        }
      }
    });

    test('regl hatırlatıcısı iki gün önce sabah dokuzda', () {
      final info = infoFor(dayOfCycle: 12);
      final reminder = ofType(plan(info), ReminderType.periodApproaching).first;
      final expected = info.predictedNextPeriod!.subtract(
        const Duration(days: GeneralNotificationSettings.defaultPeriodLeadDays),
      );

      expect(reminder.when.day, expected.day);
      expect(
        reminder.when.hour,
        GeneralNotificationSettings.defaultReminderMinuteOfDay ~/ 60,
      );
    });

    test('günlük kayıt saati geçtiyse yarına planlanıyor', () {
      final evening = DateTime(2026, 9, 18, 21);
      final reminder = ReminderPlanner.plan(
        cycleInfo: infoFor(dayOfCycle: 12),
        settings: allOn,
        now: evening,
        care: CarePlanInput.none,
      ).firstWhere((r) => r.type == ReminderType.dailyLog);

      expect(reminder.when.day, 19);
      expect(
        reminder.when.hour,
        GeneralNotificationSettings.defaultDailyLogMinuteOfDay ~/ 60,
      );
    });

    test('plan iOS sınırının çok altında kalıyor', () {
      // iOS aynı anda 64 bekleyen bildirime izin veriyor; aşılırsa eskiler
      // sessizce düşüyor.
      expect(planFor(infoFor(dayOfCycle: 1)).length, lessThan(16));
    });
  });

  group('kayıt yokken', () {
    test('tahmine dayalı hatırlatıcı üretilmiyor', () {
      final info = PredictionService().getCycleInfo(const [], today: today);
      final plan = planFor(info);

      expect(ofType(plan, ReminderType.periodApproaching), isEmpty);
      expect(ofType(plan, ReminderType.fertileWindow), isEmpty);
      expect(
        ofType(plan, ReminderType.dailyLog),
        hasLength(1),
        reason: 'kayıt hatırlatıcısı tahmine bağlı değil',
      );
    });
  });
}

/// Test içinde kısayol.
List<ScheduledReminder> plan(CycleInfo info) => ReminderPlanner.plan(
  cycleInfo: info,
  settings: const GeneralNotificationSettings(
    periodReminders: true,
    fertileWindow: true,
    dailyLogs: true,
  ),
  now: DateTime(2026, 9, 18, 10),
  care: CarePlanInput.none,
);
