import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_ring_data.dart';

void main() {
  const tokens = AppTokens.light;

  CycleRingData build({
    int cycleLength = 28,
    int periodLength = 5,
    required int currentDay,
    bool tracked = true,
  }) => CycleRingData.from(
    info: CycleInfo(
      averageCycleLength: cycleLength,
      averagePeriodLength: periodLength,
      fertilityTracked: tracked,
    ),
    currentDay: currentDay,
    tokens: tokens,
  );

  group('CycleRingData', () {
    test('normal döngüde uzunluk beklenen kadar', () {
      final data = build(currentDay: 5);
      expect(data.length, 28);
      expect(data.todayIndex, 4);
    });

    test('gecikmede halka bugüne kadar uzar', () {
      // Halka yalnızca beklenen uzunlukta olsaydı bugüne denk gelen çiçek
      // olmaz, işaret kaybolur ve bütün günler geçmiş sayılıp çelenk solardı.
      final data = build(currentDay: 33);
      expect(data.length, 33);
      expect(data.todayIndex, 32);
    });

    test('beklenenin ötesindeki günler nötr renkte', () {
      final data = build(currentDay: 33);
      expect(data.colors[32], tokens.textFaint);
      expect(data.colors[27], isNot(tokens.textFaint));
    });

    test('geçmiş günler soluk', () {
      final data = build(currentDay: 10);
      expect(data.colors[0].a, lessThan(1.0));
      expect(data.colors[9].a, 1.0);
    });

    test('kayıt yoksa bugün işareti olmaz', () {
      expect(build(currentDay: 0).todayIndex, isNull);
    });

    test('beklenen uzunluğa kırpma geçişin başlangıcını verir', () {
      // Uygulama, döngü çoktan uzamışken açıldığında canlandırma buradan
      // başlıyor: önce tahmin edilen çelenk, sonra bugüne kadar uzayan hâli.
      final data = build(currentDay: 33);
      final start = data.clampedToExpected();
      expect(start.length, 28);
      expect(start.todayIndex, isNull);
      expect(start, isNot(data));
    });

    test('uzamamış döngüde kırpma bir şey değiştirmez', () {
      final data = build(currentDay: 5);
      expect(data.clampedToExpected(), data);
    });

    test('aynı girdi eşit değer üretir', () {
      // Canlandırmanın gereksiz yere tetiklenmemesi buna bağlı.
      expect(build(currentDay: 5), build(currentDay: 5));
      expect(build(currentDay: 5), isNot(build(currentDay: 6)));
    });
  });
}
