import '../local/secure_store.dart';
import '../../domain/models/period_log.dart';
import '../../domain/models/daily_log.dart';

/// Regl ve günlük detay verilerini **şifreli** yerel depolamada yöneten
/// repository. Bu veriler hassas kişisel sağlık verisidir; düz metin olarak
/// saklanmaz (bkz. [SecureStore]).
class PeriodRepository {
  static const String _periodKey = 'period_logs';
  static const String _dailyKey = 'daily_logs';

  final SecureStore _store;

  const PeriodRepository({SecureStore store = const SecureStore()})
    : _store = store;

  /// Tüm kayıtlı regl loglarını getirir.
  Future<List<PeriodLog>> getPeriodLogs() async {
    final jsonList = await _store.getStringList(_periodKey) ?? [];
    return jsonList.map((j) => PeriodLog.fromJson(j)).toList();
  }

  /// Regl loglarını kaydeder.
  Future<void> savePeriodLogs(List<PeriodLog> logs) async {
    await _store.setStringList(
      _periodKey,
      logs.map<String>((l) => l.toJson()).toList(),
    );
  }

  /// Tüm günlük detayları getirir.
  Future<List<DailyLog>> getDailyLogs() async {
    final jsonList = await _store.getStringList(_dailyKey) ?? [];
    return jsonList.map((j) => DailyLog.fromJson(j)).toList();
  }

  /// Günlük detayları kaydeder.
  Future<void> saveDailyLogs(List<DailyLog> logs) async {
    await _store.setStringList(
      _dailyKey,
      logs.map<String>((l) => l.toJson()).toList(),
    );
  }
}
