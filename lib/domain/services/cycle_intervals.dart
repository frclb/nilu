import '../models/life_stage.dart';
import '../models/period_log.dart';
import '../models/pregnancy.dart';

/// Gün hassasiyetinde, başı dahil sonu hariç bir aralık: `[start, end)`.
///
/// `end` null ise açık uçlu (süren gebelik).
class DateSpan {
  final DateTime start;
  final DateTime? end;

  DateSpan(DateTime start, [DateTime? end])
    : start = _day(start),
      end = end == null ? null : _day(end);

  /// `[a, b)` ile kesişiyor mu?
  bool overlaps(DateTime a, DateTime b) {
    final bas = _day(a);
    final son = _day(b);
    final bitis = end;
    return start.isBefore(son) && (bitis == null || bas.isBefore(bitis));
  }

  bool contains(DateTime d) {
    final gun = _day(d);
    final bitis = end;
    return !gun.isBefore(start) && (bitis == null || gun.isBefore(bitis));
  }

  @override
  String toString() => 'DateSpan($start, ${end ?? '∞'})';

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Tamamlanmış bir döngü.
class CycleLengthPoint {
  final DateTime startDate;
  final int lengthInDays;

  const CycleLengthPoint({required this.startDate, required this.lengthInDays});
}

/// Döngü aralıklarının **tek** hesabı.
///
/// Önceden iki yerde ayrı ayrı yapılıyordu — `CycleService` ortalama için,
/// `InsightsService` grafik/uyarı/özet/asistan için — ve makul sınırlar
/// (15/90 gün) iki dosyada ayrı sabitlerdi. Gebelik aralığını dışlama kuralı
/// eklenirken ikisine ayrı ayrı yazılsaydı, bu oturumda defalarca bulunan
/// hata (aynı kural iki yerde, biri eskiyor) kaçınılmazdı.
class CycleIntervals {
  const CycleIntervals._();

  /// En kısa aralık. Altındaki kayıtlar aynı reglin iki parçası olarak
  /// işaretlenmiş demektir.
  static const int minPlausibleDays = 15;

  /// Bir "döngü" sayılacak en uzun aralık. Ötesi takibe ara verilmiş demek;
  /// grafiğe konursa ölçeği bozar.
  static const int maxPlausibleDays = 90;

  static bool isPlausible(int days) =>
      days >= minPlausibleDays && days <= maxPlausibleDays;

  /// Makul ve hiçbir kesintiyle kesişmeyen döngüler, eskiden yeniye.
  ///
  /// [breaks] **zorunlu**: bu fonksiyonu çağıran her yer gebelik aralığını
  /// bilmek zorunda. Varsayılan değer verilseydi yeni bir ekran onu
  /// unutabilir ve lohusa bir annenin istatistiğine 10 aylık bir "döngü"
  /// karışabilirdi. Kesinti yoksa çağıran açıkça `const []` geçiyor.
  static List<CycleLengthPoint> of(
    List<PeriodLog> logs, {
    required List<DateSpan> breaks,
  }) {
    if (logs.length < 2) return const [];

    final starts = logs.map((l) => _day(l.startDate)).toList()..sort();

    final points = <CycleLengthPoint>[];
    for (var i = 0; i < starts.length - 1; i++) {
      final bas = starts[i];
      final son = starts[i + 1];
      final uzunluk = son.difference(bas).inDays;
      if (!isPlausible(uzunluk)) continue;
      if (breaks.any((k) => k.overlaps(bas, son))) continue;
      points.add(CycleLengthPoint(startDate: bas, lengthInDays: uzunluk));
    }
    return points;
  }

  /// Tahmin için kullanılabilecek regl başlangıçları.
  ///
  /// Bir kesintinin bitişinden önceki başlangıçlar **yeni döngünün
  /// dayanağı olamaz**: doğumdan sonra ilk regl gelene dek son kayıt gebelik
  /// öncesi SAT ve ondan ileri saymak "reglin 250 gün gecikti" demek.
  /// Süren gebelikte (açık uçlu kesinti) hiçbiri kullanılamaz.
  static List<DateTime> usableStarts(
    List<PeriodLog> logs, {
    required List<DateSpan> breaks,
  }) {
    final starts = logs.map((l) => _day(l.startDate)).toList()..sort();
    if (breaks.isEmpty) return starts;
    if (breaks.any((k) => k.end == null)) return const [];

    final sonKesinti = breaks
        .map((k) => k.end!)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return starts.where((s) => !s.isBefore(sonKesinti)).toList();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Gebeliklerden döngü istatistiğinin dışında tutulacak aralıklar.
class CycleBreaks {
  const CycleBreaks._();

  /// Her gebelik için `[gebelik başlangıcı, bitiş + lohusalık)`.
  ///
  /// Doğumla bitenlerde lohusalık (42 gün) da kesintiye dahil: o süredeki
  /// kanama lohia, döngü değil. Erken kayıplarda kesinti bitişte sona eriyor
  /// — kayıp kanaması klinikte yeni döngünün 1. günü sayılabiliyor.
  static List<DateSpan> fromPregnancies(Iterable<Pregnancy> pregnancies) => [
    for (final p in pregnancies)
      DateSpan(
        p.gestationStart,
        p.endedAt == null
            ? null
            : LifeStage.deliveries.contains(p.outcome)
            ? p.endedAt!.add(const Duration(days: LifeStage.postpartumDays))
            : p.endedAt,
      ),
  ];
}
