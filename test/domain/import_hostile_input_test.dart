import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/backup_import_service.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Yedek dosyası, kullanıcının **elle düzenleyebileceği** tek girdi.
///
/// Başka her yer seçici ve düğmelerle sınırlı: döngü uzunluğu 21-45, regl
/// süresi 2-10, takvimde gelecek gün işaretlenemiyor. Yedek ise düz JSON —
/// kullanıcı dışa aktarıp bir satır değiştirip geri yükleyebilir.
///
/// Düşmanca girdilerle denendi: yirmi farklı bozuk giriş (JSON olmayan
/// metin, yanlış tip, null alan, 400 kat iç içe dizi, devasa tarih) hiçbiri
/// çökertmiyordu. Ama iki tanesi **sessizce anlamsız sayı** üretiyordu ve
/// sağlık uygulamasında bu çökmeden kötü — ekranda veri gibi duruyor:
///
/// * Bitişi başlangıcından önce olan kayıt → dönem uzunluğu `-8`.
/// * Yıl 1 tarihli kayıt → ana ekranda "739880. gün", "739851 gün gecikme".
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  String iso(DateTime d) => d.toIso8601String();

  ImportedData importPeriods(String periodsJson) => BackupImportService.merge(
    json: '{"periodLogs": $periodsJson}',
    periodLogs: const [],
    dailyLogs: const [],
    today: today,
    pregnancies: const [],
    careEvents: const [],
  );

  group('makul olmayan tarihler eleniyor', () {
    test('bitişi başlangıcından önce olan kayıt alınmıyor', () {
      final start = today.subtract(const Duration(days: 3));
      final result = importPeriods(
        '[{"id":"a","startDate":"${iso(start)}",'
        '"endDate":"${iso(start.subtract(const Duration(days: 9)))}"}]',
      );

      expect(
        result.periodLogs,
        isEmpty,
        reason: 'Ters kayıt dönem uzunluğunu negatife düşürüyor.',
      );
      expect(result.report.invalid, 1);
    });

    test('elli yıldan eski kayıt alınmıyor', () {
      final ancient = DateTime(1, 1, 1);
      final result = importPeriods(
        '[{"id":"a","startDate":"${iso(ancient)}"}]',
      );

      expect(
        result.periodLogs,
        isEmpty,
        reason: 'Ana ekran altı basamaklı bir döngü günü yazıyordu.',
      );
      expect(result.report.invalid, 1);
    });

    test('sınırın içindeki eski kayıt alınıyor', () {
      // Kural, gerçek geçmişi elemeyecek kadar geniş olmalı.
      final old = DateTime(today.year - 3, today.month, today.day);
      final result = importPeriods('[{"id":"a","startDate":"${iso(old)}"}]');

      expect(result.periodLogs, hasLength(1));
    });

    test('gelecek tarihli günlük kayıt alınmıyor', () {
      final future = today.add(const Duration(days: 900));
      final result = BackupImportService.merge(
        json:
            '{"dailyLogs":[{"date":"${iso(future)}","symptoms":[],"moods":[]}]}',
        periodLogs: const [],
        dailyLogs: const [],
        today: today,
        pregnancies: const [],
        careEvents: const [],
      );

      expect(
        result.dailyLogs,
        isEmpty,
        reason: 'Günlük kayıtta hiç tarih sınırı yoktu.',
      );
    });
  });

  group('bozuk girdi çökertmiyor', () {
    // "Çökmüyor" tek başına yeterli değil ama gerileme olursa burada görülür.
    const hostile = <String>[
      '',
      'merhaba',
      '[1,2,3]',
      '{"periodLogs": "olmaz"}',
      '{"periodLogs":[{"id":"a","startDate":"yarın"}]}',
      '{"periodLogs":[{"id":null,"startDate":null}]}',
      '{"periodLogs":[[[[[]]]]]}',
    ];

    for (final (index, raw) in hostile.indexed) {
      test('girdi #$index', () {
        final result = BackupImportService.merge(
          json: raw,
          periodLogs: const [],
          dailyLogs: const [],
          today: today,
          pregnancies: const [],
          careEvents: const [],
        );
        expect(result.periodLogs, isEmpty);
        expect(result.dailyLogs, isEmpty);
      });
    }
  });

  test('elenen kayıt tahminleri bozmuyor', () {
    // Asıl mesele: bozuk kayıt alınmayınca ekrandaki sayılar sağlam kalıyor.
    final good = PeriodLog(
      id: 'g',
      startDate: today.subtract(const Duration(days: 2)),
    );
    final result = BackupImportService.merge(
      json:
          '{"periodLogs":[{"id":"a","startDate":"${iso(DateTime(1, 1, 1))}"}]}',
      periodLogs: [good],
      dailyLogs: const [],
      today: today,
      pregnancies: const [],
      careEvents: const [],
    );

    final info = PredictionService().getCycleInfo(result.periodLogs);
    expect(info.currentCycleDay, 3);
    expect(info.currentPeriodLength, greaterThan(0));
  });
}
