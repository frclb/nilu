import 'dart:convert';

import '../models/daily_log.dart';
import '../models/period_log.dart';

/// İçe aktarmanın neden başarısız olduğu.
enum ImportFailure {
  /// Dosya JSON olarak okunamadı.
  unreadable,

  /// JSON okunuyor ama bu uygulamanın yedeği değil.
  wrongFormat,

  /// Yedek geçerli ama içinde kayıt yok.
  empty,
}

/// İçe aktarma sonucu.
///
/// Sayılar kullanıcıya gösteriliyor: "şu kadar eklendi, şu kadar atlandı"
/// demek, sessizce bir şey yapmaktan iyi. Atlananın sebebi de ayrı
/// tutuluyor — zaten var olan bir gün ile bozuk bir kayıt aynı şey değil.
class ImportReport {
  const ImportReport({
    this.periodsAdded = 0,
    this.dailyAdded = 0,
    this.alreadyPresent = 0,
    this.invalid = 0,
    this.failure,
  });

  const ImportReport.failed(this.failure)
    : periodsAdded = 0,
      dailyAdded = 0,
      alreadyPresent = 0,
      invalid = 0;

  final int periodsAdded;
  final int dailyAdded;

  /// Cihazda zaten bulunan ve bu yüzden dokunulmayan kayıt sayısı.
  final int alreadyPresent;

  /// Okunamayan ya da uygulamanın kurallarına uymayan kayıt sayısı.
  final int invalid;

  final ImportFailure? failure;

  bool get succeeded => failure == null;
  int get totalAdded => periodsAdded + dailyAdded;
}

/// İçe aktarılmış veri ile birleştirilmiş sonuç.
class ImportedData {
  const ImportedData({
    required this.periodLogs,
    required this.dailyLogs,
    required this.report,
  });

  final List<PeriodLog> periodLogs;
  final List<DailyLog> dailyLogs;
  final ImportReport report;
}

/// JSON yedeğini mevcut veriyle birleştirir.
///
/// Dışa aktarma "tam yedek (JSON)" diyordu ama geri yükleme yoktu: ad
/// kullanıcıya yapamayacağı bir şeyi vaat ediyordu.
///
/// **Birleştirme asla yıkıcı değil.** Cihazdaki kayıt her zaman kazanır;
/// içe aktarma yalnızca eksik olanı ekler. Sebebi şu: kullanıcı elindeki
/// tek yedeği yanlış zamanda açtığında aylarca kaydını kaybedebilirdi ve
/// bu geri alınamaz. Eski bir yedeği açmak en kötü ihtimalle hiçbir şey
/// yapmaz.
///
/// Saf fonksiyon: dosya sistemi ya da depo bilmeden test edilebiliyor.
class BackupImportService {
  const BackupImportService._();

  /// Geçmişe doğru kabul edilen en uzak sınır (yıl).
  ///
  /// Yedek dosyası kullanıcının **elle düzenleyebileceği** tek girdi; başka
  /// her yer seçici ve düğmelerle sınırlı. Elle yazılmış bir tarih hiçbir
  /// yerde çökme üretmiyor ama ekranda anlamsız sayılar bırakıyor: yıl 1
  /// tarihli bir kayıt ana ekranda "739880. gün" ve "739851 gün gecikme"
  /// yazdırıyordu (ölçüldü). Sağlık uygulamasında uydurma bir sayı,
  /// çökmeden daha kötü — veri gibi görünüyor.
  ///
  /// Elli yıl, bir insanın kendi regl geçmişinin dış sınırı.
  static const int maxHistoryYears = 50;

