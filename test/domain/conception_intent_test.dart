import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/conception_intent.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';

/// Gebelik planlama niyeti.
///
/// Kaynaklar:
/// - Folik asit: T.C. Sağlık Bakanlığı Doğum Öncesi Bakım Yönetim Rehberi —
///   "gebelik planlayan her kadının gebelikten en az 1 ay önce başlamak
///   üzere 400–800 mikrogr/gün folik asit kullanması uygundur."
/// - Hekime başvuru: ASRM (2021) — 35 yaş altında 12 ay, 35 ve üstünde 6 ay
///   denemeden sonra değerlendirme; 40 üstünde daha erken.
void main() {
  final bas = DateTime(2026, 1, 10);
  DateTime dogum(int yas) => DateTime(2026 - yas, 1, 1);

  group('hekime başvuru zamanı (ASRM)', () {
    test('35 yaş altı: 12 ay', () {
      final n = ConceptionIntent(since: bas);
      expect(n.consultAt(birthDate: dogum(30)), DateTime(2027, 1, 10));
    });

    test('35 ve üstü: 6 ay', () {
      final n = ConceptionIntent(since: bas);
      expect(n.consultAt(birthDate: dogum(35)), DateTime(2026, 7, 10));
      expect(n.consultAt(birthDate: dogum(38)), DateTime(2026, 7, 10));
    });

    test('yaş, denemeye başlanan güne göre hesaplanıyor', () {
      // Başlarken 34, altı ay sonra 35: kural başlangıçtaki yaşa değil
      // bugünkü duruma bakmalı mı? ASRM yaşı değerlendirme anına göre
      // söylüyor; 35'e basınca 6 aylık eşik devreye girer.
      final n = ConceptionIntent(since: bas);
      final otuzDortBucuk = DateTime(1991, 4, 1); // 10 Ocak'ta 34
      expect(
        n.consultAt(birthDate: otuzDortBucuk),
        DateTime(2026, 7, 10),
        reason:
            '6. ayda (Temmuz 2026) zaten 35 yaşında; 6 aylık eşik geçerli',
      );
    });

    test('40 üstünde zamanlanmış tarih yok, hemen yönlendirme', () {
      // ASRM "daha erken" diyor ama bir sayı vermiyor. Uydurma bir ay
      // koymaktansa baştan söylemek dürüst.
      final n = ConceptionIntent(since: bas);
      expect(n.consultAt(birthDate: dogum(41)), isNull);
      expect(n.consultEarly(birthDate: dogum(41)), isTrue);
    });

    test('yaş bilinmiyorsa 12 ay', () {
      final n = ConceptionIntent(since: bas);
      expect(n.consultAt(birthDate: null), DateTime(2027, 1, 10));
      expect(n.consultEarly(birthDate: null), isFalse);
    });
  });

  group('hatırlatıcılar', () {
    const ayar = GeneralNotificationSettings();

    List<ScheduledReminder> plan(CarePlanInput girdi, DateTime simdi) =>
        ReminderPlanner.plan(
          cycleInfo: CycleInfo(),
          settings: ayar,
          now: simdi,
          care: girdi,
        ).where((r) => r.type == ReminderType.care).toList();

    CarePlanInput girdi({DateTime? dogumTarihi}) => CarePlanInput(
      stage: LifeStage.cycle,
      pregnancy: null,
      events: const [],
      conception: ConceptionIntent(since: bas),
      birthDate: dogumTarihi,
    );

    test('niyetin ertesi sabahı folik asit', () {
      final p = plan(girdi(), bas.add(const Duration(hours: 12)));
      expect(
        p.map((r) => (r.titleKey, r.when)),
        contains(('care_folic_acid_title', DateTime(2026, 1, 11, 9))),
      );
    });

    test('folik asit bir kez — günler sonra tekrar kurulmuyor', () {
      final p = plan(girdi(), DateTime(2026, 2, 1));
      expect(
        p.map((r) => r.titleKey),
        isNot(contains('care_folic_acid_title')),
      );
    });

    test('başvuru zamanı geldiğinde hatırlatıyor', () {
      final p = plan(girdi(dogumTarihi: dogum(30)), DateTime(2026, 3, 1));
      expect(
        p.map((r) => (r.titleKey, r.when)),
        contains(('care_consult_title', DateTime(2027, 1, 10, 9))),
      );
    });

    test('gebelikte planlama hatırlatıcısı yok', () {
      final p = plan(
        CarePlanInput(
          stage: LifeStage.pregnancy,
          pregnancy: null,
          events: const [],
          conception: ConceptionIntent(since: bas),
        ),
        bas,
      );
      expect(p, isEmpty);
    });

    test('niyet değişince imza değişiyor', () {
      String imza(ConceptionIntent? n) => ReminderPlanner.signature(
        cycleInfo: CycleInfo(),
        settings: ayar,
        now: bas,
        care: CarePlanInput(
          stage: LifeStage.cycle,
          pregnancy: null,
          events: const [],
          conception: n,
        ),
      );
      expect(imza(ConceptionIntent(since: bas)), isNot(imza(null)));
    });

    test('doğum tarihi değişince imza değişiyor', () {
      String imza(DateTime? d) => ReminderPlanner.signature(
        cycleInfo: CycleInfo(),
        settings: ayar,
        now: bas,
        care: CarePlanInput(
          stage: LifeStage.cycle,
          pregnancy: null,
          events: const [],
          conception: ConceptionIntent(since: bas),
          birthDate: d,
        ),
      );
      expect(
        imza(dogum(36)),
        isNot(imza(dogum(30))),
        reason: '6 ve 12 aylık eşik doğum tarihine bağlı',
      );
    });
  });

  test('json yuvarlak gidip gelir', () {
    final n = ConceptionIntent(since: bas);
    expect(ConceptionIntent.fromMap(n.toMap())?.since, bas);
  });
}
