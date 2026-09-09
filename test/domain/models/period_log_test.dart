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

  group('PeriodLog.containsRecorded — tamamlanmış dönem', () {
    final l = log('1', DateTime(2026, 3, 10), DateTime(2026, 3, 14));

    test('sınırlar dahildir', () {
      expect(l.containsRecorded(DateTime(2026, 3, 10)), isTrue);
      expect(l.containsRecorded(DateTime(2026, 3, 14)), isTrue);
    });

    test('aralık dışı günler hariçtir', () {
      expect(l.containsRecorded(DateTime(2026, 3, 9)), isFalse);
      expect(l.containsRecorded(DateTime(2026, 3, 15)), isFalse);
    });

    test('günün saati sonucu değiştirmez', () {
      expect(l.containsRecorded(DateTime(2026, 3, 14, 23, 59)), isTrue);
    });

    test('bugün kayıt aralığını etkilemez', () {
      expect(
        l.containsRecorded(DateTime(2026, 3, 14), today: DateTime(2026, 3, 11)),
        isTrue,
      );
    });
  });

  group('PeriodLog.containsRecorded — devam eden dönem', () {
    final l = log('1', DateTime(2026, 3, 10));
    final today = DateTime(2026, 3, 12);

    test('kayıt bugüne kadar uzanır', () {
      expect(l.containsRecorded(DateTime(2026, 3, 10), today: today), isTrue);
      expect(l.containsRecorded(DateTime(2026, 3, 12), today: today), isTrue);
    });

    test('bugünden sonrası kayıt değildir', () {
      // Regresyon: burada kullanıcının regl süresi kadar ileri bir projeksiyon
      // vardı ve takvim o günleri gerçek kayıtmış gibi koyu boyuyordu.
      expect(l.containsRecorded(DateTime(2026, 3, 13), today: today), isFalse);
      expect(l.containsRecorded(DateTime(2026, 3, 14), today: today), isFalse);
    });

    test('başlangıçtan önceki günler hariçtir', () {
      expect(l.containsRecorded(DateTime(2026, 3, 9), today: today), isFalse);
    });

    test('recordedLength bugüne kadar geçen günü sayar', () {
      expect(l.recordedLength(today: today), 3);
      expect(l.recordedLength(today: DateTime(2026, 3, 10)), 1);
    });
  });

  group('PeriodLog.isExpectedContinuation', () {
    final ongoing = log('1', DateTime(2026, 3, 10));
    final today = DateTime(2026, 3, 12);

    test('bugünden sonraki beklenen günler', () {
      expect(
        ongoing.isExpectedContinuation(
          DateTime(2026, 3, 13),
          today: today,
          expectedLength: 5,
        ),
        isTrue,
      );
      expect(
        ongoing.isExpectedContinuation(
          DateTime(2026, 3, 14),
          today: today,
          expectedLength: 5,
        ),
        isTrue,
      );
    });

    test('beklenen uzunluğun ötesi beklenti de değildir', () {
      expect(
        ongoing.isExpectedContinuation(
          DateTime(2026, 3, 15),
          today: today,
          expectedLength: 5,
        ),
        isFalse,
      );
    });

    test('kullanıcının regl süresi ayarı beklentiyi belirler', () {
      expect(
        ongoing.isExpectedContinuation(
          DateTime(2026, 3, 16),
          today: today,
          expectedLength: 7,
        ),
        isTrue,
      );
      expect(
        ongoing.isExpectedContinuation(
          DateTime(2026, 3, 17),
          today: today,
          expectedLength: 7,
        ),
        isFalse,
      );
    });

    test('kayıtlı günler beklenti sayılmaz', () {
      expect(
        ongoing.isExpectedContinuation(DateTime(2026, 3, 12), today: today),
        isFalse,
      );
    });

    test('tamamlanmış dönemin beklenen devamı yoktur', () {
      final closed = log('1', DateTime(2026, 3, 10), DateTime(2026, 3, 11));
      expect(
        closed.isExpectedContinuation(DateTime(2026, 3, 12), today: today),
        isFalse,
      );
    });

    test('geçersiz uzunluk en az 1 güne çekilir', () {
      final startedToday = log('1', DateTime(2026, 3, 12));
      expect(
        startedToday.isExpectedContinuation(
          DateTime(2026, 3, 13),
          today: today,
          expectedLength: 0,
        ),
        isFalse,
      );
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
