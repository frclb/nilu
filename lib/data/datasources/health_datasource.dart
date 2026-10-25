import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/period_log.dart';
import '../../domain/services/health_export.dart';
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
  /// Okunacak veri tipleri: yalnız regl.
  ///
  /// Önceden uyku ve dinlenme nabzı da isteniyordu ama hiçbir ekran onları
  /// kullanmıyordu. İzin ekranında okunmayan veriyi istemek hem App Store
  /// incelemesinde (5.1.1) hem de gizlilik etiketinde yanlış bir beyan.
  static const List<HealthDataType> readTypes = [
    HealthDataType.MENSTRUATION_FLOW,
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

  /// Geçmiş verisine erişim (yalnız Android).
  ///
  /// Health Connect, ayrı bir izin olmadan yalnızca izin verilmeden önceki
  /// 30 günü okutuyor. Regl geçmişi tahminlerin temeli; bu izin olmadan
  /// içeri aktarma tek bir dönemle kalırdı. iOS'ta böyle bir sınır yok.
  ///
  /// Geçmiş okunabiliyorsa `true`.
  Future<bool> requestHistoryAccess() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    try {
      if (!await _health.isHealthDataHistoryAvailable()) return false;
      if (await _health.isHealthDataHistoryAuthorized()) return true;
      return await _health.requestHealthDataHistoryAuthorization();
    } on Exception catch (e) {
      debugPrint('Health history authorization failed: $e');
      return false;
    }
  }

  /// Health Connect kurulabilir ya da güncellenebilir mi (yalnız Android).
  ///
  /// Android 13 ve öncesinde Health Connect ayrı bir uygulama; kurulu değilse
  /// ya da eskiyse Play'deki sayfası açılabiliyor. Cihaz hiç desteklemiyorsa
  /// `false`: açılacak bir sayfa yok.
  Future<bool> canInstall() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final status = await _health.getHealthConnectSdkStatus();
      return status ==
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
    } on Exception catch (e) {
      debugPrint('Health Connect status check failed: $e');
      return false;
    }
  }

  /// Health Connect'in Play sayfasını açar.
  Future<void> install() async {
    try {
      await _health.installHealthConnect();
    } on Exception catch (e) {
      debugPrint('Health Connect install failed: $e');
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

  /// Uygulamanın regl günlerini Sağlık'a **ayna** olarak yazar.
  ///
  /// Önce bu uygulamanın [from]–[to] arasında yazdığı regl kayıtları
  /// siliniyor (HealthKit yalnız uygulamanın kendi kayıtlarını silmeye izin
  /// veriyor; başka uygulamaların ya da Apple Watch'un verisine dokunulmuyor),
  /// sonra güncel günler yazılıyor. Böylece uygulamada silinen bir gün
  /// Sağlık'ta kalmıyor, aynı gün iki kez yazılmıyor.
  Future<bool> mirrorPeriods(
    List<HealthPeriodDay> days, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      await _ensureConfigured();
      await _health.delete(
        type: HealthDataType.MENSTRUATION_FLOW,
        startTime: from,
        endTime: to,
      );
      var ok = true;
      for (final d in days) {
        final written = await _health.writeMenstruationFlow(
          flow: _flowOf(d.flow),
          isStartOfCycle: d.isStartOfCycle,
          startTime: d.date,
          endTime: d.date.add(const Duration(hours: 1)),
          // Kullanıcının kendi girdisi; ölçülmüş bir değer değil.
          recordingMethod: RecordingMethod.manual,
        );
        ok = ok && written;
      }
      return ok;
    } on Exception catch (e) {
      debugPrint('Health write failed: $e');
      return false;
    }
  }

  static MenstrualFlow _flowOf(String? code) => switch (code) {
    'light' => MenstrualFlow.light,
    'medium' => MenstrualFlow.medium,
    'heavy' => MenstrualFlow.heavy,
    _ => MenstrualFlow.unspecified,
  };
}
