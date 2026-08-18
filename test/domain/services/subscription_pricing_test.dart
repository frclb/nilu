import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/subscription_pricing.dart';

SubscriptionPlan plan(String id, PlanPeriod period, double price) =>
    SubscriptionPlan(
      id: id,
      period: period,
      price: price,
      priceString: price.toStringAsFixed(2),
    );

void main() {
  group('aylık eşdeğer', () {
    test('yıllık plan on ikiye bölünür', () {
      expect(
        plan('y', PlanPeriod.annual, 360).monthlyEquivalent,
        closeTo(30, 0.01),
      );
    });

    test('haftalık plan yılın gerçek ay uzunluğunu kullanır', () {
      // 4 hafta = 1 ay varsayımı yıllık karşılaştırmayı ~%8 saptırıyordu.
      expect(
        plan('w', PlanPeriod.weekly, 10).monthlyEquivalent,
        closeTo(43.45, 0.1),
      );
    });
  });

  group('tasarruf yüzdesi', () {
    final weekly = plan('w', PlanPeriod.weekly, 15); // ~65,2/ay
    final monthly = plan('m', PlanPeriod.monthly, 50);
    final annual = plan('y', PlanPeriod.annual, 360); // 30/ay

    test('en pahalı plana göre hesaplanır', () {
      final all = [weekly, monthly, annual];
      // 65,2 → 30 ≈ %54
      expect(SubscriptionPricing.savingPercent(annual, all), closeTo(54, 1));
    });

    test('referans planın kendisi rozet almaz', () {
      final all = [weekly, monthly, annual];
      expect(SubscriptionPricing.savingPercent(weekly, all), isNull);
    });

    test('önemsiz fark rozet üretmez', () {
      // "%2 tasarruf" gürültüden ibaret.
      final a = plan('a', PlanPeriod.monthly, 100);
      final b = plan('b', PlanPeriod.monthly, 98);
      expect(SubscriptionPricing.savingPercent(b, [a, b]), isNull);
    });

    test('tek plan varken karşılaştırma yapılmaz', () {
      expect(SubscriptionPricing.savingPercent(annual, [annual]), isNull);
    });
  });

  group('öneri ve sıralama', () {
    test('aylık maliyeti en düşük plan önerilir', () {
      final weekly = plan('w', PlanPeriod.weekly, 15);
      final annual = plan('y', PlanPeriod.annual, 360);

      expect(SubscriptionPricing.best([weekly, annual])?.id, 'y');
    });

    test('plan yokken öneri yok', () {
      expect(SubscriptionPricing.best(const []), isNull);
    });

    test('uzun süreli plan üstte gelir', () {
      final weekly = plan('w', PlanPeriod.weekly, 15);
      final monthly = plan('m', PlanPeriod.monthly, 50);
      final annual = plan('y', PlanPeriod.annual, 360);

      expect(
        SubscriptionPricing.sorted([
          monthly,
          weekly,
          annual,
        ]).map((p) => p.id).toList(),
        ['y', 'm', 'w'],
      );
    });

    test('sıralama girdiyi değiştirmez', () {
      final input = [
        plan('m', PlanPeriod.monthly, 50),
        plan('y', PlanPeriod.annual, 360),
      ];
      SubscriptionPricing.sorted(input);
      expect(input.map((p) => p.id).toList(), ['m', 'y']);
    });
  });
}
