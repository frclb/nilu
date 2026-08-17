import '../models/cycle_info.dart';
import '../models/period_log.dart';
import 'cycle_service.dart';

/// Gelecek tahminlerini üreten servis.
class PredictionService {
  final CycleService _cycleService = CycleService();

  /// Döngü bilgisini hesaplar.
  /// [userCycleLength] ve [userPeriodLength]: Kullanıcının ayarladığı değerler
  /// (yeterli log verisi yoksa kullanılır).
  /// [settingsUpdatedAt]: Ayarların değiştirildiği tarih. Bu tarihten sonraki
  /// tahminlerde yeni değerler, öncekinde hesaplanan ortalamalar kullanılır.
  CycleInfo getCycleInfo(
    List<PeriodLog> logs, {
    int userCycleLength = 28,
    int userPeriodLength = 5,
    DateTime? settingsUpdatedAt,
  }) {
    final avgLength = _cycleService.calculateAverageCycleLength(
      logs,
      defaultLength: userCycleLength,
    );
    final lastStart = _cycleService.getLastPeriodStart(logs);
    final avgPeriodLength = _calculateAveragePeriodLength(
      logs,
      defaultLength: userPeriodLength,
    );

    // Eğer settingsUpdatedAt varsa ve son regl bu tarihten sonraysa,
    // yeni kullanıcı ayarlarını kullan; değilse hesaplanan ortalamayı kullan.
    int effectiveCycleLength = avgLength;
    int effectivePeriodLength = avgPeriodLength;

    if (settingsUpdatedAt != null && lastStart != null) {
      final cleanUpdatedAt = DateTime(
        settingsUpdatedAt.year,
        settingsUpdatedAt.month,
        settingsUpdatedAt.day,
      );
      final cleanLastStart = DateTime(
        lastStart.year,
        lastStart.month,
        lastStart.day,
      );
      // Son regl, ayar değişikliğinden sonra veya aynı gündeyse yeni ayarları kullan
      if (cleanLastStart.isAtSameMomentAs(cleanUpdatedAt) ||
          cleanLastStart.isAfter(cleanUpdatedAt)) {
        effectiveCycleLength = userCycleLength;
        effectivePeriodLength = userPeriodLength;
      }
    }

    if (lastStart == null) {
      return CycleInfo(
        averageCycleLength: effectiveCycleLength,
        averagePeriodLength: effectivePeriodLength,
      );
    }

    final nextPeriod = lastStart.add(Duration(days: effectiveCycleLength));

    // Yumurtlama: Döngü uzunluğu - 14 gün
    final ovulation = lastStart.add(Duration(days: effectiveCycleLength - 14));

    // Doğurganlık penceresi: Yumurtlama -5 gün → Yumurtlama +1 gün (tıbbi standart)
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    // İleri 3 döngü tahmini — bunlar her zaman kullanıcı ayarlarını kullanır
    // (gelecekteki döngüler settingsUpdatedAt'ten sonra olacak)
    final futureCycleLength = userCycleLength;
    final futurePredictions = <PredictedCycle>[];
    for (int i = 1; i <= 3; i++) {
      final futureStart = nextPeriod.add(Duration(days: futureCycleLength * i));
      final futureOvulation = futureStart.subtract(const Duration(days: 14));
      futurePredictions.add(
        PredictedCycle(
          startDate: futureStart,
          ovulationDay: futureOvulation,
          fertileStart: futureOvulation.subtract(const Duration(days: 5)),
          fertileEnd: futureOvulation.add(const Duration(days: 1)),
        ),
      );
    }

    return CycleInfo(
      averageCycleLength: effectiveCycleLength,
      averagePeriodLength: effectivePeriodLength,
      lastPeriodStart: lastStart,
      predictedNextPeriod: nextPeriod,
      ovulationDay: ovulation,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      futurePredictions: futurePredictions,
    );
  }

  /// Ortalama regl süresini hesaplar.
  ///
  /// Yalnızca **tamamlanmış** dönemler sayılır: devam eden bir dönemin gerçek
  /// uzunluğu henüz bilinmediğinden, onu sabit bir değerle hesaba katmak
  /// ortalamayı kullanıcının gerçek verisinden saptırır.
  /// [defaultLength] yeterli veri olmadığında kullanılacak değer.
  int _calculateAveragePeriodLength(
    List<PeriodLog> logs, {
    int defaultLength = 5,
  }) {
    final lengths = logs
        .map((l) => l.completedLength)
        .whereType<int>()
        .toList();
    if (lengths.isEmpty) return defaultLength;

    // Son 3 tamamlanmış dönem
    final recent = lengths.length > 3
        ? lengths.sublist(lengths.length - 3)
        : lengths;
    final sum = recent.reduce((a, b) => a + b);
    return (sum / recent.length).round().clamp(1, 10);
  }
}
