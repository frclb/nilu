import '../models/period_log.dart';

/// Regl günlerini yöneten ve logları blok (başlangıç/bitiş) olarak tutan servis.
class PeriodService {
  /// "Reglim başladı": [date] gününden itibaren devam eden bir dönem açar.
  ///
  /// Dönem **bitişsiz** kaydediliyor. Kapalı tek günlük bir kayıt açsaydık
  /// ertesi gün düğme yine "Reglim başladı" derdi; kullanıcı kanaması
  /// sürerken her sabah "başladı" demek zorunda kalıyordu.
  List<PeriodLog> startPeriod(List<PeriodLog> logs, DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final newList = List<PeriodLog>.from(logs);

    // Bugün zaten kayıtlıysa yapacak bir şey yok.
    if (newList.any((l) => l.containsRecorded(cleanDate, today: cleanDate))) {
      return newList;
    }

    // Dün biten bir dönem varsa aslında bitmemiş: kaydı yeniden açıyoruz.
    // Yeni bir dönem açmak, aynı kanamayı iki döngü gibi gösterirdi.
    final yesterday = cleanDate.subtract(const Duration(days: 1));
    for (final log in newList) {
      final end = log.endDate;
      if (end != null &&
          DateTime(end.year, end.month, end.day).isAtSameMomentAs(yesterday)) {
        log.endDate = null;
        return newList;
      }
    }

    // Açık kalmış bir dönemi burada kapatmak gerekmiyor: devam eden bir kayıt
    // tanımı gereği bugünü kapsar, o durumda da bu metoda hiç gelinmez.
    newList.add(
      PeriodLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startDate: cleanDate,
        endDate: null,
      ),
    );
    newList.sort((a, b) => a.startDate.compareTo(b.startDate));
    return newList;
  }

  /// "Reglim bitti": dönemi [date] gününde kapatır.
  ///
  /// [date] kaydın **içinde kalır**. Önceden bu eylem günü kaydın dışına
  /// çıkarıyordu; kullanıcı son kanama gününü işaretleyemiyordu.
  ///
  /// Dönem bugünün ötesine uzanıyorsa (onboarding'in ürettiği kayıt tipik
  /// olarak uzanıyor) bugüne kırpılır.
  List<PeriodLog> endPeriod(List<PeriodLog> logs, DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final newList = List<PeriodLog>.from(logs);

    for (final log in newList) {
      if (log.containsRecorded(cleanDate, today: cleanDate)) {
        log.endDate = cleanDate;
        return newList;
      }
    }

    // Bugün kayıtlı değil ama dün kayıtlıysa kanama bugün de sürdü demektir;
    // dönemi bugüne uzatıp kapatıyoruz.
    final yesterday = cleanDate.subtract(const Duration(days: 1));
    for (final log in newList) {
      if (log.containsRecorded(yesterday, today: cleanDate)) {
        log.endDate = cleanDate;
        return newList;
      }
    }

    return newList;
  }

  /// Belirli bir regl kaydını tamamen siler.
  List<PeriodLog> deletePeriod(List<PeriodLog> logs, String id) {
    final newList = List<PeriodLog>.from(logs);
    newList.removeWhere((log) => log.id == id);
    return newList;
  }

  /// Bir günü regl günü olarak işaretler veya kaldırır.
  ///
  /// Takvimde tek bir güne dokunmanın karşılığı. Ana ekrandaki düğme bunu
  /// kullanmıyor; onun eylemleri [startPeriod] ve [endPeriod].
  ///
  /// [today]: bugünün tarihi. Gelecekte **başlayan** bir dönem üretilmesini
  /// engellemek için gerekiyor; kullanıcı yaşamadığı bir kanamayı kaydedemez.
  ///
  /// [expectedLength]: kullanıcının regl süresi. Geçmiş bir gün işaretlendiğinde
  /// dönemin hâlâ sürüyor olup olmadığına bununla karar veriliyor — bkz.
  /// [_couldStillBeRunning].
  List<PeriodLog> toggleDay(
    List<PeriodLog> logs,
    DateTime date, {
    DateTime? today,
    int expectedLength = PeriodLog.defaultOngoingLength,
  }) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final reference = today ?? DateTime.now();
    final cleanToday = DateTime(reference.year, reference.month, reference.day);
    final newList = List<PeriodLog>.from(logs);

    final foundIndex = newList.indexWhere(
      (l) => l.containsRecorded(cleanDate, today: cleanToday),
    );

    if (foundIndex != -1) {
      final log = newList[foundIndex];
      final logStart = log.firstDay;
      final logEnd = log.lastRecordedDay(today: cleanToday);

      if (logStart.isAtSameMomentAs(cleanDate) &&
          logEnd.isAtSameMomentAs(cleanDate)) {
        // Tek günlük dönem: kaydı sil.
        newList.removeAt(foundIndex);
      } else if (logStart.isAtSameMomentAs(cleanDate)) {
        // Baştan kırp; dönem devam ediyorsa devam eder.
        log.startDate = cleanDate.add(const Duration(days: 1));
      } else if (logEnd.isAtSameMomentAs(cleanDate)) {
        // Sondan kırp. Devam eden bir dönemde son kayıtlı gün bugündür;
        // bugünü kaldırmak dönemi dün kapatır.
        log.endDate = cleanDate.subtract(const Duration(days: 1));
      } else {
        // Ortadaki bir gün siliniyor: dönem ikiye ayrılır.
        final secondStart = cleanDate.add(const Duration(days: 1));

        newList.removeAt(foundIndex);
        newList.add(
          PeriodLog(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            startDate: log.startDate,
            endDate: cleanDate.subtract(const Duration(days: 1)),
          ),
        );

        // İkinci parça gelecekte başlıyorsa atılıyor. Kayıt bugünün ötesine
        // uzandığında (onboarding'inki uzanıyor) bölme, yarın başlayan bir
        // dönem bırakıyordu; `lastPeriodStart` geleceğe kayınca döngü günü
        // null oluyor, ana ekranın başlığı ile çelengi boşalıyordu.
        if (!secondStart.isAfter(cleanToday)) {
          newList.add(
            PeriodLog(
              id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
              startDate: secondStart,
              endDate: log.endDate,
            ),
          );
        }
      }
    } else {
      // Regl günü değil: ekle. Komşu dönemler varsa onlarla birleştir.
      final nextDay = cleanDate.add(const Duration(days: 1));
      final prevDay = cleanDate.subtract(const Duration(days: 1));

      PeriodLog? prevPeriod;
      PeriodLog? nextPeriod;

      for (final log in newList) {
        if (log.lastRecordedDay(today: cleanToday).isAtSameMomentAs(prevDay)) {
          prevPeriod = log;
        }
        if (log.firstDay.isAtSameMomentAs(nextDay)) {
          nextPeriod = log;
        }
      }

      final PeriodLog affected;
      if (prevPeriod != null && nextPeriod != null) {
        prevPeriod.endDate = nextPeriod.endDate;
        newList.remove(nextPeriod);
        affected = prevPeriod;
      } else if (prevPeriod != null) {
        prevPeriod.endDate = cleanDate;
        affected = prevPeriod;
      } else if (nextPeriod != null) {
        nextPeriod.startDate = cleanDate;
        affected = nextPeriod;
      } else {
        affected = PeriodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startDate: cleanDate,
          endDate: cleanDate,
        );
        newList.add(affected);
      }

      // Sonrasında başka bir dönem varsa bu blok geçmişe ait; kapalı kalır.
      final hasLaterPeriod = newList.any(
        (l) => !identical(l, affected) && l.firstDay.isAfter(affected.firstDay),
      );
      if (!hasLaterPeriod &&
          _couldStillBeRunning(
            affected.firstDay,
            cleanToday,
            expectedLength,
          )) {
        affected.endDate = null;
      }
    }

    newList.sort((a, b) => a.startDate.compareTo(b.startDate));
    return newList;
  }

  /// İşaretlenen blok bugün hâlâ sürüyor olabilir mi?
  ///
  /// "17'sinde başladı" demek "17'sinde başlayıp bitti" demek değil. Takvimde
  /// geçmiş bir gün işaretlemek dönemi **kapalı** kaydediyordu: takvim bugünü
  /// kapsamıyor, `periodEndedToday` doğru dönüyor ve ana ekran daha ilk günden
  /// dönemi bitmiş sayıyordu. Oysa ana ekrandaki "Reglim başladı" düğmesi aynı
  /// tarihi açık kaydediyordu — aynı olgu iki arayüzde iki farklı şey.
  ///
  /// Beklenen regl süresi henüz dolmadıysa kayıt açık bırakılıyor; dönem
  /// bittiğinde kullanıcı "Reglim bitti" diyor. Süre dolmuşsa kayıt geçmişe
  /// aittir ve kapalı kalır — aksi hâlde aylar önceki bir gün işaretlendiğinde
  /// dönem bugüne kadar uzardı.
  bool _couldStillBeRunning(
    DateTime start,
    DateTime today,
    int expectedLength,
  ) => !_lastPossibleDay(start, expectedLength).isBefore(today);

  static DateTime _lastPossibleDay(DateTime start, int expectedLength) =>
      start.add(Duration(days: (expectedLength < 1 ? 1 : expectedLength) - 1));

  /// Kullanıcının bildirdiği bir **başlangıç tarihinden** kayıt üretir.
  ///
  /// Onboarding formu yalnızca "son reglin ne zaman başladı" diye soruyor.
  /// Ekran bu cevaptan `startDate + süre - 1` diye bir bitiş uyduruyor ve
  /// kaydı kapatıyordu: kullanıcının söylemediği bir tarih veri gibi
  /// yazılıyor, üstelik dönem hâlâ sürüyorsa kurulumun hemen ertesinde
  /// bitmiş görünüyordu.
  ///
  /// Kural [toggleDay] ile aynı olmak zorunda — ikisi de "beklenen süre
  /// dolmadıysa dönem sürüyor" diyor. Ayrı ayrı yazılsaydı biri değişip
  /// diğeri unutulurdu.
  PeriodLog recordFromStart(
    DateTime start, {
    DateTime? today,
    int expectedLength = PeriodLog.defaultOngoingLength,
  }) {
    final cleanStart = DateTime(start.year, start.month, start.day);
    final reference = today ?? DateTime.now();
    final cleanToday = DateTime(reference.year, reference.month, reference.day);

    return PeriodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: cleanStart,
      endDate: _couldStillBeRunning(cleanStart, cleanToday, expectedLength)
          ? null
          : _lastPossibleDay(cleanStart, expectedLength),
    );
  }

  /// Belirli bir tarihten önceki en son regl başlangıcını bulur.
  DateTime? getLastPeriodStartBefore(List<PeriodLog> logs, DateTime date) {
    if (logs.isEmpty) return null;
    final cleanDate = DateTime(date.year, date.month, date.day);
    final previousLogs = logs.where((l) {
      final logStart = DateTime(
        l.startDate.year,
        l.startDate.month,
        l.startDate.day,
      );
      return logStart.isBefore(cleanDate) ||
          logStart.isAtSameMomentAs(cleanDate);
    }).toList();

    if (previousLogs.isEmpty) return null;
    previousLogs.sort(
      (a, b) => b.startDate.compareTo(a.startDate),
    ); // En yakın geçmişten uzağa
    return previousLogs.first.startDate;
  }
}
