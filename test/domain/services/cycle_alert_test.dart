import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/cycle_alert.dart';
import 'package:period_tracker/domain/services/insights_service.dart';

List<CycleLengthPoint> points(List<int> lengths) => [
  for (var i = 0; i < lengths.length; i++)
    CycleLengthPoint(
      startDate: DateTime(2026, 1, 1).add(Duration(days: 30 * i)),
      lengthInDays: lengths[i],
    ),
];

void main() {
  group('CycleAlertService', () {
    test('yetersiz kayıtta uyarı üretilmez', () {
      // İlk döngüsünü kaydeden kullanıcıya "düzensizsin" demek hem yanlış
      // hem ürkütücü olurdu.
      expect(
        CycleAlertService.evaluate(points([20, 20]), breaks: const []),
        isEmpty,
      );
      expect(CycleAlertService.evaluate(points([]), breaks: const []), isEmpty);
    });

    test('olağan aralıktaki düzenli döngüler uyarı vermez', () {
      expect(
        CycleAlertService.evaluate(points([28, 29, 28, 30]), breaks: const []),
        isEmpty,
      );
    });

    test('sürekli kısa döngüler uyarı verir', () {
      final alerts = CycleAlertService.evaluate(
        points([21, 22, 20]),
        breaks: const [],
      );
      expect(alerts, contains(CycleAlert.consistentlyShort));
    });

    test('sürekli uzun döngüler uyarı verir', () {
      final alerts = CycleAlertService.evaluate(
        points([40, 42, 45]),
        breaks: const [],
      );
      expect(alerts, contains(CycleAlert.consistentlyLong));
    });

    test('tek bir kısa döngü uyarı vermez', () {
      // "Düzenli olarak" kısa olması gerekiyor; bir seferlik sapma
      // stres, hastalık ya da seyahatle açıklanabilir.
      final alerts = CycleAlertService.evaluate(
        points([21, 28, 29]),
        breaks: const [],
      );
      expect(alerts, isNot(contains(CycleAlert.consistentlyShort)));
    });

    test('belirgin oynama uyarı verir', () {
      final alerts = CycleAlertService.evaluate(
        points([25, 34, 28]),
        breaks: const [],
      );
      expect(alerts, contains(CycleAlert.highlyVariable));
    });

    test('küçük oynama uyarı vermez', () {
      final alerts = CycleAlertService.evaluate(
        points([28, 30, 29]),
        breaks: const [],
      );
      expect(alerts, isNot(contains(CycleAlert.highlyVariable)));
    });

    test('sınır değerler uyarı vermez', () {
      // 24 ve 38 dâhil olmak üzere olağan aralık.
      final alerts = CycleAlertService.evaluate(
        points([24, 24, 24]),
        breaks: const [],
      );
      expect(alerts, isNot(contains(CycleAlert.consistentlyShort)));

      final long = CycleAlertService.evaluate(
        points([38, 38, 38]),
        breaks: const [],
      );
      expect(long, isNot(contains(CycleAlert.consistentlyLong)));
    });

    test('kısa ve oynak aynı anda bildirilebilir', () {
      final alerts = CycleAlertService.evaluate(
        points([15, 23, 18]),
        breaks: const [],
      );
      expect(alerts, contains(CycleAlert.consistentlyShort));
      expect(alerts, contains(CycleAlert.highlyVariable));
    });

    test('her uyarının başlık ve gövde anahtarı var', () {
      for (final alert in CycleAlert.values) {
        expect(CycleAlertService.titleKey(alert), isNotEmpty);
        expect(CycleAlertService.bodyKey(alert), isNotEmpty);
      }
    });
  });
}
