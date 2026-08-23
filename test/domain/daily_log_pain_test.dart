import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';

void main() {
  group('DailyLog ağrı alanları', () {
    test('varsayılan olarak ağrı kaydı yok', () {
      final log = DailyLog(date: DateTime(2026, 5, 1));
      expect(log.painLevel, isNull);
      expect(log.painLimitedActivity, isFalse);
    });

    test('kaydedilip geri okunur', () {
      final log = DailyLog(
        date: DateTime(2026, 5, 1),
        painLevel: 'severe',
        painLimitedActivity: true,
      );
      final restored = DailyLog.fromMap(log.toMap());
      expect(restored.painLevel, 'severe');
      expect(restored.painLimitedActivity, isTrue);
    });

    test('eski kayıtlar ağrı alanı olmadan okunabilir', () {
      // Bu alanlar sonradan eklendi; mevcut kullanıcıların kayıtları
      // okunamaz hâle gelmemeli.
      final old = {
        'date': DateTime(2026, 5, 1).toIso8601String(),
        'symptoms': ['cramp'],
        'moods': <String>[],
      };
      final log = DailyLog.fromMap(old);
      expect(log.painLevel, isNull);
      expect(log.painLimitedActivity, isFalse);
      expect(log.symptoms, ['cramp']);
    });

    test('tanınmayan ağrı kodu düşer', () {
      // Diğer alanlarla aynı davranış: kod sözlükte yoksa değer atılır.
      // Ağrı yeni bir alan olduğu için çevrilmiş etiketle kaydedilmiş eski
      // veri yok; uydurma bir eşleme kurmak yanlış olurdu.
      final log = DailyLog.fromMap({
        'date': DateTime(2026, 5, 1).toIso8601String(),
        'painLevel': 'bilinmeyen',
      });
      expect(log.painLevel, isNull);
    });

    test('geçerli kod korunur', () {
      final log = DailyLog.fromMap({
        'date': DateTime(2026, 5, 1).toIso8601String(),
        'painLevel': 'moderate',
      });
      expect(log.painLevel, 'moderate');
    });

    test('üç kademe tanımlı ve anahtarları benzersiz', () {
      expect(LogVocabulary.painLevels.length, 3);
      final keys = LogVocabulary.painLevels
          .map(LogVocabulary.painLevelKey)
          .toSet();
      expect(keys.length, 3);
    });
  });
}
