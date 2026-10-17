import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/privacy_settings_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/backup_crypto.dart';
import 'package:period_tracker/domain/services/premium_gate.dart';

/// Yedeğin gidiş-dönüşü.
///
/// Dışa aktarma ile içe aktarma iki ayrı yerde yazılıyor; biri bir alan
/// eklemeyi unutursa kullanıcı verisini geri yüklediğini sanar ama eksik
/// olur — ve bunu ancak aylar sonra fark eder.
///
/// Bu yüzden test uydurma bir JSON kullanmıyor: **uygulamanın kendi dışa
/// aktarma çıktısını** geri yüklüyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const periods = PeriodRepository();
  const privacy = PrivacySettingsRepository();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final samplePeriods = [
    PeriodLog(
      id: '1',
      startDate: DateTime(2026, 1, 5),
      endDate: DateTime(2026, 1, 9),
    ),
    PeriodLog(
      id: '2',
      startDate: DateTime(2026, 2, 2),
      endDate: DateTime(2026, 2, 7),
    ),
  ];

  final sampleDaily = [
    DailyLog(
      date: DateTime(2026, 1, 5),
      flowIntensity: 'heavy',
      symptoms: const ['cramp', 'backache'],
      moods: const ['irritable'],
      sexualActivity: 'protected',
      pregnancyTest: 'negative',
      painLevel: 'severe',
      painLimitedActivity: true,
      painLocations: const ['abdomen', 'pelvis'],
      painContexts: const ['intercourse', 'bowel'],
      notes: 'ilk gün çok ağrılıydı',
    ),
    DailyLog(date: DateTime(2026, 1, 20), flowIntensity: 'spotting'),
  ];

  Future<String> exportAfterSaving() async {
    await periods.savePeriodLogs(samplePeriods);
    await periods.saveDailyLogs(sampleDaily);
    return privacy.exportDataAsJson();
  }

  test('yedek boş cihaza eksiksiz geri yükleniyor', () async {
    final backup = await exportAfterSaving();

    // Cihaz sıfırlanıyor: yeni telefon ya da yeniden kurulum.
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    expect(await periods.getPeriodLogs(), isEmpty, reason: 'kurulum');

    final report = await privacy.importDataFromJson(backup);
    expect(report.succeeded, isTrue);

    final restoredPeriods = await periods.getPeriodLogs();
    final restoredDaily = await periods.getDailyLogs();

    expect(restoredPeriods, hasLength(samplePeriods.length));
    expect(restoredDaily, hasLength(sampleDaily.length));

    for (final original in samplePeriods) {
      final match = restoredPeriods.firstWhere(
        (l) => l.startDate == original.startDate,
      );
      expect(match.endDate, original.endDate, reason: 'bitiş tarihi kaybolmuş');
    }

    // Her alan tek tek: birleşik karşılaştırma, eksik bir alanı
    // diğerlerinin gölgesinde bırakabilir.
    final rich = restoredDaily.firstWhere(
      (l) => l.date == sampleDaily.first.date,
    );
    final source = sampleDaily.first;

    expect(rich.flowIntensity, source.flowIntensity);
    expect(rich.symptoms, source.symptoms);
    expect(rich.moods, source.moods);
    expect(rich.sexualActivity, source.sexualActivity);
    expect(rich.pregnancyTest, source.pregnancyTest);
    expect(rich.painLevel, source.painLevel);
    expect(rich.painLimitedActivity, source.painLimitedActivity);
    expect(rich.painLocations, source.painLocations);
    expect(rich.painContexts, source.painContexts);
    expect(rich.notes, source.notes);
  });

  test('parolalı yedek de eksiksiz geri yükleniyor', () async {
    final sifreli = await BackupCrypto.encrypt(
      await exportAfterSaving(),
      'uzun-bir-parola',
      iterations: 100000,
    );
    expect(sifreli, isNot(contains('ilk gün çok ağrılıydı')));

    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    final report = await privacy.importDataFromJson(
      await BackupCrypto.decrypt(sifreli, 'uzun-bir-parola'),
    );
    expect(report.succeeded, isTrue);
    expect(await periods.getPeriodLogs(), hasLength(samplePeriods.length));
    expect(
      (await periods.getDailyLogs()).any(
        (l) => l.notes == 'ilk gün çok ağrılıydı',
      ),
      isTrue,
    );
  });

  test('aynı yedeği iki kez yüklemek kopya üretmiyor', () async {
    final backup = await exportAfterSaving();

    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await privacy.importDataFromJson(backup);
    final second = await privacy.importDataFromJson(backup);

    expect(second.totalAdded, 0);
    expect(await periods.getPeriodLogs(), hasLength(samplePeriods.length));
    expect(await periods.getDailyLogs(), hasLength(sampleDaily.length));
  });

  test('mevcut veri korunuyor', () async {
    final backup = await exportAfterSaving();

    // Cihazda yedekte olmayan bir kayıt var: geri yükleme onu silmemeli.
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final mine = DailyLog(
      date: DateTime(2026, 3, 15),
      notes: 'yedekten sonra girdim',
    );
    await periods.saveDailyLogs([mine]);

    await privacy.importDataFromJson(backup);

    final all = await periods.getDailyLogs();
    expect(
      all.any((l) => l.date == mine.date && l.notes == mine.notes),
      isTrue,
      reason: 'yedekte olmayan kaydım silinmiş',
    );
    expect(all, hasLength(sampleDaily.length + 1));
  });

  test('ücretsiz kullanıcı da yedek alabiliyor', () async {
    // Gizlilik politikasının 9. bölümü taşınabilirlik hakkını vaat
    // ediyor; KVKK ve GDPR bu hakkın ücretsiz kullanılmasını istiyor.
    // Ayrıca veri cihazda duruyor: yedek alamayan kullanıcı telefonunu
    // kaybettiğinde sağlık geçmişinin tamamını kaybederdi.
    expect(PremiumGate.canExportBackup(), isTrue);

    // Hekim özeti ve tablo kolaylık; onlar premium'da kalabilir.
    expect(PremiumGate.canExportReports(isPremium: false), isFalse);
  });

  test('başarısız okumada depoya dokunulmuyor', () async {
    await periods.savePeriodLogs(samplePeriods);

    final report = await privacy.importDataFromJson('bu bir yedek değil');

    expect(report.succeeded, isFalse);
    expect(
      await periods.getPeriodLogs(),
      hasLength(samplePeriods.length),
      reason: 'yarım yazılmış bir durum, hiç yazmamaktan kötü',
    );
  });
}
