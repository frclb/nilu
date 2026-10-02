import '../models/period_log.dart';
import 'cycle_intervals.dart';

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
  static const int minPlausibleCycleDays = CycleIntervals.minPlausibleDays;

  /// En uzun aralık. Ötesi döngü değil, takibe ara verilmiş demektir.
  static const int maxPlausibleCycleDays = CycleIntervals.maxPlausibleDays;

  static bool isPlausibleCycleLength(int days) =>
      CycleIntervals.isPlausible(days);

  /// Son üç **makul** döngünün ortalama uzunluğu.
  ///
  /// Makul aralık kalmazsa [defaultLength] döner: uydurma bir ortalama
  /// üretmektense kullanıcının kendi ayarına düşmek doğru.
  int calculateAverageCycleLength(
    List<PeriodLog> logs, {
    int defaultLength = 28,
    List<DateSpan> breaks = const [],
  }) {
    // Aralık hesabı tek yerde (bkz. `CycleIntervals`): önceden burada ayrı
    // bir döngü vardı ve makul sınırlar iki dosyada ayrı sabitlerdi.
    final lengths = CycleIntervals.of(
      logs,
      breaks: breaks,
    ).map((p) => p.lengthInDays).toList();

    if (lengths.isEmpty) return defaultLength;

    // Son 3 döngünün ortalaması
    final lastThree = lengths.length > 3
        ? lengths.sublist(lengths.length - 3)
        : lengths;
    final sum = lastThree.reduce((a, b) => a + b);

    return (sum / lastThree.length).round();
  }

  /// Yeni döngünün dayanağı olabilecek son regl başlangıcı.
  ///
  /// Gebelik ya da lohusalık kesintisinin **öncesindeki** başlangıç bu
  /// dayanak olamaz: doğumdan sonra ilk regl gelene dek son kayıt gebelik
  /// öncesi SAT, ve ondan ileri saymak "reglin 250 gün gecikti" demek.
  DateTime? getLastPeriodStart(
    List<PeriodLog> logs, {
    List<DateSpan> breaks = const [],
  }) {
    final usable = CycleIntervals.usableStarts(logs, breaks: breaks);
    return usable.isEmpty ? null : usable.last;
  }
}
