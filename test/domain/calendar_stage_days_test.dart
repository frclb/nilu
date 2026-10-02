import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';

/// Takvimin gün ayrıntısı gebelikte ve sonrasında döngü dili konuşmamalı.
///
/// Simülatörde 24 haftalık gebelikte takvim başlığı "Döngü günü 5" diyor ve
/// açık kalmış bir regl kaydının "beklenen devamını" tahmin diye boyuyordu.
/// İkisi de dönem kayıtlarından doğrudan hesaplanıyordu; evreye ve gebelik
/// kesintisine bakılmıyordu. Düşükten sonra da döngü günü gebelik öncesi
/// son adetten sayılıp "Döngü günü 85" yazılacaktı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bugun = DateTime.now();
  final gun = DateTime(bugun.year, bugun.month, bugun.day);
  DateTime once(int n) => DateTime(gun.year, gun.month, gun.day - n);

  Future<CalendarViewModel> kur(
    List<PeriodLog> kayitlar,
    Pregnancy gebelik,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await const PeriodRepository().savePeriodLogs(kayitlar);
    await const PregnancyRepository().upsert(gebelik);
    final vm = CalendarViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return vm;
  }

  // Gebelik öncesi düzenli döngüler; son adet 170 gün önce.
  final sat = once(170);
  final oncesi = [
    for (final o in [226, 198, 170])
      PeriodLog(id: 'p$o', startDate: once(o), endDate: once(o - 4)),
  ];
  final gebelik = Pregnancy.fromLmp(
    lmp: sat,
    cycleLength: 28,
    confirmedAt: once(120),
    id: 'g1',
  );

  group('gebelik sürerken', () {
    test('açık kalmış regl kaydının devamı tahmin diye boyanmıyor', () async {
      final vm = await kur([
        ...oncesi,
        // Gebelikte girilmiş, kapatılmamış bir kanama kaydı. İki gün önce
        // başladı: varsayılan 5 günlük sürede "beklenen devamı" önümüzdeki
        // günlere taşıyor (simülatörde 3–6 Ekim boyanmıştı).
        PeriodLog(id: 'acik', startDate: once(2)),
      ], gebelik);

      for (var i = 0; i < 6; i++) {
        expect(
          vm.isPredictedPeriodDay(gun.add(Duration(days: i))),
          isFalse,
          reason: 'Gebelikte regl tahmini yok (+$i. gün)',
        );
      }
      expect(vm.getCycleDayForDate(gun), isNull, reason: 'Döngü günü');
    });

    test('gebelik öncesindeki günlerin döngü günü yerinde', () async {
      final vm = await kur(oncesi, gebelik);
      // Gebelik öncesi son döngünün 3. günü.
      expect(vm.getCycleDayForDate(once(200)), 27);
      expect(vm.getCycleDayForDate(once(196)), 3);
    });
  });

  group('düşükten sonra', () {
    final bitti = gebelik.ended(
      outcome: PregnancyOutcome.miscarriage,
      at: once(30),
    );

    test('yeni regl yokken döngü günü gebelik öncesinden sayılmıyor', () async {
      final vm = await kur(oncesi, bitti);
      expect(
        vm.getCycleDayForDate(gun),
        isNull,
        reason: '"Döngü günü 171" — gebelik öncesi son adetten sayıldı',
      );
      for (var i = 0; i < 40; i++) {
        expect(
          vm.isPredictedPeriodDay(gun.add(Duration(days: i))),
          isFalse,
          reason: 'Kesintiden sonra tek döngü yokken tahmin (+$i. gün)',
        );
      }
    });

    test('yeni regl girilince döngü günü ondan sayılıyor', () async {
      final vm = await kur([
        ...oncesi,
        PeriodLog(id: 'yeni', startDate: once(9), endDate: once(5)),
      ], bitti);
      expect(vm.getCycleDayForDate(gun), 10);
    });
  });
}