  /// [json] yedeğini [periodLogs] ve [dailyLogs] ile birleştirir.
  ///
  /// [today] gelecek tarihli kayıtları elemek için; varsayılan bugündür.
  static ImportedData merge({
    required String json,
    required List<PeriodLog> periodLogs,
    required List<DailyLog> dailyLogs,
    DateTime? today,
  }) {
    final Map<String, dynamic> root;
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) {
        return _unchanged(periodLogs, dailyLogs, ImportFailure.wrongFormat);
      }
      root = decoded;
    } on FormatException {
      return _unchanged(periodLogs, dailyLogs, ImportFailure.unreadable);
    }

    final rawPeriods = root['periodLogs'];
    final rawDaily = root['dailyLogs'];
    if (rawPeriods is! List && rawDaily is! List) {
      return _unchanged(periodLogs, dailyLogs, ImportFailure.wrongFormat);
    }

    final limit = _day(today ?? DateTime.now());
    final earliest = DateTime(limit.year - maxHistoryYears, limit.month, limit.day);
    var alreadyPresent = 0;
    var invalid = 0;

    // ── Dönemler ──
    final periods = List<PeriodLog>.from(periodLogs);
    var periodsAdded = 0;

    for (final entry in (rawPeriods is List ? rawPeriods : const [])) {
      final log = _readPeriod(entry);
      if (log == null) {
        invalid++;
        continue;
      }

      // Gelecekte başlayan dönem uygulamanın hiçbir yerinde üretilemiyor;
      // saati yanlış bir cihazdan gelen böyle bir kayıt tahminlerin
      // tamamını bozardı. Çok eski tarih de aynı şekilde: bkz.
      // [maxHistoryYears].
      if (!_isPlausible(log.startDate, earliest, limit)) {
        invalid++;
        continue;
      }

      // Bitişi başlangıcından önce olan kayıt. Uygulamanın hiçbir akışı
      // böyle bir şey üretmiyor; geldiğinde dönem uzunluğu negatife
      // düşüyor ve ekranda "-8 gün" gibi bir sayı çıkıyor.
      final end = log.endDate;
      if (end != null && _day(end).isBefore(_day(log.startDate))) {
        invalid++;
        continue;
      }

      if (periods.any((existing) => _overlaps(existing, log))) {
        alreadyPresent++;
        continue;
      }

      periods.add(log);
      periodsAdded++;
    }
    periods.sort((a, b) => a.startDate.compareTo(b.startDate));

    // ── Günlük kayıtlar ──
    final daily = List<DailyLog>.from(dailyLogs);
    final existingDays = daily.map((l) => _key(l.date)).toSet();
    var dailyAdded = 0;

    for (final entry in (rawDaily is List ? rawDaily : const [])) {
      final log = _readDaily(entry);
      if (log == null) {
        invalid++;
        continue;
      }
      // Günlük kayıtta hiç tarih sınırı yoktu: yıl 9999 tarihli bir kayıt
      // takvimde ve dışa aktarmada öylece duruyordu.
      if (!_isPlausible(log.date, earliest, limit)) {
        invalid++;
        continue;
      }
      if (!existingDays.add(_key(log.date))) {
        alreadyPresent++;
        continue;
      }
      daily.add(log);
      dailyAdded++;
    }
    daily.sort((a, b) => a.date.compareTo(b.date));

    final nothingUsable =
        periodsAdded == 0 && dailyAdded == 0 && alreadyPresent == 0;

    return ImportedData(
      periodLogs: periods,
      dailyLogs: daily,
      report: nothingUsable && invalid == 0
          ? const ImportReport.failed(ImportFailure.empty)
          : ImportReport(
              periodsAdded: periodsAdded,
              dailyAdded: dailyAdded,
              alreadyPresent: alreadyPresent,
              invalid: invalid,
            ),
    );
  }

  static ImportedData _unchanged(
    List<PeriodLog> periods,
    List<DailyLog> daily,
    ImportFailure failure,
  ) => ImportedData(
    periodLogs: periods,
    dailyLogs: daily,
    report: ImportReport.failed(failure),
  );

  static PeriodLog? _readPeriod(Object? entry) {
    if (entry is! Map) return null;
    try {
      return PeriodLog.fromMap(Map<String, dynamic>.from(entry));
    } catch (_) {
      return null;
    }
  }

  static DailyLog? _readDaily(Object? entry) {
    if (entry is! Map) return null;
    try {
      return DailyLog.fromMap(Map<String, dynamic>.from(entry));
    } catch (_) {
      return null;
    }
  }

  /// İki dönem aynı günlere mi uzanıyor?
  ///
  /// Yalnızca başlangıç tarihini karşılaştırmak yetmiyor: bir gün kayık
  /// başlayan iki kayıt üst üste binerdi ve döngü uzunluğu hesabı
  /// bozulurdu.
  /// Tarih, bir insanın kendi geçmişi olabilecek aralıkta mı?
  static bool _isPlausible(DateTime date, DateTime earliest, DateTime limit) {
    final day = _day(date);
    return !day.isAfter(limit) && !day.isBefore(earliest);
  }

  static bool _overlaps(PeriodLog a, PeriodLog b) {
    final aStart = _day(a.startDate);
    final aEnd = _day(a.endDate ?? a.startDate);
    final bStart = _day(b.startDate);
    final bEnd = _day(b.endDate ?? b.startDate);
    return !aEnd.isBefore(bStart) && !bEnd.isBefore(aStart);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
