import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/session_plan.dart';

void main() {
  const plan = SessionPlan(
    titleKey: 't',
    steps: [
      SessionStep(
        nameKey: 'a',
        descriptionKey: 'ad',
        duration: Duration(minutes: 3),
      ),
      SessionStep(
        nameKey: 'b',
        descriptionKey: 'bd',
        duration: Duration(minutes: 2),
      ),
      SessionStep(
        nameKey: 'c',
        descriptionKey: 'cd',
        duration: Duration(minutes: 1),
      ),
    ],
  );

  group('SessionPlan', () {
    test('toplam süre adımların toplamıdır', () {
      expect(plan.total, const Duration(minutes: 6));
    });

    test('adım başlangıçları birikimlidir', () {
      expect(plan.startOf(0), Duration.zero);
      expect(plan.startOf(1), const Duration(minutes: 3));
      expect(plan.startOf(2), const Duration(minutes: 5));
    });

    test('geçen süreye göre doğru adımı verir', () {
      expect(plan.stepIndexAt(Duration.zero), 0);
      expect(plan.stepIndexAt(const Duration(minutes: 2, seconds: 59)), 0);
      expect(plan.stepIndexAt(const Duration(minutes: 3, seconds: 1)), 1);
      expect(plan.stepIndexAt(const Duration(minutes: 5, seconds: 30)), 2);
    });

    test('adım sınırında bir sonraki adıma geçer', () {
      // 3 dakikalık ilk adımın tam 3. dakikasında artık ikinci adımdayız;
      // aksi hâlde sayaç bir saniye boyunca bitmiş adımda takılı kalırdı.
      expect(plan.stepIndexAt(const Duration(minutes: 3)), 1);
      expect(plan.stepIndexAt(const Duration(minutes: 5)), 2);
    });

    test('seans bitince adım kalmaz', () {
      expect(plan.stepIndexAt(const Duration(minutes: 6)), isNull);
      expect(plan.stepIndexAt(const Duration(minutes: 10)), isNull);
    });

    test('negatif süre ilk adımı verir', () {
      expect(plan.stepIndexAt(const Duration(seconds: -5)), 0);
    });
  });

  group('yoga planı', () {
    test('ekrandaki poz listesiyle aynı uzunlukta', () {
      expect(SessionPlan.yoga.steps.length, 6);
    });

    test('toplam süre 20 dakika', () {
      expect(SessionPlan.yoga.total, const Duration(minutes: 20));
    });

    test('her adımın anahtarları dolu ve süresi pozitif', () {
      for (final step in SessionPlan.yoga.steps) {
        expect(step.nameKey, isNotEmpty);
        expect(step.descriptionKey, isNotEmpty);
        expect(step.duration, greaterThan(Duration.zero));
      }
    });
  });
}
