import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/daily_log.dart';
import '../../domain/models/conception_intent.dart';
import '../../domain/models/period_log.dart';
import '../../domain/services/backup_import_service.dart';
import '../../domain/services/cycle_intervals.dart';
import '../local/secure_store.dart';
import 'period_repository.dart';
import 'care_repository.dart';
import 'conception_repository.dart';
import 'pregnancy_repository.dart';

/// Gizlilik ekranının tercihleri ve veri yönetimi işlemleri.
class PrivacySettingsRepository {
  static const String _biometricKey = 'privacy_biometric_enabled';
  static const String _pinKey = 'privacy_pin_enabled';

  final SecureStore _store;
  final PeriodRepository _periodRepository;
  final PregnancyRepository _pregnancyRepository;
  final CareRepository _careRepository;
  final ConceptionRepository _conceptionRepository;

  const PrivacySettingsRepository({
    SecureStore store = const SecureStore(),
    PeriodRepository periodRepository = const PeriodRepository(),
    PregnancyRepository pregnancyRepository = const PregnancyRepository(),
    CareRepository careRepository = const CareRepository(),
    ConceptionRepository conceptionRepository = const ConceptionRepository(),
  }) : _store = store,
       _periodRepository = periodRepository,
       _pregnancyRepository = pregnancyRepository,
       _careRepository = careRepository,
       _conceptionRepository = conceptionRepository;

  // ─── Tercihler ───
  // Bunlar hassas veri değil, yalnızca aç/kapa tercihi.

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
  }

  Future<bool> getPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinKey) ?? false;
  }

  Future<void> setPinEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinKey, value);
  }

  // ─── Veri yönetimi ───

  /// Dışa aktarılacak ham veri.
  ///
  /// Biçimlendirme `DataExportService`'in işi; burada yalnızca okuma var.
  ///
  /// Gebelik kesintileri de dönüyor: hekime giden özetteki döngü uzunlukları
  /// ve ara kanama sayısı ekrandakiyle aynı kuralla hesaplanmalı. Aksi hâlde
  /// özet lohiayı ara kanama diye listeler.
  Future<
    ({
      List<PeriodLog> periodLogs,
      List<DailyLog> dailyLogs,
      List<DateSpan> breaks,
    })
  >
  loadExportData() async {
    return (
      periodLogs: await _periodRepository.getPeriodLogs(),
      dailyLogs: await _periodRepository.getDailyLogs(),
      breaks: CycleBreaks.fromPregnancies(await _pregnancyRepository.getAll()),
    );
  }

  /// Yedekten geri yüklenebilecek tam JSON.
  ///
  /// Okunabilir özet ve CSV kullanıcı içindir; bu, verinin kayıpsız hâli.
  Future<String> exportDataAsJson() async {
    final periodLogs = await _periodRepository.getPeriodLogs();
    final dailyLogs = await _periodRepository.getDailyLogs();
    final pregnancies = await _pregnancyRepository.getAll();
    final careEvents = await _careRepository.getAll();
    final conception = await _conceptionRepository.get();

    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'periodLogs': periodLogs.map((l) => l.toMap()).toList(),
      'dailyLogs': dailyLogs.map((l) => l.toMap()).toList(),
      // Gebelik yedekte olmasaydı yeni telefonda gebe kullanıcının
      // uygulaması döngü moduna düşerdi.
      'pregnancies': pregnancies.map((p) => p.toMap()).toList(),
      'careEvents': careEvents.map((e) => e.toMap()).toList(),
      // Kaybolursa ASRM'nin 6/12 aylık sayacı yeni telefonda sıfırlanır.
      if (conception != null) 'conceptionIntent': conception.toMap(),
    });
  }

  /// JSON yedeğini mevcut veriyle birleştirip kaydeder.
  ///
  /// Birleştirme kuralları [BackupImportService] içinde ve saf: cihazdaki
  /// kayıt her zaman kazanıyor, içe aktarma yalnızca eksik olanı ekliyor.
  /// Burada yalnızca okuma ve yazma var.
  ///
  /// Başarısız bir okumada depoya **hiç dokunulmuyor**: yarım yazılmış bir
  /// durum, hiç yazmamaktan kötü.
  Future<ImportReport> importDataFromJson(String json) async {
    await _restoreConceptionIntent(json);

    final result = BackupImportService.merge(
      json: json,
      periodLogs: await _periodRepository.getPeriodLogs(),
      dailyLogs: await _periodRepository.getDailyLogs(),
      pregnancies: await _pregnancyRepository.getAll(),
      careEvents: await _careRepository.getAll(),
    );

    if (!result.report.succeeded || result.report.totalAdded == 0) {
      return result.report;
    }

    await _periodRepository.savePeriodLogs(result.periodLogs);
    await _periodRepository.saveDailyLogs(result.dailyLogs);
    await _pregnancyRepository.saveAll(result.pregnancies);
    await _careRepository.saveAll(result.careEvents);
    return result.report;
  }

  /// Cihazdaki tüm kullanıcı verisini kalıcı olarak siler:
  /// şifreli depodaki sağlık verisi + yerel tercihler.
  ///
  /// Geri alınamaz. Uzak (Firestore) veriyi silmez — o, hesap silme akışının
  /// backend tarafına aittir.
  /// Cihazda niyet yoksa yedektekini alır; varsa cihazdaki kazanır.
  Future<void> _restoreConceptionIntent(String json) async {
    if (await _conceptionRepository.get() != null) return;
    try {
      final root = jsonDecode(json);
      final raw = root is Map<String, dynamic>
          ? root['conceptionIntent']
          : null;
      if (raw is! Map<String, dynamic>) return;
      final niyet = ConceptionIntent.fromMap(raw);
      // Gelecek tarihli bir niyet elle bozulmuş demek.
      if (niyet == null || niyet.since.isAfter(DateTime.now())) return;
      await _conceptionRepository.set(niyet);
    } catch (_) {
      return;
    }
  }

  Future<void> deleteAllLocalData() async {
    await _store.clearSensitiveData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
