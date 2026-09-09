import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/period_service.dart';

DateTime d(int day, {int month = 4}) => DateTime(2026, month, day);

PeriodLog block(String id, int startDay, int? endDay) => PeriodLog(
  id: id,
  startDate: d(startDay),
  endDate: endDay == null ? null : d(endDay),
);

/// Testlerin okunabilirliği için [start, end] gün çiftlerine indirger.
List<List<int?>> spans(List<PeriodLog> logs) =>
    logs.map((l) => <int?>[l.startDate.day, l.endDate?.day]).toList();

void main() {
  final service = PeriodService();

  group('toggleDay — ekleme', () {
    test('boş listede tek günlük dönem oluşturur', () {
      final result = service.toggleDay([], d(10));
      expect(spans(result), [
        [10, 10],
      ]);
    });

    test('bir önceki güne bitişikse önceki dönemi uzatır', () {
      final result = service.toggleDay([block('a', 8, 10)], d(11));
      expect(spans(result), [
        [8, 11],
      ]);
    });

    test('bir sonraki güne bitişikse sonraki dönemin başını öne çeker', () {
      final result = service.toggleDay([block('a', 12, 14)], d(11));
      expect(spans(result), [
        [11, 14],
      ]);
    });

    test('iki dönemin arasındaki tek boşluğu doldurup birleştirir', () {
      final result = service.toggleDay([
        block('a', 8, 10),
        block('b', 12, 14),
      ], d(11));
      expect(spans(result), [
        [8, 14],
      ]);
    });

    test('bitişik olmayan gün ayrı bir dönem olur', () {
      final result = service.toggleDay([block('a', 1, 3)], d(10));
      expect(spans(result), [
        [1, 3],
        [10, 10],
      ]);
    });
  });

  group('toggleDay — kaldırma', () {
    test('tek günlük dönemi tamamen siler', () {
      final result = service.toggleDay([block('a', 10, 10)], d(10));
      expect(result, isEmpty);
    });

    test('baştaki günü kaldırınca başlangıç bir gün ileri kayar', () {
      final result = service.toggleDay([block('a', 10, 14)], d(10));
      expect(spans(result), [
        [11, 14],
      ]);
    });

    test('sondaki günü kaldırınca bitiş bir gün geri kayar', () {
      final result = service.toggleDay([block('a', 10, 14)], d(14));
      expect(spans(result), [
        [10, 13],
      ]);
    });

    test('ortadaki günü kaldırınca dönemi ikiye böler', () {
      final result = service.toggleDay([block('a', 10, 14)], d(12));
      expect(spans(result), [
        [10, 11],
        [13, 14],
      ]);
    });
  });

  group('toggleDay — devam eden dönem', () {
    test('projeksiyon uzunluğu kullanıcı ayarına uyar', () {
      // 10 Nisan'da başlayan, bitmemiş bir dönem.
      // 7 günlük ayarla 16 Nisan hâlâ dönemin içindedir; 5 günlük ayarla değil.
      final ongoing = [block('a', 10, null)];

      final withSevenDaySetting = service.toggleDay(
        ongoing,
        d(16),
        ongoingLength: 7,
      );
      // Dönemin içindeydi → kaldırma yolu çalışır. Devam eden kayıtta o günden
      // sonrası veri değil projeksiyon olduğu için kayıt bölünmez, bir önceki
      // günde kapanır; bölmek yarın başlayan hayalet bir dönem bırakıyordu.
      expect(spans(withSevenDaySetting), [
        [10, 15],
      ]);

      final withFiveDaySetting = service.toggleDay(
        [block('a', 10, null)],
        d(16),
        ongoingLength: 5,
      );
      // Dönemin dışındaydı → yeni bağımsız gün eklenir.
      expect(spans(withFiveDaySetting), [
        [10, null],
        [16, 16],
      ]);
    });
  });

  test('toggleDay girdi listesini yerinde değiştirmez', () {
    final original = [block('a', 10, 14)];
    service.toggleDay(original, d(12));
    expect(spans(original), [
      [10, 14],
    ]);
  });

  test('toggleDay sonucu başlangıç tarihine göre sıralıdır', () {
    final result = service.toggleDay([block('a', 20, 22)], d(1));
    expect(result.first.startDate.isBefore(result.last.startDate), isTrue);
  });

  group('getLastPeriodStartBefore', () {
    test('log yokken null döner', () {
      expect(service.getLastPeriodStartBefore([], d(10)), isNull);
    });

    test('verilen tarihten sonraki dönemleri yok sayar', () {
      final logs = [block('a', 1, 3), block('b', 20, 22)];
      expect(service.getLastPeriodStartBefore(logs, d(10)), d(1));
    });

    test('aynı gün başlayan dönemi dahil eder', () {
      expect(
        service.getLastPeriodStartBefore([block('a', 10, 12)], d(10)),
        d(10),
      );
    });

    test('tüm dönemler sonraysa null döner', () {
      expect(
        service.getLastPeriodStartBefore([block('a', 20, 22)], d(10)),
        isNull,
      );
    });
  });
}
