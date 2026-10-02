import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/conception_intent.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/assistant/assistant_answer.dart';
import 'package:period_tracker/domain/services/assistant/assistant_parser.dart';
import 'package:period_tracker/domain/services/cycle_agenda.dart';
import 'package:period_tracker/domain/services/cycle_alert.dart';
import 'package:period_tracker/domain/services/cycle_intervals.dart';
import 'package:period_tracker/domain/services/data_export_service.dart';
import 'package:period_tracker/domain/services/health_import.dart';
import 'package:period_tracker/domain/services/insights_service.dart';
import 'package:period_tracker/domain/services/period_service.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';

import '../dst_support.dart';

/// Döngü hesapları yaz saatinde kaymıyor.
///
/// Gün farkı `difference().inDays`, gün ekleme `Duration(days: n)` ile
/// yapılıyordu: yaz saatine geçilen gün 23 saat sürdüğü için Berlin'de
/// 26 Şubat → 1 Nisan döngüsü 33 gün sayılıyor, ABD'de tahmin edilen regl
/// gece 01:00'e kayıyordu. Türkiye saatinde bu dosya kendiliğinden geçer;
/// asıl sınama `dst_timezones_test` ile yaz saatli saat dilimlerinde.
void main() {
  expectDstZoneInChild();

  PeriodLog regl(String id, DateTime bas, {DateTime? son}) =>
      PeriodLog(id: id, startDate: bas, endDate: son);

  for (final t in dstTransitions) {
    DateTime g(int n) => dstDay(t, n);
    final ad = '${t.day}.${t.month}';

    group('geçiş $ad', () {
      test('döngü uzunluğu', () {
        final aralik = CycleIntervals.of([
          regl('a', g(-10), son: g(-6)),
          regl('b', g(25), son: g(29)),
        ], breaks: const []);
        expect(aralik.single.lengthInDays, 35);
      });

      test('regl süresi ve beklenen devam', () {
        expect(regl('a', g(-2), son: g(2)).completedLength, 5);
        final suren = regl('b', g(-2));
        expect(suren.recordedLength(today: g(2)), 5);
        expect(
          suren.isExpectedContinuation(g(2), today: g(-1), expectedLength: 5),
          isTrue,
        );
        expect(
          suren.isExpectedContinuation(g(3), today: g(-1), expectedLength: 5),
          isFalse,
        );
      });

      test('döngü günü, evre ve gecikme', () {
        final info = CycleInfo(lastPeriodStart: g(-4), averagePeriodLength: 5);
        expect(info.cycleDayOn(g(3)), 8);
        // 6. gün regl değil (5 günlük regl).
        expect(
          info.phaseForDate(g(1), loggedStart: g(-4), now: g(5)),
          isNot(CyclePhase.menstruation),
        );
        expect(CycleInfo(predictedNextPeriod: g(-2)).daysLateAt(g(2)), 4);
      });

      // Son regl başı üç farklı yerde: yumurtlama geçişin ertesine, geçiş
      // gününe ve ilk ileri döngüde geçiş gününe denk geliyor. Pencere sonu
      // (yumurtlama + 1) ancak yumurtlama geçiş günündeyse saati aşıyor.
      for (final b in [-13, -14, -42]) {
        test('tahmin (son regl $b): sonraki regl, yumurtlama, doğurganlık, '
            'ileri döngüler', () {
          final info = PredictionService().getCycleInfo(
            [
              regl('a', g(b - 28), son: g(b - 24)),
              regl('b', g(b), son: g(b + 4)),
            ],
            userCycleLength: 28,
            userPeriodLength: 5,
            today: g(b + 1),
          );
          expect(info.lastPeriodStart, g(b));
          expect(info.predictedNextPeriod, g(b + 28));
          expect(info.ovulationDay, g(b + 14));
          expect(info.fertileWindowStart, g(b + 9));
          expect(info.fertileWindowEnd, g(b + 15));
          for (var i = 0; i < info.futurePredictions.length; i++) {
            final ileri = info.futurePredictions[i];
            final bas = b + 28 * (i + 1);
            final neden = '${i + 1}. ileri döngü';
            expect(ileri.startDate, g(bas), reason: neden);
            expect(ileri.ovulationDay, g(bas + 14), reason: neden);
            expect(ileri.fertileStart, g(bas + 9), reason: neden);
            expect(ileri.fertileEnd, g(bas + 15), reason: neden);
          }
        });
      }

      test('tahmin edilen regl bandı', () {
        final info = CycleInfo(
          predictedNextPeriod: g(-2),
          averagePeriodLength: 5,
        );
        expect(info.isPredictedPeriod(g(2)), isTrue);
        expect(info.isPredictedPeriod(g(3)), isFalse);

        // Aynısı ileri döngülerin bandında.
        final ileri = CycleInfo(
          predictedNextPeriod: g(-60),
          futurePredictions: [PredictedCycle(startDate: g(-2))],
          averagePeriodLength: 5,
        );
        expect(ileri.isPredictedPeriod(g(2)), isTrue);
        expect(ileri.isPredictedPeriod(g(3)), isFalse);
      });

      group('regl kaydı', () {
        final servis = PeriodService();

        test('dün biten regl "başladı" deyince yeniden açılıyor', () {
          final sonuc = servis.startPeriod([regl('a', g(-3), son: g(0))], g(1));
          expect(sonuc, hasLength(1), reason: 'Yeni bir dönem açıldı');
          expect(sonuc.single.isOngoing, isTrue);
        });

        test('dün kayıtlıysa "bitti" bugüne uzatıyor', () {
          // Tek günlük dönem: "dün" yanlış güne düşerse başka bir gün onu
          // kapsamıyor.
          final sonuc = servis.endPeriod([regl('a', g(0), son: g(0))], g(1));
          expect(sonuc.single.endDate, g(1));
        });

        test('baştan ve sondan kırpma', () {
          final bas = servis.toggleDay(
            [regl('a', g(0), son: g(3))],
            g(0),
            today: g(10),
          );
          expect(bas.single.firstDay, g(1));

          final son = servis.toggleDay(
            [regl('a', g(-3), son: g(1))],
            g(1),
            today: g(10),
          );
          expect(son.single.lastRecordedDay(today: g(10)), g(0));
        });

        test('önceki dönemle birleşiyor', () {
          final sonuc = servis.toggleDay(
            [regl('a', g(-4), son: g(0))],
            g(1),
            today: g(10),
          );
          expect(sonuc, hasLength(1), reason: 'Ayrı bir dönem açıldı');
          expect(sonuc.single.endDate, g(1));
        });

        test('sonraki dönemle birleşiyor', () {
          final sonuc = servis.toggleDay(
            [regl('a', g(1), son: g(4))],
            g(0),
            today: g(10),
          );
          expect(sonuc, hasLength(1), reason: 'Ayrı bir dönem açıldı');
          expect(sonuc.single.firstDay, g(0));
        });

        test('ortadan bölme', () {
          (DateTime, DateTime) aralik(PeriodLog l) =>
              (l.firstDay, l.lastRecordedDay(today: g(10)));
          // Geçiş günü siliniyor: ikinci parça ertesi gün başlıyor.
          expect(
            servis
                .toggleDay([regl('a', g(-2), son: g(2))], g(0), today: g(10))
                .map(aralik),
            [(g(-2), g(-1)), (g(1), g(2))],
          );
          // Geçişin ertesi siliniyor: ilk parça geçiş gününde bitiyor.
          expect(
            servis
                .toggleDay([regl('a', g(-2), son: g(3))], g(1), today: g(10))
                .map(aralik),
            [(g(-2), g(0)), (g(2), g(3))],
          );
        });

        test('başlangıçtan kayıt: beklenen süre dolmadıysa açık', () {
          final kayit = servis.recordFromStart(
            g(-2),
            today: g(2),
            expectedLength: 5,
          );
          expect(kayit.isOngoing, isTrue);
        });
      });

      test('ajanda ve asistan: kaç gün kaldı', () {
        final info = CycleInfo(
          lastPeriodStart: g(-25),
          predictedNextPeriod: g(3),
          fertilityTracked: false,
        );
        expect(CycleAgenda.upcoming(info, now: g(-2)).first.daysAway, 5);
        final cevap = AssistantAnswerBuilder.build(
          const AssistantQuery(AssistantIntent.nextPeriod),
          cycleInfo: info,
          periodLogs: const [],
          dailyLogs: const [],
          now: g(-2),
          breaks: const [],
        );
        expect(cevap.params['days'], '5');
      });

      test('ara kanama atakları ve regl kenarı', () {
        final regller = [regl('r', g(-30), son: g(-26))];
        // İki gün arayla iki lekelenme: ayrı ataklar.
        final ataklar = CycleAlertService.intermenstrualEpisodes(
          dailyLogs: [
            DailyLog(date: g(-1), flowIntensity: 'spotting'),
            DailyLog(date: g(1), flowIntensity: 'spotting'),
          ],
          periodLogs: regller,
          breaks: const [],
        );
        expect(ataklar, hasLength(2));

        // Reglin iki gün sonrası "kenarda", üç gün sonrası değil.
        final kenar = [regl('r', g(-3), son: g(-1))];
        List<DateTime> atak(int n) => CycleAlertService.intermenstrualEpisodes(
          dailyLogs: [DailyLog(date: g(n), flowIntensity: 'spotting')],
          periodLogs: kenar,
          breaks: const [],
        );
        expect(atak(1), isEmpty);
        expect(atak(2), hasLength(1));

        // Reglden iki gün önce kenarda, üç gün önce değil.
        List<DateTime> once(int n) => CycleAlertService.intermenstrualEpisodes(
          dailyLogs: [DailyLog(date: g(n), flowIntensity: 'spotting')],
          periodLogs: [regl('r', g(1), son: g(3))],
          breaks: const [],
        );
        expect(once(-1), isEmpty);
        expect(once(-2), hasLength(1));

        // Süren dönemin sonu bilinmiyor: beş günlük varsayım + iki gün.
        List<DateTime> suren(int n) => CycleAlertService.intermenstrualEpisodes(
          dailyLogs: [DailyLog(date: g(n), flowIntensity: 'spotting')],
          periodLogs: [regl('r', g(-2))],
          breaks: const [],
        );
        expect(suren(4), isEmpty);
        expect(suren(5), hasLength(1));
      });

      test('hatırlatıcılar doğru günde ve saatte', () {
        List<ScheduledReminder> plan({
          required GeneralNotificationSettings ayar,
          required DateTime simdi,
          CycleInfo? info,
          CarePlanInput care = CarePlanInput.none,
        }) => ReminderPlanner.plan(
          cycleInfo:
              info ??
              CycleInfo(
                lastPeriodStart: g(-26),
                predictedNextPeriod: g(2),
                fertilityTracked: false,
              ),
          settings: ayar,
          now: simdi,
          care: care,
        );
        DateTime saat(DateTime d, int h) => DateTime(d.year, d.month, d.day, h);

        final regl = plan(
          ayar: const GeneralNotificationSettings(fertileWindow: false),
          simdi: saat(g(-5), 8),
        ).where((r) => r.type == ReminderType.periodApproaching);
        expect(
          regl.first.when,
          saat(g(0), ReminderPlanner.morningHour),
          reason: 'Regl iki gün önce, sabah',
        );

        final gunluk = plan(
          ayar: const GeneralNotificationSettings(
            periodReminders: false,
            fertileWindow: false,
            dailyLogs: true,
          ),
          simdi: saat(g(-1), 21),
        ).where((r) => r.type == ReminderType.dailyLog);
        expect(gunluk.single.when, saat(g(0), ReminderPlanner.dailyLogHour));

        final folik = plan(
          ayar: const GeneralNotificationSettings(
            periodReminders: false,
            fertileWindow: false,
          ),
          simdi: saat(g(0), 8),
          care: CarePlanInput(
            stage: LifeStage.cycle,
            pregnancy: null,
            events: const [],
            conception: ConceptionIntent(since: g(0)),
          ),
        ).where((r) => r.titleKey == 'care_folic_acid_title');
        expect(
          folik.single.when,
          saat(g(1), ReminderPlanner.morningHour),
          reason: 'Folik asit niyetin ertesi sabahı',
        );

        // Gece yarısını yarım saat geçe randevu: bir önceki akşam.
        final gebelik = Pregnancy.fromLmp(
          lmp: g(-100),
          cycleLength: 28,
          id: 'p',
        );
        final randevu = plan(
          ayar: const GeneralNotificationSettings(
            periodReminders: false,
            fertileWindow: false,
          ),
          simdi: saat(g(-3), 8),
          care: CarePlanInput(
            stage: LifeStage.pregnancy,
            pregnancy: gebelik,
            events: [
              CareEvent.custom(
                pregnancyId: 'p',
                title: 'Kontrol',
                scheduledAt: DateTime(g(1).year, g(1).month, g(1).day, 0, 30),
              ),
            ],
          ),
        ).where((r) => r.type == ReminderType.care);
        expect(randevu.single.when, saat(g(0), ReminderPlanner.eveningHour));
      });

      test('Sağlık içe aktarımı: üç gün boşluk ayrı dönem', () {
        var n = 0;
        final donemler = HealthImport.toPeriods([
          HealthFlowDay(date: g(-2)),
          HealthFlowDay(date: g(1)),
        ], nextId: () => '${n++}');
        expect(donemler, hasLength(2));
      });

      test('belirtinin evresi döngü gününe göre', () {
        final sayim = InsightsService.symptomsByPhase(
          'headache',
          dailyLogs: [
            DailyLog(date: g(1), symptoms: const ['headache']),
          ],
          periodLogs: [regl('a', g(-4), son: g(0))],
          periodLength: 5,
          breaks: const [],
        );
        expect(
          sayim[CyclePhase.menstruation],
          isNull,
          reason: '6. gün regl evresi sayıldı',
        );
        expect(sayim.values.fold<int>(0, (a, b) => a + b), 1);
      });

      test('belirti: kesinti o gün başlıyorsa ya da başlangıç çok eskiyse '
          'sayılmıyor', () {
        Map<CyclePhase, int> say(DateTime gun, DateTime bas, {DateSpan? k}) =>
            InsightsService.symptomsByPhase(
              'headache',
              dailyLogs: [
                DailyLog(date: gun, symptoms: const ['headache']),
              ],
              periodLogs: [regl('a', bas, son: dstDay(bas, 4))],
              periodLength: 5,
              breaks: [?k],
            );
        // Gebelik o gün başladı: gün hiçbir regl evresine ait değil.
        expect(say(g(0), g(-10), k: DateSpan(g(0))), isEmpty);
        // 90 günden eski başlangıç döngüye bağlanmıyor; 90 gün bağlanıyor.
        const sinir = CycleIntervals.maxPlausibleDays;
        expect(say(g(31), g(30 - sinir)), isEmpty);
        expect(say(g(30), g(30 - sinir)), isNotEmpty);
      });

      test('CSV: regl günlerinin hepsi işaretli', () {
        final gunler = [for (var i = -2; i <= 2; i++) g(i)];
        final csv = DataExportService.buildCsv(
          dailyLogs: [for (final d in gunler) DailyLog(date: d, notes: 'x')],
          periodLogs: [regl('a', g(-2), son: g(2))],
        );
        final satirlar = csv.split('\n').skip(1).toList();
        expect(satirlar, hasLength(5));
        for (final s in satirlar) {
          expect(s.split(',')[1], '"yes"', reason: s);
        }
      });
    });
  }
}
