import '../models/calendar_day.dart';
import '../models/cycle_info.dart';
import '../models/prediction_basis.dart';
import 'cycle_intervals.dart';
import '../models/period_log.dart';
import 'cycle_service.dart';

/// Gelecek tahminlerini üreten servis.
class PredictionService {
  /// Kaç döngü ileri tahmin üretileceği.
  ///
  /// Takvimde ileri sayfalanabiliyor; üç döngü (~3 ay) sonrası boş kalıyordu.
  /// On üç döngü bir yılı aşıyor.
  static const int forecastCycleCount = 13;

  /// Luteal faz uzunluğu. Yumurtlama, bir sonraki regl başlangıcından bu
  /// kadar gün öncedir.
  static const int lutealPhaseDays = 14;

  final CycleService _cycleService = CycleService();

  /// [start] gününde başlayan, [cycleLength] gün süren döngünün yumurtlaması.
  static DateTime _ovulationFor(DateTime start, int cycleLength) =>
      start.plusDays(cycleLength - lutealPhaseDays);

  /// Döngü bilgisini hesaplar.
  /// [userCycleLength] ve [userPeriodLength]: Kullanıcının ayarladığı değerler
  /// (yeterli log verisi yoksa kullanılır).
  /// [settingsUpdatedAt]: Ayarların değiştirildiği tarih. Bu tarihten sonraki
  /// tahminlerde yeni değerler, öncekinde hesaplanan ortalamalar kullanılır.
  /// [hormonalContraception] açıkken yumurtalık ve doğurganlık penceresi
  /// **hiç hesaplanmaz**. Bunları ekranlarda tek tek gizlemek yerine burada
  /// üretmemek daha güvenli: yeni bir ekran eklendiğinde de gizlemeyi
  /// unutma riski kalmıyor.
  CycleInfo getCycleInfo(
    List<PeriodLog> logs, {
    int userCycleLength = 28,
    int userPeriodLength = 5,
    DateTime? settingsUpdatedAt,
    bool hormonalContraception = false,
    DateTime? today,
    List<DateSpan> breaks = const [],
    // Kullanıcı döngü süresini kendisi girdi mi? Girmediyse 28 bir
    // varsayım; açıklama ekranı bunu "senin döngün" diye sunmamalı.
    bool cycleLengthFromUser = true,
  }) {
    final avgLength = _cycleService.calculateAverageCycleLength(
      logs,
      defaultLength: userCycleLength,
      breaks: breaks,
    );
    final lastStart = _cycleService.getLastPeriodStart(logs, breaks: breaks);
    final avgPeriodLength = _calculateAveragePeriodLength(
      logs,
      defaultLength: userPeriodLength,
    );

    // Eğer settingsUpdatedAt varsa ve son regl bu tarihten sonraysa,
    // yeni kullanıcı ayarlarını kullan; değilse hesaplanan ortalamayı kullan.
    int effectiveCycleLength = avgLength;
    int effectivePeriodLength = avgPeriodLength;
    var settingsOverride = false;

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
        settingsOverride = true;
      }
    }

    if (lastStart == null) {
      return CycleInfo(
        averageCycleLength: effectiveCycleLength,
        averagePeriodLength: effectivePeriodLength,
        fertilityTracked: !hormonalContraception,
        plannedPeriodLength: userPeriodLength,
      );
    }

    // Bu döngüde kanamanın kayıtlı uzunluğu. Ortalamadan ayrı tutuluyor:
    // ortalama gelecek tahminleri için, bu ise "bugün kanama var mı"
    // sorusu için. İkisini karıştırdığımızda takvimde regl kısaltılınca
    // başlık ile düğme farklı şey söylüyordu.
    final currentPeriodLength = _loggedLengthOf(logs, lastStart, today: today);
    final currentPeriodEnd = _endOf(logs, lastStart);

    // Gebelik ya da lohusalık sonrası ilk döngüler düzensiz (emzirmede daha
    // da). Kesintiden sonra en az bir döngü tamamlanmadan tarih vermek
    // kendinden emin bir yanlış olur — ve bilinmeyen bir doğurganlık
    // penceresi "güvenli gün" gibi görünür. Bugünkü regl yine görünüyor;
    // yalnızca ileriye dönük tahmin yok.
    final kesintiSonrasiDonguVar =
        breaks.isEmpty ||
        CycleIntervals.usableStarts(logs, breaks: breaks).length >= 2;
    if (!kesintiSonrasiDonguVar) {
      return CycleInfo(
        averageCycleLength: effectiveCycleLength,
        averagePeriodLength: effectivePeriodLength,
        lastPeriodStart: lastStart,
        currentPeriodLength: currentPeriodLength,
        plannedPeriodLength: userPeriodLength,
        currentPeriodEnd: currentPeriodEnd,
        fertilityTracked: !hormonalContraception,
      );
    }

    final nextPeriod = lastStart.plusDays(effectiveCycleLength);
    final basis = _basis(
      CycleIntervals.of(
        logs,
        breaks: breaks,
      ).map((p) => p.lengthInDays).toList(),
      lastStart: lastStart,
      nextPeriod: nextPeriod,
      cycleLength: effectiveCycleLength,
      settingsOverride: settingsOverride,
      cycleLengthFromUser: cycleLengthFromUser,
    );

    // Yumurtlama luteal faza göre hesaplanır: bir sonraki reglden 14 gün önce,
    // yani döngü başlangıcından `uzunluk - 14` gün sonra. Luteal faz kişiden
    // kişiye pek değişmez, değişen foliküler fazdır.
    final tracksFertility = !hormonalContraception;

    final ovulation = tracksFertility
        ? _ovulationFor(lastStart, effectiveCycleLength)
        : null;

    // Doğurganlık penceresi: Yumurtlama -5 gün → Yumurtlama +1 gün (tıbbi standart)
    final fertileStart = ovulation?.plusDays(-5);
    final fertileEnd = ovulation?.plusDays(1);

    // İleri döngü tahminleri.
    //
    // Üç kusur düzeltildi:
    //
    // 1. Uzunluk olarak `userCycleLength` kullanılıyordu, mevcut döngü ise
    //    hesaplanan ortalamayı kullanıyordu. Kullanıcı takvimde önce 30
    //    günlük, hemen ardından 28 günlük aralıklar görüyordu.
    // 2. Yumurtlama `başlangıç - 14` idi; bu, o döngünün değil bir
    //    öncekinin yumurtlamasıdır. Kayıt içinde başlangıç ve yumurtlama
    //    birbirine uymuyordu ve zincirin son döngüsünün doğurganlık
    //    penceresi hiç üretilmiyordu.
    // 3. Zincir `nextPeriod`'dan **sonra** başlıyordu, dolayısıyla sonraki
    //    reglin kendi doğurganlık penceresi listede yoktu.
    final futurePredictions = <PredictedCycle>[];
    for (int i = 1; i <= forecastCycleCount; i++) {
      final futureStart = lastStart.plusDays(effectiveCycleLength * i);
      final futureOvulation = tracksFertility
          ? _ovulationFor(futureStart, effectiveCycleLength)
          : null;
      futurePredictions.add(
        PredictedCycle(
          startDate: futureStart,
          ovulationDay: futureOvulation,
          fertileStart: futureOvulation?.plusDays(-5),
          fertileEnd: futureOvulation?.plusDays(1),
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
      currentPeriodLength: currentPeriodLength,
      // Takvim bandı ve kayıt mantığı da bu sayıyı kullanıyor; halka
      // ortalamaya bakınca iki yüzey aynı güne farklı cevap veriyordu.
      plannedPeriodLength: userPeriodLength,
      currentPeriodEnd: currentPeriodEnd,
      fertilityTracked: tracksFertility,
      basis: basis,
    );
  }

  /// Tahminin aralığı ve dayanağı (bkz. [PredictionBasis]).
  static PredictionBasis _basis(
    List<int> lengths, {
    required DateTime lastStart,
    required DateTime nextPeriod,
    required int cycleLength,
    required bool settingsOverride,
    required bool cycleLengthFromUser,
  }) {
    final source = settingsOverride
        ? PredictionSource.settings
        : lengths.isNotEmpty
        ? PredictionSource.history
        : cycleLengthFromUser
        ? PredictionSource.settings
        : PredictionSource.assumed;

    final son = lengths.length > PredictionBasis.rangeCycles
        ? lengths.sublist(lengths.length - PredictionBasis.rangeCycles)
        : lengths;
    final kisa = son.length >= 2 ? son.reduce((a, b) => a < b ? a : b) : null;
    final uzun = son.length >= 2 ? son.reduce((a, b) => a > b ? a : b) : null;

    DateTime erken;
    DateTime gec;
    if (source == PredictionSource.history &&
        son.length >= PredictionBasis.minCyclesForRange) {
      // Kendi geçmişi: en kısa ve en uzun döngü. En olası gün aralığın
      // içinde kalsın ve tamamen düzenli döngüde de bir gün pay olsun.
      erken = lastStart.plusDays(
        kisa! < cycleLength - 1 ? kisa : cycleLength - 1,
      );
      gec = lastStart.plusDays(
        uzun! > cycleLength + 1 ? uzun : cycleLength + 1,
      );
    } else {
      final pay = source == PredictionSource.assumed
          ? PredictionBasis.assumedMargin
          : PredictionBasis.fewCyclesMargin;
      erken = nextPeriod.plusDays(-pay);
      gec = nextPeriod.plusDays(pay);
    }

    return PredictionBasis(
      source: source,
      cycleLength: cycleLength,
      cyclesAveraged: lengths.length < PredictionBasis.averagedCycles
          ? lengths.length
          : PredictionBasis.averagedCycles,
      cyclesConsidered: son.length,
      shortest: kisa,
      longest: uzun,
      earliest: erken,
      latest: gec,
    );
  }

  /// Ortalama regl süresini hesaplar.
  ///
  /// Yalnızca **tamamlanmış** dönemler sayılır: devam eden bir dönemin gerçek
  /// uzunluğu henüz bilinmediğinden, onu sabit bir değerle hesaba katmak
  /// ortalamayı kullanıcının gerçek verisinden saptırır.
  /// [defaultLength] yeterli veri olmadığında kullanılacak değer.
  /// [start] tarihinde başlayan kaydın kanama uzunluğu.
  ///
  /// `PeriodLog.containsRecorded` ile birebir aynı sayıyı verir: bitmiş
  /// kayıtta gerçek uzunluk, devam eden kayıtta bugüne kadar geçen gün
  /// sayısı. Aynı sayıyı vermezse ekranın iki yarısı yine ayrışır.
  int? _loggedLengthOf(
    List<PeriodLog> logs,
    DateTime start, {
    DateTime? today,
  }) {
    final cleanStart = DateTime(start.year, start.month, start.day);
    for (final log in logs) {
      final logStart = DateTime(
        log.startDate.year,
        log.startDate.month,
        log.startDate.day,
      );
      if (logStart.isAtSameMomentAs(cleanStart)) {
        return log.recordedLength(today: today);
      }
    }
    return null;
  }

  /// Bu döngüdeki dönemin kapatıldığı gün; devam ediyorsa null.
  DateTime? _endOf(List<PeriodLog> logs, DateTime start) {
    final cleanStart = DateTime(start.year, start.month, start.day);
    for (final log in logs) {
      final logStart = DateTime(
        log.startDate.year,
        log.startDate.month,
        log.startDate.day,
      );
      if (logStart.isAtSameMomentAs(cleanStart)) {
        final end = log.endDate;
        return end == null ? null : DateTime(end.year, end.month, end.day);
      }
    }
    return null;
  }

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
