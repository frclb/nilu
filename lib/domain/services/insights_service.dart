import '../models/cycle_info.dart';
import '../models/daily_log.dart';
import '../models/period_log.dart';
import 'cycle_intervals.dart';

export 'cycle_intervals.dart' show CycleLengthPoint, DateSpan, CycleBreaks;

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

/// Döngü düzeninin değerlendirmesi.
///
/// Bu bir teşhis değil; yalnızca kullanıcının kendi kayıtlarının ne kadar
/// oynadığını söyler. Uygulamanın hekim yerine geçmesi söz konusu değil.
enum CycleRegularity {
  /// Uçlar arası 0–3 gün.
  steady,

  /// 4–7 gün. Normal aralıkta; stres, uyku ve seyahat bu kadarını açıklar.
  typical,

  /// 8+ gün. Kullanıcının bilmesi ve isterse hekime danışması iyi olur.
  irregular;

  bool get shouldSuggestConsultation => this == CycleRegularity.irregular;
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
  static const int maxPlausibleCycleDays = CycleIntervals.maxPlausibleDays;

  /// En kısa aralık. Altındaki kayıtlar aynı reglin iki parçası olarak
  /// işaretlenmiş demektir.
  static const int minPlausibleCycleDays = CycleIntervals.minPlausibleDays;

  /// Tamamlanmış döngülerin uzunlukları, eskiden yeniye sıralı.
  ///
  /// Son döngü listede yoktur: bitmesi için bir sonraki reglin başlaması
  /// gerekir. Yani N regl kaydı en fazla N-1 nokta üretir.
  static List<CycleLengthPoint> cycleLengths(
    List<PeriodLog> logs, {
    required List<DateSpan> breaks,
    int limit = 6,
  }) {
    final points = CycleIntervals.of(logs, breaks: breaks);
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

  /// Döngü uzunluklarının ne kadar oynadığı.
  ///
  /// İki ölçümden az varsa null: tek döngüden "düzenli" ya da "düzensiz"
  /// demek veriye dayanmaz.
  ///
  /// Eşikler klinik bir sınır değil, kullanıcıya ne söyleneceğini belirleyen
  /// pratik bir ayrım. 8 gün, yaygın hasta bilgilendirme kaynaklarının
  /// "hekimine danışmayı düşünebilirsin" dediği aralığın başı.
  static CycleRegularity? regularity(List<CycleLengthPoint> points) {
    final spread = variation(points);
    if (spread == null) return null;
    if (spread <= 3) return CycleRegularity.steady;
    if (spread <= 7) return CycleRegularity.typical;
    return CycleRegularity.irregular;
  }

  /// Belirtilerin döngü evresine göre dağılımı.
  ///
  /// "Krampların çoğunlukla regl günlerinde" gibi bir cümle, yalnızca toplam
  /// sıklıktan çıkarılamaz. Her kayıt, o günün döngü gününe bakılarak
  /// evresine yerleştirilir.
  ///
  /// Döngü günü hesaplanamayan kayıtlar (ilk regl kaydından önceki günler)
  /// sayılmaz — bir yere zorla yerleştirmek veriyi bozar.
  static Map<CyclePhase, int> symptomsByPhase(
    String symptomCode, {
    required List<DailyLog> dailyLogs,
    required List<PeriodLog> periodLogs,
    required int periodLength,
    required List<DateSpan> breaks,
  }) {
    final starts = periodLogs.map((l) => _dateOnly(l.startDate)).toList()
      ..sort();
    if (starts.isEmpty) return const {};

    final counts = <CyclePhase, int>{};

    for (final log in dailyLogs) {
      if (!log.symptoms.contains(symptomCode)) continue;

      final day = _dateOnly(log.date);
      final start = _lastStartOnOrBefore(starts, day);
      if (start == null) continue;

      // Gebeliğin ilk 90 günü SAT'tan sayılınca makul bir "döngü günü"
      // çıkıyordu; ilk trimesterin bulantısı "luteal faz belirtisi" diye
      // sayılıyordu. Gün ile döngü başı arasına kesinti giriyorsa o gün
      // hiçbir regl evresine ait değil.
      if (breaks.any(
        (k) => k.overlaps(start, day.add(const Duration(days: 1))),
      )) {
        continue;
      }

      final cycleDay = day.difference(start).inDays + 1;
      final phase = _phaseOf(cycleDay, periodLength: periodLength);
      counts[phase] = (counts[phase] ?? 0) + 1;
    }

    return counts;
  }

  /// Bir belirtinin en çok görüldüğü evre ve o evredeki payı.
  ///
  /// Kayıt azken sonuç yanıltıcı olur: en az [minObservations] gözlem ve
  /// baskın evrenin payı yarıdan fazla değilse null döner — "çoğunlukla"
  /// diyebilmek için gerçekten çoğunluk gerekiyor.
  static ({CyclePhase phase, int count, int total})? dominantPhase(
    String symptomCode, {
    required List<DailyLog> dailyLogs,
    required List<PeriodLog> periodLogs,
    required int periodLength,
    required List<DateSpan> breaks,
    int minObservations = 3,
  }) {
    final counts = symptomsByPhase(
      symptomCode,
      dailyLogs: dailyLogs,
      periodLogs: periodLogs,
      periodLength: periodLength,
      breaks: breaks,
    );
    if (counts.isEmpty) return null;

    final total = counts.values.fold<int>(0, (sum, c) => sum + c);
    if (total < minObservations) return null;

    var best = counts.entries.first;
    for (final entry in counts.entries) {
      if (entry.value > best.value) best = entry;
    }

    if (best.value * 2 <= total) return null;
    return (phase: best.key, count: best.value, total: total);
  }

  static DateTime? _lastStartOnOrBefore(List<DateTime> starts, DateTime day) {
    DateTime? found;
    for (final start in starts) {
      if (start.isAfter(day)) break;
      found = start;
    }
    // Takip arası boşluktan sonraki bir güne eski bir başlangıcı
    // yakıştırmayalım: 90 günden uzak kayıt bir döngüye ait sayılmaz.
    if (found == null) return null;
    if (day.difference(found).inDays > maxPlausibleCycleDays) return null;
    return found;
  }

  static CyclePhase _phaseOf(int cycleDay, {required int periodLength}) {
    if (cycleDay <= periodLength) return CyclePhase.menstruation;
    // Ovulasyon penceresi: bir sonraki reglden ~14 gün önce. Kullanıcının
    // döngü uzunluğu bilinmediği için 28 günlük tipik döngü varsayılıyor;
    // gün 13–16 arası pencere olarak alınıyor.
    if (cycleDay < 13) return CyclePhase.follicular;
    if (cycleDay <= 16) return CyclePhase.ovulation;
    return CyclePhase.luteal;
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
