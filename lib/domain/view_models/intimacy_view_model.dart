import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/intimacy_repository.dart';
import '../../data/repositories/share_settings_repository.dart';
import '../models/intimacy_status.dart';
import '../services/intimacy_share_service.dart';

/// Sahibin yakınlık durumu ve partnerle paylaşımı.
///
/// Paylaşım üç koşulda yapılıyor: onaylanmış bir partner var, kullanıcı
/// açık rıza vermiş ve paylaşım açık. Önceden kontrol yalnızca ayarlara
/// bakıyordu ve ayar varsayılan olarak açıktı; partneri olmayan kullanıcıya
/// da paylaşım düğmesi gösteriliyordu.
class IntimacyViewModel extends ChangeNotifier {
  final IntimacyRepository _repository;
  final IntimacyShareService _shareService;
  final ShareSettingsRepository _shareSettings;

  IntimacyViewModel({
    IntimacyRepository? repository,
    IntimacyShareService? shareService,
    ShareSettingsRepository shareSettings = const ShareSettingsRepository(),
  }) : _repository = repository ?? IntimacyRepository(),
       _shareService = shareService ?? IntimacyShareService(),
       _shareSettings = shareSettings {
    _ready = _loadState();
  }

  /// Paylaşımı kapatınca sunucudaki durum silinemediyse sonraki açılışta
  /// yeniden deneniyor.
  static const String _retractPendingKey = 'intimacy_retract_pending';

  // ─── State ───
  String? _selectedSexualDesire;
  List<String> _selectedAffectionNeeds = [];
  bool _isAutoShareEnabled = false;
  DateTime? _lastSharedAt;
  bool _isSharing = false;
  String? _shareError;
  bool _isLoaded = false;
  bool _sharingOn = false;
  bool _retractPending = false;

  String? _currentUserId;
  bool _hasPartner = false;
  late final Future<void> _ready;

  // ─── Debounce ───
  //
  // Arka arkaya birkaç seçim tek gönderimde gitsin diye kısa bir bekleme.
  // 10 saniyeydi; partnerin ekranına "anlık" gelmesi beklendiği için
  // kısaldı (TestFlight bulgusu).
  //
  // Günlük 10 paylaşım sınırı da kaldırıldı: yalnızca bu cihazda sayılan,
  // sunucuyu korumayan bir sayaçtı ve otomatik paylaşımda her seçim bir
  // hak yiyordu ("Bugün 9 paylaşım hakkın kaldı").
  Timer? _debounceTimer;
  static const Duration debounceDuration = Duration(seconds: 3);

  // ─── Getters ───
  String? get selectedSexualDesire => _selectedSexualDesire;
  List<String> get selectedAffectionNeeds =>
      List.unmodifiable(_selectedAffectionNeeds);
  bool get isAutoShareEnabled => _isAutoShareEnabled;
  DateTime? get lastSharedAt => _lastSharedAt;
  bool get isSharing => _isSharing;
  String? get shareError => _shareError;
  bool get isLoaded => _isLoaded;

  /// Kullanıcı açık rıza verdi ve paylaşım açık.
  bool get sharingOn => _sharingOn;

  /// Onaylanmış bir partner var (sahip rolünde).
  bool get hasPartner => _hasPartner;

  /// [uid]: sahibin kimliği. [hasPartner]: onaylanmış partner var mı.
  void init(String? uid, {bool hasPartner = false}) {
    final changed = uid != _currentUserId || hasPartner != _hasPartner;
    _currentUserId = uid;
    _hasPartner = hasPartner;
    if (changed && _isLoaded) {
      notifyListeners();
      _tryFlushOfflineQueue();
    }
  }

