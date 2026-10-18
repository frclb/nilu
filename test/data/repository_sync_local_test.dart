import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/profile_repository.dart';
import 'package:period_tracker/data/sync/repository_sync_local.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/conception_intent.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/models/sync_snapshot.dart';

/// Cihaz depolarıyla eşitleme kopyası.
///
/// Buluttan inen kopya yazılıp geri okununca özet **aynı** kalmalı: kalmazsa
/// bu cihaz kendini "değişmiş" sanıp aynı veriyi yeniden yükler, öbür cihaz
/// da onu indirip aynısını yapar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const local = RepositorySyncLocal();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final gebelik = Pregnancy.fromLmp(
    lmp: DateTime(2026, 1, 5),
    cycleLength: 28,
    confirmedAt: DateTime(2026, 2, 10),
    id: 'g1',
  );

  SyncSnapshot ornek() => SyncSnapshot(
    periodLogs: [
      PeriodLog(
        id: 'p1',
        startDate: DateTime(2025, 12, 1),
        endDate: DateTime(2025, 12, 5),
      ),
    ],
    dailyLogs: [
      DailyLog(
        date: DateTime(2025, 12, 2),
        symptoms: const ['cramp'],
        painLevel: 'moderate',
        pregnancyTest: 'negative',
        notes: 'yorgun',
      ),
    ],
    pregnancies: [gebelik],
    careEvents: [
      CareEvent.custom(
        pregnancyId: 'g1',
        title: 'Kontrol',
        scheduledAt: DateTime(2026, 3, 4, 10),
      ),
    ],
    conception: ConceptionIntent(since: DateTime(2025, 11, 1)),
    cycleSettings: SyncCycleSettings(
      cycleLength: 31,
      periodLength: 6,
      updatedAt: DateTime(2025, 11, 2),
      hormonalContraception: false,
    ),
    profile: SyncProfile(
      name: 'Ada',
      email: 'ada@ornek.com',
      birthDate: DateTime(1994, 4, 4),
    ),
  );

  test('yazılan kopya aynı özetle geri okunuyor', () async {
    final s = ornek();
    await local.write(s);
    final geri = await local.read();
    expect(geri.hash, s.hash);
  });

  test('buluttan gelen metin de aynı özetle okunuyor', () async {
    // Örnek bir kez kuruluyor: `CareEvent.custom` her çağrıda yeni kimlik
    // üretiyor.
    final kaynak = ornek();
    await local.write(SyncSnapshot.decode(kaynak.encode()));
    expect((await local.read()).hash, kaynak.hash);
  });

  test('yazmak değiştirir: cihazda olup kopyada olmayan silinir', () async {
    await local.write(ornek());
    await local.write(
      SyncSnapshot(
        periodLogs: [
          PeriodLog(
            id: 'p2',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 4),
          ),
        ],
      ),
    );
    final geri = await local.read();
    expect(geri.periodLogs.map((l) => l.id), ['p2']);
    expect(geri.pregnancies, isEmpty);
    expect(geri.conception, isNull);
    expect(geri.profile.name, isNull, reason: 'Öbür cihazda silinen ad');
    expect(
      await const CycleSettingsRepository().hasCycleLength(),
      isFalse,
      reason: 'Girilmemiş süre varsayılanla doldurulmamalı',
    );
  });

  test(
    'ayar tarihi korunuyor (tahmin kuralı cihazdan cihaza kaymıyor)',
    () async {
      await local.write(ornek());
      expect(
        await const CycleSettingsRepository().getSettingsUpdatedAt(),
        DateTime(2025, 11, 2),
      );
      expect(await const ProfileRepository().getEmail(), 'ada@ornek.com');
    },
  );
}
