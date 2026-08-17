import '../models/period_log.dart';

/// Döngü istatistiklerini hesaplayan servis.
class CycleService {
  /// Ortalama döngü uzunluğunu hesaplar (Son 3 döngü üzerinden).
  /// [defaultLength] yeterli veri olmadığında kullanılacak değer.
  int calculateAverageCycleLength(
    List<PeriodLog> logs, {
    int defaultLength = 28,
  }) {
    // Yeterli veri yoksa kullanıcı ayarı veya varsayılan
    if (logs.length < 2) {
      return defaultLength;
    }

    // Tarihe göre sırala
    final sortedLogs = List<PeriodLog>.from(logs)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    List<int> lengths = [];
    for (int i = 0; i < sortedLogs.length - 1; i++) {
      final currentStart = sortedLogs[i].startDate;
      final nextStart = sortedLogs[i + 1].startDate;
      lengths.add(nextStart.difference(currentStart).inDays);
    }

    if (lengths.isEmpty) return 28;

    // Son 3 döngünün ortalaması
    final lastThree = lengths.length > 3
        ? lengths.sublist(lengths.length - 3)
        : lengths;
    final sum = lastThree.reduce((a, b) => a + b);

    return (sum / lastThree.length).round();
  }

  /// Son regl başlangıcını döndürür.
  DateTime? getLastPeriodStart(List<PeriodLog> logs) {
    if (logs.isEmpty) return null;
    return logs.map((l) => l.startDate).reduce((a, b) => a.isAfter(b) ? a : b);
  }
}
