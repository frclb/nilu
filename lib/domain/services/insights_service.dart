import '../models/daily_log.dart';
import '../models/period_log.dart';

/// Gözlenmiş bir döngünün uzunluğu.
///
/// "Gözlenmiş" kelimesi önemli: tahmin değil, kullanıcının işaretlediği iki
/// ardışık regl başlangıcı arasındaki gerçek gün sayısı.
class CycleLengthPoint {
  /// Döngünün başladığı gün (regl ilk günü).
  final DateTime startDate;

  /// Bir sonraki regl başlangıcına kadar geçen gün sayısı.
  final int lengthInDays;

  const CycleLengthPoint({required this.startDate, required this.lengthInDays});
}

/// Bir semptomun ne sıklıkta kaydedildiği.
class SymptomFrequency {
  /// Dilden bağımsız semptom kodu (bkz. `LogVocabulary`).
  final String code;

  /// Semptomun kaydedildiği gün sayısı.
  final int dayCount;

  /// Payda: kullanıcının herhangi bir kayıt girdiği gün sayısı.
  final int loggedDayCount;

  const SymptomFrequency({
    required this.code,
    required this.dayCount,
    required this.loggedDayCount,
  });

  /// 0–100 arası yüzde. Payda sıfırsa 0.
  int get percentage {
    if (loggedDayCount == 0) return 0;
    return ((dayCount / loggedDayCount) * 100).round();
  }
}

/// İçgörüler ekranının tüm hesapları.
///
/// Ekran bileşenlerinden ayrı tutuldu: burada widget ağacı kurmadan, gerçek
/// veri desenleriyle (tek döngü, kayıt yok, takip arası boşluk) test edilebilir.
///
/// Hiçbir fonksiyon veri uydurmaz — yeterli kayıt yoksa boş liste döner ve
/// ekran boş durumu gösterir. Bu ekran sağlık verisi sunuyor; "makul görünen"
/// bir sayı, yanlış sayıdan daha tehlikeli.
class InsightsService {
  /// Bir "döngü" sayılacak en uzun aralık.
  ///
  /// Bunun ötesi döngü değil, takibe ara verilmiş demektir; grafiğe konursa
  /// ölçeği bozar ve kullanıcıya 200 günlük bir döngü geçirmiş gibi görünür.
  static const int maxPlausibleCycleDays = 90;

  /// En kısa aralık. Altındaki kayıtlar aynı reglin iki parçası olarak
  /// işaretlenmiş demektir.
  static const int minPlausibleCycleDays = 15;

  /// Tamamlanmış döngülerin uzunlukları, eskiden yeniye sıralı.
  ///
  /// Son döngü listede yoktur: bitmesi için bir sonraki reglin başlaması
  /// gerekir. Yani N regl kaydı en fazla N-1 nokta üretir.
  static List<CycleLengthPoint> cycleLengths(
    List<PeriodLog> logs, {
    int limit = 6,
  }) {
    if (logs.length < 2) return const [];

    final starts = logs.map((l) => _dateOnly(l.startDate)).toList()..sort();

    final points = <CycleLengthPoint>[];
    for (var i = 0; i < starts.length - 1; i++) {
      final length = starts[i + 1].difference(starts[i]).inDays;
      if (length < minPlausibleCycleDays || length > maxPlausibleCycleDays) {
        continue;
      }
      points.add(
        CycleLengthPoint(startDate: starts[i], lengthInDays: length),
      );
    }

    if (points.length <= limit) return points;
    return points.sublist(points.length - limit);
  }

  /// Döngü uzunluklarının ortalaması. Nokta yoksa null.
  static int? averageLength(List<CycleLengthPoint> points) {
    if (points.isEmpty) return null;
    final total = points.fold<int>(0, (sum, p) => sum + p.lengthInDays);
    return (total / points.length).round();
  }

  /// En kısa ve en uzun döngü arasındaki fark. İki noktadan az varsa null.
  ///
  /// Düzenlilik göstergesi: 0–3 gün dar, 8+ gün belirgin değişkenlik.
  static int? variation(List<CycleLengthPoint> points) {
    if (points.length < 2) return null;
    var min = points.first.lengthInDays;
    var max = points.first.lengthInDays;
    for (final p in points) {
      if (p.lengthInDays < min) min = p.lengthInDays;
      if (p.lengthInDays > max) max = p.lengthInDays;
    }
    return max - min;
  }

  /// Semptom sıklıkları, çoktan aza sıralı.
  ///
  /// [since] verilirse yalnızca o tarihten sonraki kayıtlar sayılır.
  /// Payda, aralıktaki **dolu** kayıt sayısıdır: boş `DailyLog` nesneleri
  /// (takvim seçildiğinde oluşan ama hiçbir şey girilmeyen günler) sayılmaz,
  /// yoksa her yüzde yapay olarak düşük çıkar.
  static List<SymptomFrequency> symptomFrequencies(
    List<DailyLog> logs, {
    int limit = 4,
    DateTime? since,
  }) {
    final relevant = logs.where((log) {
      if (since != null && log.date.isBefore(since)) return false;
      return _hasContent(log);
    }).toList();

    if (relevant.isEmpty) return const [];

    final counts = <String, int>{};
    for (final log in relevant) {
      // Aynı semptom bir günde iki kez sayılmasın.
      for (final code in log.symptoms.toSet()) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }

    final result =
        counts.entries
            .map(
              (e) => SymptomFrequency(
                code: e.key,
                dayCount: e.value,
                loggedDayCount: relevant.length,
              ),
            )
            .toList()
          // Eşitlikte kod adına göre: sıralama kayıt sırasına göre
          // oynamasın, ekran her açılışta aynı görünsün.
          ..sort((a, b) {
            final byCount = b.dayCount.compareTo(a.dayCount);
            return byCount != 0 ? byCount : a.code.compareTo(b.code);
          });

    if (result.length <= limit) return result;
    return result.sublist(0, limit);
  }

  /// Semptom yüzdelerinin dayandığı kayıtlı gün sayısı.
  static int loggedDayCount(List<DailyLog> logs, {DateTime? since}) {
    return logs.where((log) {
      if (since != null && log.date.isBefore(since)) return false;
      return _hasContent(log);
    }).length;
  }

  static bool _hasContent(DailyLog log) {
    return log.symptoms.isNotEmpty ||
        log.moods.isNotEmpty ||
        log.flowIntensity != null ||
        (log.notes != null && log.notes!.isNotEmpty);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
