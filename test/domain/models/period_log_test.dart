import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/period_log.dart';

PeriodLog log(String id, DateTime start, [DateTime? end]) =>
    PeriodLog(id: id, startDate: start, endDate: end);

void main() {
  group('PeriodLog.completedLength', () {
    test('devam eden dönemde null döner', () {
      final l = log('1', DateTime(2026, 1, 1));
      expect(l.isOngoing, isTrue);
      expect(l.completedLength, isNull);
    });

    test('tamamlanmış dönemde gün sayısı kapsayıcıdır', () {
      expect(
        log('1', DateTime(2026, 1, 1), DateTime(2026, 1, 5)).completedLength,
        5,
      );
      expect(
        log('2', DateTime(2026, 1, 1), DateTime(2026, 1, 1)).completedLength,
        1,
      );
    });
  });

  group('PeriodLog.contains — tamamlanmış dönem', () {
    final l = log('1', DateTime(2026, 3, 10), DateTime(2026, 3, 14));

    test('sınırlar dahildir', () {
      expect(l.contains(DateTime(2026, 3, 10)), isTrue);
      expect(l.contains(DateTime(2026, 3, 14)), isTrue);
    });

    test('aralık dışı günler hariçtir', () {
      expect(l.contains(DateTime(2026, 3, 9)), isFalse);
      expect(l.contains(DateTime(2026, 3, 15)), isFalse);
    });

    test('günün saati sonucu değiştirmez', () {
      expect(l.contains(DateTime(2026, 3, 14, 23, 59)), isTrue);
    });
  });

  group('PeriodLog.contains — devam eden dönem', () {
    final l = log('1', DateTime(2026, 3, 10));

    test('varsayılan projeksiyon 5 gündür', () {
      expect(l.contains(DateTime(2026, 3, 14)), isTrue);
      expect(l.contains(DateTime(2026, 3, 15)), isFalse);
    });

    test('kullanıcının regl süresi ayarı projeksiyonu belirler', () {
      // Regresyon: bu değer eskiden 5'e sabitlenmişti ve kullanıcı ayarı
      // yoksayılıyordu.
      expect(l.contains(DateTime(2026, 3, 16), ongoingLength: 7), isTrue);
      expect(l.contains(DateTime(2026, 3, 17), ongoingLength: 7), isFalse);

      expect(l.contains(DateTime(2026, 3, 12), ongoingLength: 3), isTrue);
      expect(l.contains(DateTime(2026, 3, 13), ongoingLength: 3), isFalse);
    });

    test('geçersiz uzunluk en az 1 güne çekilir', () {
      expect(l.contains(DateTime(2026, 3, 10), ongoingLength: 0), isTrue);
      expect(l.contains(DateTime(2026, 3, 11), ongoingLength: 0), isFalse);
    });
  });

  group('serileştirme', () {
    test('toJson/fromJson gidiş-dönüşü veriyi korur', () {
      final original = log('abc', DateTime(2026, 5, 2), DateTime(2026, 5, 6));
      final restored = PeriodLog.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.startDate, original.startDate);
      expect(restored.endDate, original.endDate);
    });

    test('devam eden dönem gidiş-dönüşte devam eden kalır', () {
      final restored = PeriodLog.fromJson(
        log('abc', DateTime(2026, 5, 2)).toJson(),
      );
      expect(restored.isOngoing, isTrue);
      expect(restored.endDate, isNull);
    });
  });
}
