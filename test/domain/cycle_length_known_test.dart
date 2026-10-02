import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';

import '../presentation/screen_harness.dart';

/// Ortalama döngü uzunluğu kullanıcıdan mı geliyor?
///
/// `getCycleLength` kayıt yokken de 28 döndürüyor. Kurulumda gebelik yolunu
/// seçen kullanıcı ne süre söyledi ne kayıt girdi; o 28 ekranda "senin
/// döngün" diye sunulmamalı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  DateTime gunOnce(int n) {
    final b = DateTime.now();
    return DateTime(b.year, b.month, b.day - n);
  }

  PeriodLog regl(int once) => PeriodLog(
    id: 'p$once',
    startDate: gunOnce(once),
    endDate: gunOnce(once - 4),
  );

  Future<bool> biliniyor() async {
    final vm = CalendarViewModel();
    await vm.refreshData();
    return vm.cycleLengthKnown;
  }

  test('ne süre ne kayıt: bilinmiyor', () async {
    expect(await biliniyor(), isFalse);
  });

  test('tek kayıt: aralık yok, bilinmiyor', () async {
    await const PeriodRepository().savePeriodLogs([regl(20)]);
    expect(await biliniyor(), isFalse);
  });

  test('kurulumda süre söylendi: biliniyor', () async {
    await const CycleSettingsRepository().saveInitialSettings(
      cycleLength: 30,
      periodLength: 5,
    );
    expect(await biliniyor(), isTrue);
  });

  test('kayıtlardan bir döngü aralığı çıkıyor: biliniyor', () async {
    await const PeriodRepository().savePeriodLogs([regl(50), regl(20)]);
    expect(await biliniyor(), isTrue);
  });

  test('yalnızca hormonal korunma ayarı: süre söylenmedi', () async {
    // Bu ayar da "ayarların güncellendiği tarih"i yazıyor; o tarih süre
    // söylendiğinin işareti sayılamaz.
    await const CycleSettingsRepository().setHormonalContraception(true);
    expect(await biliniyor(), isFalse);
  });
}
