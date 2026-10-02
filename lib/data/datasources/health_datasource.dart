import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/calendar_day.dart';
import '../../domain/models/period_log.dart';
import '../../domain/services/health_import.dart';

/// Sağlık verisine erişim isteğinin sonucu.
enum HealthAccess {
  /// Kullanıcı izin verdi.
  granted,

  /// Kullanıcı istemi gördü ve reddetti.
  denied,

  /// İstem hiç açılamadı — yetki yok ya da platform desteklemiyor.
  /// Kullanıcının yapabileceği bir şey yok.
  unavailable,
}

/// Apple Sağlık / Health Connect köprüsü.
///
/// Apple Watch ve diğer uygulamaların verisi zaten HealthKit'e akıyor;
/// ayrı bir giyilebilir cihaz entegrasyonu gerekmiyor.
///
/// Tüm platform çağrıları burada; birleştirme mantığı `HealthImport`'ta ve
/// saf. Böylece kural değişikliği için cihaz gerekmiyor.
class HealthDatasource {
  /// Okunacak veri tipleri.
  ///
  /// Regl verisi tahminleri besliyor; uyku ve dinlenme nabzı ise döngü
  /// evresiyle ilişkili sinyaller — kullanıcı bunları zaten saatinden
  /// topluyor, tekrar elle girmesi anlamsız.
  static const List<HealthDataType> readTypes = [
    HealthDataType.MENSTRUATION_FLOW,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.RESTING_HEART_RATE,
  ];

  /// Yazılacak tipler. Yalnızca regl: uygulamanın ürettiği tek veri bu.
  static const List<HealthDataType> writeTypes = [
    HealthDataType.MENSTRUATION_FLOW,
  ];

  final Health _health;
  final Uuid _uuid;

  HealthDatasource({Health? health, Uuid? uuid})
    : _health = health ?? Health(),
      _uuid = uuid ?? const Uuid();

  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Cihaz Sağlık verisi sunuyor mu.
  Future<bool> isAvailable() async {
    try {
      await _ensureConfigured();
      // iOS'ta HealthKit her zaman var; Android'de Health Connect kurulu
      // olmayabilir.
      if (defaultTargetPlatform == TargetPlatform.iOS) return true;
      return await _health.isHealthConnectAvailable();
    } on Exception catch (e) {
      debugPrint('Health availability check failed: $e');
      return false;
    }
  }

  /// İzin ister.
  ///
  /// iOS izin **durumunu** güvenilir biçimde bildirmiyor (gizlilik gereği:
  /// bir uygulamanın hangi veriye erişimi reddedildiğini bilmesi de bilgi
  /// sızdırır). Bu yüzden "izin var mı" diye sormak yerine doğrudan istenip
  /// sonucuna bakılıyor.
  ///
  /// Üç sonuç ayrı tutuluyor. Önce yalnızca "oldu / olmadı" vardı ve istem
  /// hiç açılamadığında da "olmadı" dönüyordu; ekran bunu "izin verilmedi"
  /// diye gösteriyordu. Kullanıcıya hiçbir şey sorulmamışken ona reddetmiş
  /// gibi davranmak yanlış — üstelik yapabileceği bir şey de yok, sorun
  /// derlemede HealthKit yetkisinin bulunmaması.
  Future<HealthAccess> requestPermissions({bool includeWrite = false}) async {
    try {
      await _ensureConfigured();
      final types = includeWrite ? [...readTypes, ...writeTypes] : readTypes;
      final permissions = [
        ...readTypes.map((_) => HealthDataAccess.READ),
        if (includeWrite) ...writeTypes.map((_) => HealthDataAccess.READ_WRITE),
      ];
      final granted = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      return granted ? HealthAccess.granted : HealthAccess.denied;
    } on Exception catch (e) {
      // İstem açılamadı: yetki yok, HealthKit kapalı ya da platform
      // desteklemiyor. Kullanıcının kararı değil.
      debugPrint('Health authorization failed: $e');
      return HealthAccess.unavailable;
    }
  }

  /// Sağlık'taki regl günlerini dönemlere çevirir.
  Future<List<PeriodLog>> readPeriods({required DateTime since}) async {
    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.MENSTRUATION_FLOW],
        startTime: since,
        endTime: DateTime.now(),
      );

      final days = points.map((p) => HealthFlowDay(date: p.dateFrom)).toList();

      return HealthImport.toPeriods(days, nextId: () => _uuid.v4());
    } on Exception catch (e) {
      debugPrint('Health read failed: $e');
      return const [];
    }
  }

  /// Son [days] gün için ortalama gece uykusu (saat).
  ///
  /// Veri yoksa null — uydurma bir ortalama göstermektense hiçbir şey
  /// göstermemek doğru.
  Future<double?> averageSleepHours({int days = 14}) async {
    try {
      await _ensureConfigured();
      final points = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_ASLEEP],
        startTime: DateTime.now().subtract(Duration(days: days)),
        endTime: DateTime.now(),
      );
      if (points.isEmpty) return null;

      final totalMinutes = points.fold<double>(
        0,
        (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes,
      );
      final nights = points
          .map(
            (p) => DateTime(p.dateFrom.year, p.dateFrom.month, p.dateFrom.day),
          )
          .toSet()
          .length;
      if (nights == 0) return null;

      return (totalMinutes / nights) / 60;
    } on Exception catch (e) {
      debugPrint('Health sleep read failed: $e');
      return null;
    }
  }

  /// Uygulamada işaretlenen regl günlerini Sağlık'a yazar.
  Future<bool> writePeriod(PeriodLog log) async {
    try {
      await _ensureConfigured();
      final end = log.endDate ?? log.startDate;
      var ok = true;
      for (var day = log.startDate; !day.isAfter(end); day = day.plusDays(1)) {
        final written = await _health.writeMenstruationFlow(
          flow: MenstrualFlow.medium,
          isStartOfCycle: day == log.startDate,
          startTime: day,
          endTime: day.add(const Duration(hours: 1)),
        );
        ok = ok && written;
      }
      return ok;
    } on Exception catch (e) {
      debugPrint('Health write failed: $e');
      return false;
    }
  }
}
