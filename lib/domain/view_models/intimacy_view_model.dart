import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/intimacy_repository.dart';
import '../../data/repositories/share_settings_repository.dart';
import '../models/intimacy_status.dart';
import '../services/intimacy_share_service.dart';

/// Duygusal yakınlık durumu için state management.
/// Debounce, rate limiting, offline queue ve otomatik paylaşım desteği içerir.
class IntimacyViewModel extends ChangeNotifier {
  final IntimacyRepository _repository = IntimacyRepository();
  final IntimacyShareService _shareService = IntimacyShareService();
  final ShareSettingsRepository _shareSettings =
      const ShareSettingsRepository();

  // ─── State ───
  String? _selectedSexualDesire;
  List<String> _selectedAffectionNeeds = [];
  bool _isAutoShareEnabled = false;
  DateTime? _lastSharedAt;
  int _dailyShareCount = 0;
  bool _isSharing = false;
  String? _shareError;
  bool _isLoaded = false;

  String? _currentUserId; // Eklenen UID

  // ─── Debounce ───
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(seconds: 10);

  // ─── Rate Limit ───
  static const int _maxDailyShares = 10;

  // ─── Getters ───
  String? get selectedSexualDesire => _selectedSexualDesire;
  List<String> get selectedAffectionNeeds =>
      List.unmodifiable(_selectedAffectionNeeds);
  bool get isAutoShareEnabled => _isAutoShareEnabled;
  DateTime? get lastSharedAt => _lastSharedAt;
  int get dailyShareCount => _dailyShareCount;
  bool get isSharing => _isSharing;
  String? get shareError => _shareError;
  bool get isLoaded => _isLoaded;
  bool get canShare => _dailyShareCount < _maxDailyShares;
  int get remainingShares => _maxDailyShares - _dailyShareCount;

  IntimacyViewModel() {
    _loadState();
  }

  void init(String? uid) {
    _currentUserId = uid;
  }

  /// Yerel depolamadan son durumu yükler.
  Future<void> _loadState() async {
    _selectedSexualDesire = await _repository.getSexualDesire();
    _selectedAffectionNeeds = await _repository.getAffectionNeeds();
    _isAutoShareEnabled = await _repository.getAutoShareEnabled();
    _lastSharedAt = await _repository.getLastSharedAt();
    _dailyShareCount = await _repository.getDailyShareCount();
    _isLoaded = true;
    notifyListeners();

    // Çevrimdışı kuyrukta veri varsa göndermeyi dene
    _tryFlushOfflineQueue();
  }

  /// Cinsel istek seçimini günceller (tek seçim).
  Future<void> selectSexualDesire(String value) async {
    if (_selectedSexualDesire == value) return;
    _selectedSexualDesire = value;
    _shareError = null;
    notifyListeners();

    await _repository.saveSexualDesire(value);
    _onSelectionChanged();
  }

  /// Sevgi ihtiyacı seçimini değiştirir (çoklu seçim toggle).
  Future<void> toggleAffectionNeed(String need) async {
    _shareError = null;
    if (_selectedAffectionNeeds.contains(need)) {
      _selectedAffectionNeeds.remove(need);
    } else {
      _selectedAffectionNeeds.add(need);
    }
    notifyListeners();

    await _repository.saveAffectionNeeds(_selectedAffectionNeeds);
    _onSelectionChanged();
  }

  /// Otomatik paylaşım ayarını değiştirir.
  Future<void> setAutoShareEnabled(bool enabled) async {
    _isAutoShareEnabled = enabled;
    notifyListeners();

    await _repository.saveAutoShareEnabled(enabled);

    if (!enabled) {
      _debounceTimer?.cancel();
    }
  }

  /// Seçim değişikliğinde çağrılır — otomatik paylaşım açıksa debounce başlatır.
  void _onSelectionChanged() {
    if (_isAutoShareEnabled) {
      _startDebounce();
    }
  }

  /// Debounce timer'ı başlatır/sıfırlar.
  void _startDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _performShare();
    });
  }

  /// Manuel paylaşım tetikler.
  Future<void> manualShare() async {
    await _performShare();
  }

  /// Paylaşım işlemini gerçekleştirir.
  Future<void> _performShare() async {
    if (_currentUserId == null) {
      _shareError = 'not_logged_in';
      notifyListeners();
      return;
    }

    // Gizlilik kontrolü: kullanıcı paylaşım ayarlarında her şeyi kapattıysa
    // hiçbir veri gönderilmez. Bu ayarlar bir gizlilik sözüdür; sessizce
    // yok sayılamaz.
    final settings = await _shareSettings.load();
    if (!settings.sharesAnything) {
      _shareError = 'sharing_disabled';
      notifyListeners();
      return;
    }

    // Rate limit kontrolü
    if (!canShare) {
      _shareError = 'rate_limit_exceeded';
      notifyListeners();
      return;
    }

    // Seçim kontrolü
    if (_selectedSexualDesire == null && _selectedAffectionNeeds.isEmpty) {
      return;
    }

    _isSharing = true;
    _shareError = null;
    notifyListeners();

    final status = IntimacyStatus(
      sexualDesire: _selectedSexualDesire ?? '',
      affectionNeeds: List.from(_selectedAffectionNeeds),
      timestamp: DateTime.now(),
      isShared: true,
    );

    try {
      final success = await _shareService.shareWithPartner(
        _currentUserId!,
        status,
      );

      if (success) {
        _lastSharedAt = DateTime.now();
        _dailyShareCount++;
        await _repository.saveLastSharedAt(_lastSharedAt!);
        await _repository.incrementDailyShareCount();
        await _repository.clearOfflineQueue();
      } else {
        // Başarısız — offline kuyruğa ekle
        await _repository.saveOfflineQueue(status.toJsonString());
        _shareError = 'share_failed';
      }
    } catch (e) {
      // Hata — offline kuyruğa ekle
      await _repository.saveOfflineQueue(status.toJsonString());
      _shareError = 'share_failed';
    }

    _isSharing = false;
    notifyListeners();
  }

  /// Çevrimdışı kuyrukta bekleyen veriyi göndermeyi dener.
  Future<void> _tryFlushOfflineQueue() async {
    if (_currentUserId == null) return;

    final queueData = await _repository.getOfflineQueue();
    if (queueData == null) return;

    try {
      final status = IntimacyStatus.fromJsonString(queueData);
      final success = await _shareService.shareWithPartner(
        _currentUserId!,
        status,
      );
      if (success) {
        await _repository.clearOfflineQueue();
      }
    } catch (_) {
      // Sessizce başarısız — sonraki açılışta tekrar denenir
    }
  }

  /// Hata mesajını temizler.
  void clearError() {
    _shareError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
