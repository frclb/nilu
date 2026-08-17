import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/intimacy_repository.dart';
import 'package:period_tracker/data/repositories/notification_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/notification_settings.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('PeriodRepository (şifreli)', () {
    const repo = PeriodRepository();

    test('veri yokken boş liste döner', () async {
      expect(await repo.getPeriodLogs(), isEmpty);
      expect(await repo.getDailyLogs(), isEmpty);
    });

    test('regl logları gidiş-dönüşte korunur', () async {
      final logs = [
        PeriodLog(
          id: 'a',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 5),
        ),
        PeriodLog(id: 'b', startDate: DateTime(2026, 2, 1)),
      ];

      await repo.savePeriodLogs(logs);
      final restored = await repo.getPeriodLogs();

      expect(restored, hasLength(2));
      expect(restored[0].id, 'a');
      expect(restored[0].endDate, DateTime(2026, 1, 5));
      expect(restored[1].isOngoing, isTrue);
    });

    test('günlük loglar gidiş-dönüşte korunur', () async {
      final logs = [DailyLog(date: DateTime(2026, 3, 3))];
      await repo.saveDailyLogs(logs);

      final restored = await repo.getDailyLogs();
      expect(restored, hasLength(1));
      expect(restored.first.date, DateTime(2026, 3, 3));
    });

    test('kaydetme önceki veriyi tamamen değiştirir', () async {
      await repo.savePeriodLogs([
        PeriodLog(id: 'a', startDate: DateTime(2026, 1, 1)),
      ]);
      await repo.savePeriodLogs([]);

      expect(await repo.getPeriodLogs(), isEmpty);
    });
  });

  group('CycleSettingsRepository (şifreli)', () {
    const repo = CycleSettingsRepository();

    test('kayıt yokken varsayılanları döner', () async {
      expect(await repo.getCycleLength(), 28);
      expect(await repo.getPeriodLength(), 5);
      expect(await repo.getSettingsUpdatedAt(), isNull);
    });

    test('saveCycleSettings değerleri ve güncel tarihi yazar', () async {
      await repo.saveCycleSettings(cycleLength: 31, periodLength: 6);

      expect(await repo.getCycleLength(), 31);
      expect(await repo.getPeriodLength(), 6);

      final updatedAt = await repo.getSettingsUpdatedAt();
      expect(updatedAt, isNotNull);
      expect(updatedAt!.year, greaterThan(2000));
    });

    test(
      'saveInitialSettings geçmiş bir tarih yazar (tüm tahminler yeni ayarla)',
      () async {
        await repo.saveInitialSettings(cycleLength: 30, periodLength: 4);

        expect(await repo.getCycleLength(), 30);
        expect(await repo.getSettingsUpdatedAt(), DateTime(2000, 1, 1));
      },
    );
  });

  group('IntimacyRepository (şifreli)', () {
    const repo = IntimacyRepository();

    test('seçimler gidiş-dönüşte korunur', () async {
      await repo.saveSexualDesire('passionate');
      await repo.saveAffectionNeeds(['hug', 'kiss']);

      expect(await repo.getSexualDesire(), 'passionate');
      expect(await repo.getAffectionNeeds(), ['hug', 'kiss']);
    });

    test('veri yokken güvenli varsayılanlar döner', () async {
      expect(await repo.getSexualDesire(), isNull);
      expect(await repo.getAffectionNeeds(), isEmpty);
      expect(await repo.getAutoShareEnabled(), isFalse);
      expect(await repo.getLastSharedAt(), isNull);
      expect(await repo.getDailyShareCount(), 0);
    });

    test('günlük paylaşım sayacı artar', () async {
      await repo.incrementDailyShareCount();
      await repo.incrementDailyShareCount();
      expect(await repo.getDailyShareCount(), 2);
    });

    test('sayaç farklı bir güne ait kayıtta sıfırlanır', () async {
      await repo.incrementDailyShareCount();
      expect(await repo.getDailyShareCount(), 1);

      // Kaydı dünkü tarihe çevir.
      const store = FlutterSecureStorage();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await store.write(
        key: 'intimacy_daily_share_date',
        value: yesterday.toIso8601String().substring(0, 10),
      );

      expect(await repo.getDailyShareCount(), 0);
    });

    test('offline kuyruk yazılır ve temizlenir', () async {
      await repo.saveOfflineQueue('{"a":1}');
      expect(await repo.getOfflineQueue(), '{"a":1}');

      await repo.clearOfflineQueue();
      expect(await repo.getOfflineQueue(), isNull);
    });
  });

  group('NotificationSettingsRepository (hassas değil, SharedPreferences)', () {
    final repo = NotificationSettingsRepository();

    test('kayıt yokken varsayılanları döner', () async {
      final s = await repo.getGeneralSettings();
      expect(s.periodReminders, isTrue);
      expect(s.dailyLogs, isFalse);
    });

    test('genel ayarlar gidiş-dönüşte korunur', () async {
      await repo.saveGeneralSettings(
        const GeneralNotificationSettings(
          periodReminders: false,
          fertileWindow: false,
          dailyLogs: true,
          partnerUpdates: false,
        ),
      );

      final s = await repo.getGeneralSettings();
      expect(s.periodReminders, isFalse);
      expect(s.dailyLogs, isTrue);
    });

    test('partner ayarları gidiş-dönüşte korunur', () async {
      await repo.savePartnerSettings(
        const PartnerNotificationSettings(
          ovulationEnabled: true,
          periodStartValue: '3',
          dailySupportValue: '1900',
        ),
      );

      final s = await repo.getPartnerSettings();
      expect(s.ovulationEnabled, isTrue);
      expect(s.periodStartValue, '3');
      expect(s.dailySupportValue, '1900');
    });
  });
}
