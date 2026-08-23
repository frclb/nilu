/// Döngü fazlarını temsil eden enum.
enum CyclePhase {
  menstruation, // Regl günleri (gün 1-5 civarı)
  follicular, // Foliküler faz (regl sonrası → ovulasyon öncesi)
  ovulation, // Ovulasyon penceresi
  luteal, // Luteal faz (ovulasyon sonrası → sonraki regl)
  /// Hormonal doğum kontrolü nedeniyle evre izlenmiyor.
  ///
  /// Kombine hap, hormonal spiral, implant ve iğne çoğunlukla yumurtlamayı
  /// baskılar; hormon seviyelerini doğal döngü değil ilaç belirler. Bu
  /// durumda foliküler/luteal ayrımı ve doğurganlık penceresi anlamını
  /// yitirir. Uygulama bunları göstermeye devam etseydi kullanıcıya
  /// olmayan bir yumurtlama günü ve yanlış bir doğurganlık penceresi
  /// göstermiş olurdu.
  suppressed,

  unknown, // Veri yok
}

/// Döngü istatistiklerini ve tahminleri barındıran model.
class CycleInfo {
  final int averageCycleLength;
  final int averagePeriodLength;
  final DateTime? lastPeriodStart;
  final DateTime? predictedNextPeriod;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final DateTime? ovulationDay;

  /// İleri döngü tahminleri (gelecek 3 döngü)
  final List<PredictedCycle> futurePredictions;

  /// Doğurganlık tahmini üretiliyor mu?
  ///
  /// Hormonal doğum kontrolünde `false`: yumurtlama günü ve doğurganlık
  /// penceresi hesaplanmaz, takvimde işaretlenmez.
  final bool fertilityTracked;

  CycleInfo({
    this.averageCycleLength = 28,
    this.averagePeriodLength = 5,
    this.lastPeriodStart,
    this.predictedNextPeriod,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.ovulationDay,
    this.futurePredictions = const [],
    this.fertilityTracked = true,
  });

