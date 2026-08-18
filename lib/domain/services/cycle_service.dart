import '../models/period_log.dart';

/// Döngü istatistiklerini hesaplayan servis.
class CycleService {
  /// Ortalama döngü uzunluğunu hesaplar (Son 3 döngü üzerinden).
  /// [defaultLength] yeterli veri olmadığında kullanılacak değer.
  /// Bir döngü sayılacak en kısa aralık.
  ///
  /// Takvimde tek bir gün işaretlemek yeni bir dönem kaydı üretiyor.
  /// Kullanıcı bir düzeltme için reglinin bitiminden birkaç gün sonra bir gün
  /// işaretlediğinde, o birkaç günlük fark "döngü" sayılıp ortalamayı yere
  /// çekiyordu: ortalama 30'dan 20'ye düşüyor, yumurtlama ve doğurganlık
  /// penceresi bir hafta kayıyordu.
  static const int minPlausibleCycleDays = 15;

  /// En uzun aralık. Ötesi döngü değil, takibe ara verilmiş demektir.
  static const int maxPlausibleCycleDays = 90;

  static bool isPlausibleCycleLength(int days) =>
      days >= minPlausibleCycleDays && days <= maxPlausibleCycleDays;

  /// Son üç **makul** döngünün ortalama uzunluğu.
  ///
  /// Makul aralık kalmazsa [defaultLength] döner: uydurma bir ortalama
  /// üretmektense kullanıcının kendi ayarına düşmek doğru.
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
      final gap = nextStart.difference(currentStart).inDays;
      if (isPlausibleCycleLength(gap)) lengths.add(gap);
    }

    if (lengths.isEmpty) return defaultLength;

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
