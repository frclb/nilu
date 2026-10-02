import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/local/reminder_scheduler.dart';
import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';
import 'package:period_tracker/domain/services/reminder_planner.dart';
import 'package:period_tracker/presentation/reminders/reminder_sync.dart';

import 'screen_harness.dart';

/// Platform eklentisine dokunmadan ne yapıldığını kaydeden zamanlayıcı.
class _KayitciZamanlayici extends ReminderScheduler {
  int iptal = 0;
  final uygulanan = <List<ScheduledReminder>>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> cancelAll() async => iptal++;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> apply(
    List<ScheduledReminder> reminders, {
    required String Function(String key) localize,
  }) async {
    iptal++; // gerçek `apply` de önce hepsini iptal ediyor
    uygulanan.add(reminders);
  }

  @override
  Future<List<PendingNotificationRequest>> pending() async => const [];
}

/// Düşükten sonra eski gebelik bildirimleri temizleniyor mu?
///
/// Senkronizasyon plan **boşken** `apply`'ı hiç çağırmadan dönüyordu (izin
/// sormamak için) ve `cancelAll()` çalışmıyordu. Düşükten sonra döngü
/// tahmini olmadığı için plan tam olarak boş: gebelikte kurulmuş "18–22.
/// hafta: anomali taraması" bildirimi olduğu gibi kalıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  testWidgets('düşükten sonra boş plan eski bildirimleri temizliyor', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    final bugun = DateTime.now();
    final gun = DateTime(bugun.year, bugun.month, bugun.day);
    final sat = gun.subtract(const Duration(days: 70));

    await const PeriodRepository().savePeriodLogs([
      PeriodLog(
        id: 'sat',
        startDate: sat,
        endDate: sat.add(const Duration(days: 4)),
      ),
    ]);
    final gebelik = Pregnancy.fromLmp(
      lmp: sat,
      cycleLength: 28,
      confirmedAt: sat.add(const Duration(days: 35)),
      id: 'g1',
    );
    await const CareRepository().addMissing(
      CareTemplates.generate(gebelik, CareTemplates.turkeyAntenatal),
    );
    await const PregnancyRepository().upsert(
      gebelik.ended(
        outcome: PregnancyOutcome.miscarriage,
        at: gun.subtract(const Duration(days: 3)),
      ),
    );

    final zamanlayici = _KayitciZamanlayici();
    await pumpScreen(
      tester,
      ReminderSync(scheduler: zamanlayici, child: const SizedBox()),
      size: const Size(390, 844),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(
      zamanlayici.iptal,
      greaterThan(0),
      reason:
          'Plan boş ama eski gebelik bildirimleri temizlenmedi. Düşükten '
          'sonra "anomali taraması zamanı" bildirimi kilit ekranına düşer.',
    );
    expect(
      zamanlayici.uygulanan.expand((p) => p),
      isEmpty,
      reason: 'Hiçbir şey planlanmamalı',
    );
  });
}