  /// Bugünkü döngü gününü hesaplar.
  int? get currentCycleDay {
    if (lastPeriodStart == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(
      lastPeriodStart!.year,
      lastPeriodStart!.month,
      lastPeriodStart!.day,
    );
    final diff = today.difference(start).inDays + 1;
    if (diff < 1) return null;
    return diff;
  }

  /// Sonraki regle kaç gün kaldığını hesaplar.
  int? get daysUntilNextPeriod {
    if (predictedNextPeriod == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = DateTime(
      predictedNextPeriod!.year,
      predictedNextPeriod!.month,
      predictedNextPeriod!.day,
    );
    final diff = next.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Döngü ilerlemesini 0.0-1.0 arasında döndürür.
  double get cycleProgress {
    final day = currentCycleDay;
    if (day == null) return 0.0;
    return (day / averageCycleLength).clamp(0.0, 1.0);
  }

  /// Mevcut döngü fazını belirler.
  CyclePhase get currentPhase {
    final day = currentCycleDay;
    if (day == null) return CyclePhase.unknown;
    return getPhaseForDay(day);
  }

  /// Belirli bir döngü günü için fazı belirler.
  CyclePhase getPhaseForDay(int cycleDay) {
    if (cycleDay < 1) return CyclePhase.unknown;

    // Menstrüasyon fazı (1 → averagePeriodLength)
    if (cycleDay <= averagePeriodLength) {
      return CyclePhase.menstruation;
    }

    // Hormonal doğum kontrolünde kanama dışındaki günler için evre
    // belirtilmez: yumurtlama baskılandığı için foliküler/luteal ayrımı
    // gerçeği yansıtmaz.
    if (!fertilityTracked) return CyclePhase.suppressed;

    // Ovulasyon günü hesapla
    final ovulationDayNum = averageCycleLength - 14;

    // Ovulasyon penceresi (ovulasyon -2 → ovulasyon +1)
    if (cycleDay >= ovulationDayNum - 2 && cycleDay <= ovulationDayNum + 1) {
      return CyclePhase.ovulation;
    }

    // Foliküler faz (regl sonrası → ovulasyon penceresi öncesi)
    if (cycleDay > averagePeriodLength && cycleDay < ovulationDayNum - 2) {
      return CyclePhase.follicular;
    }

    // Luteal faz (ovulasyon sonrası → döngü sonu)
    return CyclePhase.luteal;
  }

  /// Belirli bir tarihin hangi evreye düştüğünü belirler.
  ///
  /// [loggedStart] o tarihten önceki en son **kayıtlı** regl başlangıcı.
  ///
  /// Yalnızca son kayıttan itibaren gün saymak gelecek tarihlerde bozuluyordu:
  /// 28 günlük bir döngüde 20 gün sonrasına bakan kullanıcı 35. güne düşüyor,
  /// [getPhaseForDay] de bunu luteal sayıyordu. Oysa o tarih bir sonraki
  /// döngünün regl günü. Tahmin edilen başlangıçları da çapa saydığımızda
  /// takvimin boyadığı renk ile gösterilen evre aynı şeyi söylüyor.
  CyclePhase phaseForDate(
    DateTime date, {
    DateTime? loggedStart,
    DateTime? now,
  }) {
    final day = cycleDayForDate(date, loggedStart: loggedStart, now: now);
    if (day == null) return CyclePhase.unknown;
    return getPhaseForDay(day);
  }

  /// Belirli bir tarihin, ait olduğu döngüdeki kaçıncı gün olduğunu döndürür.
  ///
  /// [phaseForDate] ile aynı çapayı kullanır; başlıkta "30. gün" yazarken
  /// içeriğin "regl dönemi" demesi kullanıcıyı şaşırtıyordu.
  ///
  /// Tahmin edilen başlangıçlar yalnızca **gelecek** tarihler için çapa sayılır.
  /// Bugün için de saysaydık, regl geciktiğinde sayaç "3. gün"e döner ve
  /// kullanıcının doğrulamadığı bir şeyi — reglin başladığını — iddia ederdi.
  /// Gecikmede 30. günde kalması doğru davranış.
  int? cycleDayForDate(DateTime date, {DateTime? loggedStart, DateTime? now}) {
    final target = DateTime(date.year, date.month, date.day);
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final isFuture = target.isAfter(today);

    final anchors = <DateTime>[
      ?loggedStart,
      if (isFuture) ...[
        ?predictedNextPeriod,
        ...futurePredictions.map((p) => p.startDate),
      ],
    ].map((d) => DateTime(d.year, d.month, d.day)).toList()..sort();

    DateTime? anchor;
    for (final candidate in anchors) {
      if (!candidate.isAfter(target)) {
        anchor = candidate;
      } else {
        break;
      }
    }
    if (anchor == null) return null;

    return target.difference(anchor).inDays + 1;
  }

  bool isPredictedPeriod(DateTime date) {
    if (predictedNextPeriod == null) return false;
    final end = predictedNextPeriod!.add(
      Duration(days: averagePeriodLength - 1),
    );
    if (_isBetween(date, predictedNextPeriod!, end)) return true;

    // İleri tahminleri de kontrol et
    for (final prediction in futurePredictions) {
      final predEnd = prediction.startDate.add(
        Duration(days: averagePeriodLength - 1),
      );
      if (_isBetween(date, prediction.startDate, predEnd)) return true;
    }

    return false;
  }

  bool isFertile(DateTime date) {
    if (!fertilityTracked) return false;
    if (fertileWindowStart == null || fertileWindowEnd == null) return false;
    if (_isBetween(date, fertileWindowStart!, fertileWindowEnd!)) return true;

    // İleri tahmin doğurganlık pencerelerini de kontrol et
    for (final prediction in futurePredictions) {
      if (prediction.fertileStart != null && prediction.fertileEnd != null) {
        if (_isBetween(
          date,
          prediction.fertileStart!,
          prediction.fertileEnd!,
        )) {
          return true;
        }
      }
    }

    return false;
  }

  /// Belirli bir günün yumurtlama günü olup olmadığını kontrol eder
  /// (mevcut döngü + gelecek tahminler).
  bool isOvulationDay(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);

    // Mevcut döngü yumurtlama günü
    if (ovulationDay != null) {
      final o = DateTime(
        ovulationDay!.year,
        ovulationDay!.month,
        ovulationDay!.day,
      );
      if (d.isAtSameMomentAs(o)) return true;
    }

    // Gelecek tahmin yumurtlama günleri
    for (final prediction in futurePredictions) {
      if (prediction.ovulationDay != null) {
        final po = DateTime(
          prediction.ovulationDay!.year,
          prediction.ovulationDay!.month,
          prediction.ovulationDay!.day,
        );
        if (d.isAtSameMomentAs(po)) return true;
      }
    }

    return false;
  }

  bool _isBetween(DateTime date, DateTime start, DateTime end) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
        (d.isAtSameMomentAs(e) || d.isBefore(e));
  }
}

/// Gelecek döngü tahmin modeli.
class PredictedCycle {
  final DateTime startDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final DateTime? ovulationDay;

  PredictedCycle({
    required this.startDate,
    this.fertileStart,
    this.fertileEnd,
    this.ovulationDay,
  });
}
