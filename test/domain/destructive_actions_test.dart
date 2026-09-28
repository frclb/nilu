import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/privacy_settings_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';

/// Geri alınamaz işlemlerin tam olarak söylediklerini yapması.
///
/// Çıkış diyaloğu "Kayıtlı sağlık verileriniz cihazda kalır" diyor;
/// hesap silme "geri alınamaz" diyor. İkisi de kullanıcının inandığı
/// cümleler ve yanlış tarafa kayarsa telafisi yok: ya veri kaybolur ya
/// da silindi sanılan veri cihazda kalır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const periodRepo = PeriodRepository();
  const gizlilik = PrivacySettingsRepository();
  const ayarlar = CycleSettingsRepository();

  Future<void> veriKur() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await periodRepo.savePeriodLogs([
      PeriodLog(
        id: 'p1',
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 6),
      ),
    ]);
    await periodRepo.saveDailyLogs([
      DailyLog(date: DateTime(2026, 4, 2), symptoms: const ['cramp']),
    ]);
    await ayarlar.saveInitialSettings(cycleLength: 30, periodLength: 6);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString('myId', 'kullanici-1');
    await prefs.setString('partnerId', 'partner-1');
    await prefs.setBool('hasPartner', true);
    // Ekran kilidi: kullanıcının verisini korumak için açtığı ayar.
    await prefs.setBool('privacy_biometric_enabled', true);
  }

  group('çıkış', () {
    test('sağlık verisine dokunmuyor', () async {
      await veriKur();
      await UserViewModel().signOut();

      expect(
        (await periodRepo.getPeriodLogs()).length,
        1,
        reason: 'çıkış dönem kaydını sildi — diyalog kalacağını söylüyor',
      );
      expect((await periodRepo.getDailyLogs()).length, 1);
      expect(await ayarlar.getCycleLength(), 30);
      expect(await ayarlar.getPeriodLength(), 6);
    });

    test('ekran kilidini kapatmıyor', () async {
      await veriKur();
      await UserViewModel().signOut();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('privacy_biometric_enabled'),
        isTrue,
        reason: 'çıkış kullanıcının kilidini sessizce kapattı',
      );
    });

    test('oturumu ve partner bağını bitiriyor', () async {
      await veriKur();
      await UserViewModel().signOut();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isFalse);
      expect(prefs.getString('partnerId'), isNull);
      expect(prefs.getString('myId'), isNull);
      expect(prefs.getBool('hasPartner'), isFalse);
    });
  });

  group('hesabı sil', () {
    test('sağlık verisinin tamamını siliyor', () async {
      await veriKur();
      await gizlilik.deleteAllLocalData();

      expect(
        await periodRepo.getPeriodLogs(),
        isEmpty,
        reason: 'silindi denen dönem kayıtları cihazda kaldı',
      );
      expect(await periodRepo.getDailyLogs(), isEmpty);
      // Ayarlar varsayılana dönmeli, eski değer okunmamalı.
      expect(
        await ayarlar.getCycleLength(),
        CycleSettingsRepository.defaultCycleLength,
      );
    });

    test('yerel tercihleri de siliyor', () async {
      await veriKur();
      await gizlilik.deleteAllLocalData();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('onboarding_complete'), isNull);
      expect(prefs.getString('myId'), isNull);
      expect(prefs.getBool('privacy_biometric_enabled'), isNull);
    });

    test('silme sonrası yedek alınırsa boş çıkıyor', () async {
      await veriKur();
      await gizlilik.deleteAllLocalData();

      final yedek = await gizlilik.exportDataAsJson();
      expect(yedek.contains('"periodLogs": []'), isTrue);
      expect(yedek.contains('"dailyLogs": []'), isTrue);
    });
  });
}
