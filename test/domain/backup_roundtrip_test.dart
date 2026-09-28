import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/privacy_settings_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';

/// Yedek al → geri yükle → hiçbir şey kaybolmamış olmalı.
///
/// İki yarı ayrı ayrı test ediliyordu: dışa aktarma kendi biçimine,
/// içe aktarma kendi beklentisine göre. İkisi arasındaki sözleşmeyi
/// kimse sınamıyordu — `toMap()` yazdığı bir alanı `fromMap()` okumazsa
/// veri sessizce kaybolur ve kullanıcı bunu ancak telefonunu
/// kaybettikten sonra fark eder.
///
/// Uygulamanın verisi yalnızca cihazda; yedek tek güvence.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repo = PrivacySettingsRepository();
  const periodRepo = PeriodRepository();

  /// Her alanı dolu bir günlük kayıt — boş bırakılan alan sınanmış olmaz.
  ///
  /// Kodlar `LogVocabulary`'nin kanonik listesinden. İlk yazışta 'cramps'
  /// kullanılmıştı ve test düştü: okurken 'cramp'a normalize ediliyor.
  /// Bu kasıtlı (eski kayıtlar için eşleme var), yani hata testteydi.
  DailyLog doluKayit(DateTime tarih) => DailyLog(
    date: tarih,
    symptoms: const ['cramp', 'headache'],
    notes: 'iki satırlık not\nikinci satır',
    flowIntensity: 'heavy',
    moods: const ['anxious', 'calm'],
    sexualActivity: 'protected',
    painLevel: 'severe',
    painLimitedActivity: true,
    painLocations: const ['abdomen', 'lower_back'],
    painContexts: const ['intercourse'],
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('tam dolu kayıtlar yedekten kayıpsız dönüyor', () async {
    final donem = PeriodLog(
      id: 'p1',
      startDate: DateTime(2026, 3, 4),
      endDate: DateTime(2026, 3, 10),
    );
    final suren = PeriodLog(id: 'p2', startDate: DateTime(2026, 4, 1));
    final gunluk = doluKayit(DateTime(2026, 3, 5));

    await periodRepo.savePeriodLogs([donem, suren]);
    await periodRepo.saveDailyLogs([gunluk]);

    final yedek = await repo.exportDataAsJson();

    // Cihaz sıfırlanmış gibi: yedek tek kaynak.
    FlutterSecureStorage.setMockInitialValues({});
    final rapor = await repo.importDataFromJson(yedek);
    expect(rapor.succeeded, isTrue, reason: 'yedek okunamadı');

    final donemler = await periodRepo.getPeriodLogs();
    expect(donemler.length, 2);

    final geri = donemler.firstWhere((l) => l.id == 'p1');
    expect(geri.startDate, donem.startDate);
    expect(geri.endDate, donem.endDate);

    final gerisuren = donemler.firstWhere((l) => l.id == 'p2');
    expect(gerisuren.endDate, isNull, reason: 'süren dönem kapanmış');

    final gunlukler = await periodRepo.getDailyLogs();
    expect(gunlukler.length, 1);
    final g = gunlukler.single;

    expect(g.date, gunluk.date);
    expect(g.symptoms, gunluk.symptoms);
    expect(g.notes, gunluk.notes, reason: 'not kayboldu');
    expect(g.flowIntensity, gunluk.flowIntensity);
    expect(g.moods, gunluk.moods);
    expect(g.sexualActivity, gunluk.sexualActivity, reason: 'cinsel aktivite kayboldu');
    expect(g.painLevel, gunluk.painLevel, reason: 'ağrı düzeyi kayboldu');
    expect(g.painLimitedActivity, gunluk.painLimitedActivity);
    expect(g.painLocations, gunluk.painLocations, reason: 'ağrı yerleri kayboldu');
    expect(g.painContexts, gunluk.painContexts, reason: 'ağrı bağlamı kayboldu');
  });

  test('boş alanlar boş dönüyor, uydurulmuyor', () async {
    await periodRepo.savePeriodLogs([
      PeriodLog(id: 'p', startDate: DateTime(2026, 5, 1)),
    ]);
    await periodRepo.saveDailyLogs([DailyLog(date: DateTime(2026, 5, 2))]);

    final yedek = await repo.exportDataAsJson();
    FlutterSecureStorage.setMockInitialValues({});
    await repo.importDataFromJson(yedek);

    final g = (await periodRepo.getDailyLogs()).single;
    expect(g.notes, isNull);
    expect(g.flowIntensity, isNull);
    expect(g.symptoms, isEmpty);
    expect(g.painLocations, isEmpty);
  });

  test('yıllarca veri kayıpsız dönüyor', () async {
    final donemler = [
      for (var i = 0; i < 60; i++)
        PeriodLog(
          id: 'p$i',
          startDate: DateTime(2022, 1, 1).add(Duration(days: i * 28)),
          endDate: DateTime(2022, 1, 5).add(Duration(days: i * 28)),
        ),
    ];
    final gunlukler = [
      for (var i = 0; i < 200; i++)
        doluKayit(DateTime(2022, 1, 1).add(Duration(days: i * 3))),
    ];

    await periodRepo.savePeriodLogs(donemler);
    await periodRepo.saveDailyLogs(gunlukler);

    final yedek = await repo.exportDataAsJson();
    FlutterSecureStorage.setMockInitialValues({});
    await repo.importDataFromJson(yedek);

    expect((await periodRepo.getPeriodLogs()).length, 60);
    expect((await periodRepo.getDailyLogs()).length, 200);
  });
}
