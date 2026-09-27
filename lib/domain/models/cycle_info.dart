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

  /// Bu döngüde kanamanın **kayıtlı** uzunluğu; kayıt yoksa null.
  ///
  /// [averagePeriodLength] geçmişin ortalamasıdır ve gelecek tahminleri için
  /// doğru sayıdır — ama bugün kanama olup olmadığını söylemez. Kullanıcı
  /// takvimde reglini kısaltınca ekran kendi kendini yalanlıyordu: başlık
  /// ortalamaya bakıp "REGL / 3. gün" derken düğme kayda bakıp "Reglim
  /// başladı" diyordu. Basılınca da yalnızca düğme değişiyor, başlık
  /// kımıldamıyordu; düğme işlevsiz görünüyordu.
  ///
  /// Bu alan `PeriodLog.contains`in kullandığı uzunluğun aynısıdır: bitmiş
  /// kayıtta gerçek uzunluk, devam eden kayıtta kullanıcının ayarladığı regl
  /// süresi.
  final int? currentPeriodLength;

  /// Devam eden dönemin ne kadar süreceği beklentisi — kullanıcının ayarı.
  ///
  /// [averagePeriodLength]ten ayrı tutuluyor: o geçmişin ortalaması ve
  /// **gelecek** döngülerin tahmini için doğru olan. Bu ise şu an süren
  /// dönem için.
  ///
  /// Ayrı olmak zorunda, çünkü takvimin bandı (`isExpectedContinuation`) ve
  /// kaydın açık kalıp kalmayacağına karar veren mantık (`toggleDay`,
  /// `recordFromStart`) zaten kullanıcının ayarını kullanıyor. Halka
  /// ortalamayı kullanınca aynı gün takvimde regl, çelenkte foliküler
  /// görünüyordu: kullanıcı yedi gün ayarlamışken geçmişi üç günlükse
  /// halka üçte kesiliyordu.
  final int plannedPeriodLength;

  /// Bu döngüdeki dönemin kapatıldığı gün; devam ediyorsa null.
  ///
  /// Neden ayrı bir alan: "Reglim bitti" bugünü kayıttan silmiyor, son gün
  /// olarak işaretliyor. Dolayısıyla faz o gün hâlâ menstrüasyon ve
  /// devam eden bir dönemle **birebir aynı** görünüyordu. Ana ekran aynı
  /// anda hem "Reglin bugün bitti" hem "REGL · 3. gün" yazıyordu; fazı
  /// okuyan hiçbir yüzey ikisini ayırt edemiyordu.
  final DateTime? currentPeriodEnd;

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
    this.currentPeriodLength,
    this.currentPeriodEnd,
    int? plannedPeriodLength,
  }) : plannedPeriodLength = plannedPeriodLength ?? averagePeriodLength;

  /// Dönem bugün mü kapatıldı?
  ///
  /// Kıyası burada yapıyoruz: aynı karşılaştırmayı her ekranda tekrarlamak,
  /// birinin gün normalizasyonunu atlamasına açık kapı bırakırdı.
  bool get periodEndedToday {
    final end = currentPeriodEnd;
    if (end == null) return false;
    final now = DateTime.now();
    return DateTime(end.year, end.month, end.day).isAtSameMomentAs(
      DateTime(now.year, now.month, now.day),
    );
  }

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

  /// Regl tahmin edilen günü kaç gün geçti.
  ///
  /// Gecikme yoksa 0. [daysUntilNextPeriod] sıfırın altına inmiyor; tek başına
  /// bakıldığında gecikmenin ilk günü ile onuncu günü aynı görünüyordu ve
  /// ekranda her ikisinde de "bugün başlıyor" yazıyordu.
  int daysLateAt(DateTime now) {
    final predicted = predictedNextPeriod;
    if (predicted == null) return 0;
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(predicted.year, predicted.month, predicted.day);
    final diff = today.difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Bugün itibarıyla gecikme.
  int get daysLate => daysLateAt(DateTime.now());

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
    return phaseForCurrentCycleDay(day);
  }

  /// Mevcut döngünün belirli bir günü için fazı belirler.
  ///
  /// Kanama uzunluğu olarak ortalamayı değil kaydı kullanır; ana ekranın
  /// başlığı ile "Reglim başladı / bitti" düğmesi böylece aynı veriden
  /// besleniyor.
  CyclePhase phaseForCurrentCycleDay(int cycleDay) =>
      getPhaseForDay(cycleDay, periodLength: currentPeriodLength);

  /// Çelenk halkası için faz.
  ///
  /// Başlık ("4. gün") ve "Reglim bitti" düğmesi **kayda** bakıyor: bugüne
  /// kadar kaç gün geçtiğine. Halka ise bir tahmin görseli — yumurtlamayı,
  /// luteal fazı, sonraki regli hep ileriye doğru boyuyor.
  ///
  /// Devam eden reglin kalan günlerini boyamayıp diğer her şeyi boyamak
  /// tutarsızdı: kullanıcı yedi gün seçtiğinde takvim yedi gün gösterirken
  /// halka dördüncü çiçekte kesiliyordu. Aynı veriden iki farklı cevap.
  ///
  /// Dönem kapandıysa kayıt kesindir, o kullanılıyor: "Reglim bitti"ye
  /// üçüncü gün basan kullanıcıya yedi çiçek göstermek olmaz.
  CyclePhase phaseForRingDay(int cycleDay) {
    final recorded = currentPeriodLength;
    if (recorded == null) return getPhaseForDay(cycleDay);

    final length = currentPeriodEnd != null
        ? recorded
        : (recorded > plannedPeriodLength ? recorded : plannedPeriodLength);
    return getPhaseForDay(cycleDay, periodLength: length);
  }

  /// Belirli bir döngü günü için fazı belirler.
  ///
  /// [periodLength] verilmezse geçmişin ortalaması kullanılır — tahmin edilen
  /// döngüler için doğru olan budur, çünkü onların kaydı henüz yok.
  CyclePhase getPhaseForDay(int cycleDay, {int? periodLength}) {
    if (cycleDay < 1) return CyclePhase.unknown;

    final bleedingLength = periodLength ?? averagePeriodLength;

    // Menstrüasyon fazı (1 → kanama uzunluğu)
    if (cycleDay <= bleedingLength) {
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
    if (cycleDay > bleedingLength && cycleDay < ovulationDayNum - 2) {
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
    final anchored = _anchor(date, loggedStart: loggedStart, now: now);
    if (anchored == null) return CyclePhase.unknown;

    // Yalnızca içinde bulunduğumuz döngünün kaydı var; geçmiş ve gelecek
    // döngüler için ortalamaya düşülüyor.
    return getPhaseForDay(
      anchored.day,
      periodLength: anchored.isCurrentCycle ? currentPeriodLength : null,
    );
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
    return _anchor(date, loggedStart: loggedStart, now: now)?.day;
  }

  /// [date] hangi döngü başlangıcına dayanıyor ve o başlangıç bugünkü döngünün
  /// başlangıcı mı — [cycleDayForDate] ile [phaseForDate] aynı çapayı
  /// kullansın diye tek yerde hesaplanıyor.
  _AnchoredDay? _anchor(DateTime date, {DateTime? loggedStart, DateTime? now}) {
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

    final start = lastPeriodStart;
    final isCurrent =
        start != null &&
        anchor.isAtSameMomentAs(DateTime(start.year, start.month, start.day));

    return _AnchoredDay(
      day: target.difference(anchor).inDays + 1,
      isCurrentCycle: isCurrent,
    );
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

/// Bir tarihin çapalandığı döngü günü ve bu çapanın bugünkü döngüye ait olup
/// olmadığı.
class _AnchoredDay {
  final int day;
  final bool isCurrentCycle;

  const _AnchoredDay({required this.day, required this.isCurrentCycle});
}
