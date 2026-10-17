/// Tahminin neye dayandığı.
enum PredictionSource {
  /// Kullanıcının kayıtlı döngüleri.
  history,

  /// Kullanıcının girdiği döngü süresi (kayıt yok ya da ayar yeni
  /// değiştirildi).
  settings,

  /// Hiçbir bilgi yok: genel varsayılan 28 gün.
  assumed,
}

/// Sonraki regl tahmininin aralığı ve dayanağı.
///
/// Tek bir gün göstermek kesinlik iddia ediyordu: 28 günlük ortalamayla
/// "21 Ekim" yazan ekran, döngüsü 26 ile 31 gün arasında oynayan kullanıcıya
/// her ay "tahmin tutmadı" dedirtiyordu. Aralık, kullanıcının kendi
/// geçmişindeki en kısa ve en uzun döngüden geliyor; veri azsa açıkça
/// varsayılan bir pay kullanılıyor ve açıklama ekranı bunu söylüyor.
///
/// Makine öğrenmesi yok: kural ekranda tek cümleyle anlatılabilecek kadar
/// basit olmalı ki kullanıcı ona ne kadar güveneceğine kendisi karar
/// verebilsin.
class PredictionBasis {
  final PredictionSource source;

  /// Tahminde kullanılan döngü süresi.
  final int cycleLength;

  /// Ortalamaya giren döngü sayısı (en fazla [averagedCycles]).
  final int cyclesAveraged;

  /// Aralığa bakılan son döngüler (en fazla [rangeCycles]) içinde en kısa ve
  /// en uzun; en az iki döngü yoksa `null`.
  final int? shortest;
  final int? longest;

  /// Aralığa bakılan döngü sayısı.
  final int cyclesConsidered;

  /// Sonraki reglin en erken ve en geç beklenen günü. En olası gün her
  /// zaman bu aralığın içinde.
  final DateTime earliest;
  final DateTime latest;

  /// Ortalama son kaç döngüden (bkz. `CycleService`).
  static const int averagedCycles = 3;

  /// Aralık son kaç döngüden.
  static const int rangeCycles = 6;

  /// Aralık için geçmişin yeterli sayıldığı döngü sayısı.
  static const int minCyclesForRange = 3;

  /// Az veride varsayılan pay (gün, iki yana).
  static const int fewCyclesMargin = 2;

  /// Hiç bilgi yokken varsayılan pay.
  static const int assumedMargin = 3;

  /// Döngüler arası fark bunu aşarsa aralık geniş; açıklama bunu söylüyor.
  static const int irregularSpreadDays = 7;

  const PredictionBasis({
    required this.source,
    required this.cycleLength,
    required this.cyclesAveraged,
    required this.cyclesConsidered,
    required this.earliest,
    required this.latest,
    this.shortest,
    this.longest,
  });

  /// Aralık kendi geçmişinden mi, varsayılan bir paydan mı?
  bool get rangeFromHistory =>
      source == PredictionSource.history &&
      cyclesConsidered >= minCyclesForRange;

  /// Son döngüler arasındaki fark geniş mi?
  bool get isIrregular {
    final kisa = shortest;
    final uzun = longest;
    return kisa != null && uzun != null && uzun - kisa > irregularSpreadDays;
  }
}
