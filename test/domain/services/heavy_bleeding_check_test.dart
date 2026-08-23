import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/heavy_bleeding_check.dart';

void main() {
  group('HeavyBleedingCheck', () {
    test('hiçbir işaret yoksa yönlendirme yapılmaz', () {
      final r = HeavyBleedingCheck.evaluate([]);
      expect(r.isEmpty, isTrue);
      expect(r.shouldSeeClinician, isFalse);
      expect(r.suggestsIronCheck, isFalse);
    });

    test('tek işaret bile hekime yönlendirir', () {
      // NHS bir eşik sayısı vermiyor: "bunlardan herhangi biri varsa yoğun
      // kanaman olabilir". Sayı uydurmak kaynağın söylemediği bir kesinlik
      // iddia etmek olurdu.
      final r = HeavyBleedingCheck.evaluate([HeavyBleedingSign.largeClots]);
      expect(r.shouldSeeClinician, isTrue);
    });

    test('yorgunluk tek başına demir uyarısı vermez', () {
      // Yorgunluğun tek başına sayısız nedeni var; yoğun kanamayla birlikte
      // olduğunda anlamlı.
      final r = HeavyBleedingCheck.evaluate([
        HeavyBleedingSign.tirednessOrBreathlessness,
      ]);
      expect(r.suggestsIronCheck, isFalse);
    });

    test('yorgunluk + kanama işareti demir kontrolü önerir', () {
      final r = HeavyBleedingCheck.evaluate([
        HeavyBleedingSign.tirednessOrBreathlessness,
        HeavyBleedingSign.frequentChanges,
      ]);
      expect(r.suggestsIronCheck, isTrue);
    });

    test('yorgunluk olmadan demir uyarısı verilmez', () {
      final r = HeavyBleedingCheck.evaluate([
        HeavyBleedingSign.frequentChanges,
        HeavyBleedingSign.largeClots,
      ]);
      expect(r.shouldSeeClinician, isTrue);
      expect(r.suggestsIronCheck, isFalse);
    });

    test('aynı işaret iki kez sayılmaz', () {
      final r = HeavyBleedingCheck.evaluate([
        HeavyBleedingSign.largeClots,
        HeavyBleedingSign.largeClots,
      ]);
      expect(r.signs.length, 1);
    });

    test('her işaretin çeviri anahtarı var ve benzersiz', () {
      final keys = HeavyBleedingCheck.allSigns
          .map(HeavyBleedingResult.signKey)
          .toList();
      expect(keys.every((k) => k.isNotEmpty), isTrue);
      expect(keys.toSet().length, keys.length);
    });

    test('NHS listesindeki yedi işaret de var', () {
      expect(HeavyBleedingCheck.allSigns.length, 7);
    });
  });
}