  Future<void> _loadState() async {
    _selectedSexualDesire = await _repository.getSexualDesire();
    _selectedAffectionNeeds = await _repository.getAffectionNeeds();
    _isAutoShareEnabled = await _repository.getAutoShareEnabled();
    _lastSharedAt = await _repository.getLastSharedAt();
    _sharingOn = (await _shareSettings.load()).sharesAnything;
    _retractPending = await _repository.getFlag(_retractPendingKey);
    _isLoaded = true;
    notifyListeners();

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

  /// Açık rıza alındıktan sonra paylaşımı açar. Rıza metni ekranın işi
  /// (bkz. `askIntimacyConsent`); burada yalnızca kaydı tutuluyor.
  ///
  /// Partner varsa mevcut seçimler hemen gidiyor: önceden paylaşımı açmak
  /// bir sonraki seçim değişikliğini bekliyordu.
  Future<void> startSharing() async {
    await _ready;
    await _shareSettings.grantConsent();
    _sharingOn = true;
    _shareError = null;
    notifyListeners();
    if (_hasPartner) await _performShare();
  }

  /// Partner onaylanırken: onay sayfasında gösterilen seçimler kaydedilir,
  /// rıza ve otomatik paylaşım açılır, durum **hemen** gönderilir.
  ///
  /// Önceden onaydan sonra hiçbir şey gitmiyordu: partnerin ekranı sahip
  /// "Partnerinle Paylaş"a basana ya da bir seçimi değiştirene kadar
  /// "Henüz veri yok" diyordu. Sahip de onaylarken partnerin neyi
  /// göreceğini görmüyordu.
  ///
  /// Gönderilemezse `false`; durum kuyrukta kalıyor.
  Future<bool> approveAndShare(
    String uid, {
    String? sexualDesire,
    required List<String> affectionNeeds,
  }) async {
    await _ready;
    _debounceTimer?.cancel();
    // Onay `UserViewModel`'den yeni geçti; sağlayıcının bunu buraya
    // taşıması bir sonraki kareyi bekliyor.
    _currentUserId = uid;
    _hasPartner = true;

    _selectedSexualDesire = sexualDesire;
    _selectedAffectionNeeds = List.of(affectionNeeds);
    if (sexualDesire == null) {
      await _repository.clearSexualDesire();
    } else {
      await _repository.saveSexualDesire(sexualDesire);
    }
    await _repository.saveAffectionNeeds(_selectedAffectionNeeds);

    await _shareSettings.grantConsent();
    _sharingOn = true;
    _isAutoShareEnabled = true;
    await _repository.saveAutoShareEnabled(true);
    _shareError = null;
    notifyListeners();

    await _performShare();
    return _shareError == null;
  }

  /// Paylaşımı kapatır, rızayı geri alır ve sunucudaki durumu siler.
  ///
  /// Önceden kapatmak yalnızca bundan sonraki gönderimleri durduruyordu;
  /// paylaşılmış son durum partnerin ekranında kalıyordu. Silme başarısız
  /// olursa `false` döner ve sonraki açılışta yeniden denenir.
  Future<bool> stopSharing() async {
    await _ready;
    _debounceTimer?.cancel();
    await _shareSettings.withdrawConsent();
    await _repository.clearOfflineQueue();
    _sharingOn = false;
    _shareError = null;
    notifyListeners();
    return _retract();
  }

  Future<bool> _retract() async {
    final uid = _currentUserId;
    if (uid == null) return true;
    final ok = await _shareService.retract(uid);
    _retractPending = !ok;
    await _repository.setFlag(_retractPendingKey, !ok);
    return ok;
  }

  /// Seçim değişikliğinde çağrılır — otomatik paylaşım açıksa debounce başlatır.
  void _onSelectionChanged() {
    if (_isAutoShareEnabled && _sharingOn && _hasPartner) {
      _startDebounce();
    }
  }

  void _startDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, _performShare);
  }

  /// Manuel paylaşım tetikler.
  Future<void> manualShare() => _performShare();

  Future<void> _performShare() async {
    if (_currentUserId == null || !_hasPartner) {
      _shareError = 'no_partner';
      notifyListeners();
      return;
    }

    // Rıza ve ayar her gönderimde yeniden okunuyor: başka bir ekranda
    // kapatılmış olabilir.
    final settings = await _shareSettings.load();
    _sharingOn = settings.sharesAnything;
    if (!_sharingOn) {
      _shareError = 'sharing_disabled';
      notifyListeners();
      return;
    }

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

    final success = await _shareService.shareWithPartner(
      _currentUserId!,
      status,
    );
    if (success) {
      _lastSharedAt = DateTime.now();
      await _repository.saveLastSharedAt(_lastSharedAt!);
      await _repository.clearOfflineQueue();
    } else {
      await _repository.saveOfflineQueue(status.toJsonString());
      _shareError = 'share_failed';
    }

    _isSharing = false;
    notifyListeners();
  }

  /// Bekleyen işleri dener: geri çekilememiş durumu siler, kuyruktaki
  /// durumu gönderir.
  ///
  /// Kuyruk önceden ayara bakmadan gönderiliyordu: çevrimdışıyken
  /// paylaşılan bir durum, kullanıcı paylaşımı kapattıktan sonra bağlantı
  /// gelince yine de gidiyordu.
  Future<void> _tryFlushOfflineQueue() async {
    if (_currentUserId == null) return;

    if (_retractPending) {
      await _retract();
      return;
    }

    final queueData = await _repository.getOfflineQueue();
    if (queueData == null) return;

    final settings = await _shareSettings.load();
    if (!_hasPartner || !settings.sharesAnything) {
      await _repository.clearOfflineQueue();
      return;
    }

    try {
      final status = IntimacyStatus.fromJsonString(queueData);
      if (await _shareService.shareWithPartner(_currentUserId!, status)) {
        await _repository.clearOfflineQueue();
      }
    } catch (_) {
      // Bozuk kayıt: göndermeye değmez.
      await _repository.clearOfflineQueue();
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
