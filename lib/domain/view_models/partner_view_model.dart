import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../models/intimacy_status.dart';
import '../services/partner_suggestion_engine.dart';

/// Partner cihazındaki bağlantının durumu.
enum PartnerLinkState {
  /// Bu cihaz bir kodu okutmadı.
  notConnected,

  /// Eşleşme sunucusu yok (Firebase yapılandırılmamış).
  unavailable,

  /// İstek gönderildi; sahip henüz onaylamadı. Kurallar okumayı
  /// reddediyor.
  awaitingApproval,

  /// Sunucuya ulaşılamadı; yeniden denenecek.
  unreachable,

  /// Onaylandı ve dinleniyor. Paylaşılan durum olmayabilir.
  connected,
}

/// Partner tarafında, sahibin paylaştığı yakınlık durumunu izleyen
/// ViewModel. Yalnızca **partner rolündeki** cihazda kullanılıyor.
///
/// Önceden sahibin cihazında da çalışıyordu: sahip, partnerinin
/// `intimacy` dokümanını dinliyordu (partner bir şey paylaşmıyor, kurallar
/// da reddediyor). Partner tarafında ise onay gelmeden açılan dinleyici
/// "izin yok" hatasıyla kapanıyor ve onaydan sonra bir daha açılmıyordu;
/// partner uygulamayı yeniden başlatana kadar hiçbir şey görmüyordu.
class PartnerViewModel extends ChangeNotifier {
  /// Testten sahte bir kaynak verilebilsin diye enjekte ediliyor.
  final FirestoreDataSource _firestoreDS;

  /// Onay beklerken ya da bağlantı koptuğunda yeniden deneme aralığı.
  final Duration retryInterval;

  PartnerViewModel({
    FirestoreDataSource? firestore,
    this.retryInterval = const Duration(seconds: 30),
  }) : _firestoreDS = firestore ?? FirestoreDataSource();

  // ─── State ───
  PartnerLinkState _state = PartnerLinkState.notConnected;
  IntimacyStatus? _currentStatus;
  DateTime? _lastUpdatedAt;
  List<IntimacyStatus> _historyList = [];
  bool _isLoaded = false;
  bool _hasNewUpdate = false;

  /// Şu an dinlenen sahip ve `init`'in hiç çağrılıp çağrılmadığı.
  /// `ChangeNotifierProxyProvider.update` her yeniden çizimde `init`
  /// çağırıyor.
  String? _listeningTo;
  bool _initialized = false;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _statusSubscription;
  Timer? _retryTimer;

  /// Partnerin bıraktığı istek: kod ve kendi kimliği. Onay beklerken bu
  /// istek dinleniyor.
  String? _requestToken;
  String? _myUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _requestSubscription;

  /// İstek bir kez kapandı (onay ya da ret). Bundan sonra dinlenmiyor:
  /// reddedilen istekte okuma yine reddedilir ve dinleyici aynı silinmiş
  /// isteği görüp durmadan yeniden denerdi.
  bool _requestClosed = false;

  // ─── Getters ───
  PartnerLinkState get state => _state;
  IntimacyStatus? get currentStatus => _currentStatus;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  /// Bu cihaz bir sahiple eşleşmiş mi (onay bekliyor olsa da)?
  bool get isConnected => _state != PartnerLinkState.notConnected;
  List<IntimacyStatus> get historyList => List.unmodifiable(_historyList);
  bool get isLoaded => _isLoaded;
  bool get hasNewUpdate => _hasNewUpdate;
  bool get hasData => _currentStatus != null;

  /// Suggestion engine'den mevcut öneriler.
  List<PartnerSuggestion> get suggestions =>
      PartnerSuggestionEngine.generate(_currentStatus);

  /// Son güncellemenin üzerinden geçen süre. Metne çevirme işi View'a aittir.
  Duration? get timeSinceLastUpdate => _lastUpdatedAt == null
      ? null
      : DateTime.now().difference(_lastUpdatedAt!);

  /// >24 saat eski veri kontrolü.
  bool get isDataStale {
    if (_lastUpdatedAt == null) return false;
    return DateTime.now().difference(_lastUpdatedAt!).inHours >= 24;
  }

  /// Sahibin kimliğiyle başlatılır; partner rolünde değilse `null`.
  ///
  /// [requestToken] ve [myUid] partnerin bıraktığı istek: onay beklerken
  /// dinleniyor ki sahip onaylar onaylamaz ekran açılsın.
  ///
  /// Durum değişmediyse hiçbir şey yapılmıyor: `update` her çizimde
  /// çağırıyor ve her yeni dinleyici Firestore'da okuma olarak
  /// faturalandırılıyor.
  void init(String? ownerUid, {String? requestToken, String? myUid}) {
    final id = (ownerUid != null && ownerUid.isNotEmpty) ? ownerUid : null;
    _requestToken = requestToken;
    _myUid = myUid;
    if (_initialized && id == _listeningTo) return;
    _initialized = true;
    _listeningTo = id;
    _reset();

    if (id == null) {
      _state = PartnerLinkState.notConnected;
      _isLoaded = true;
    } else if (!_firestoreDS.isAvailable) {
      _state = PartnerLinkState.unavailable;
      _isLoaded = true;
    } else {
      // Bağlantı kuruldu sayılıyor: ilk anlık görüntü ağ turundan sonra
      // geliyor ve o ana kadar eşleşmiş kullanıcıya "bağlantı yok"
      // denmemeli.
      _state = PartnerLinkState.connected;
      _subscribe(id);
    }
    notifyListeners();
  }

  /// Hemen yeniden dener (aşağı çekip yenileme, uygulama öne gelince).
  void retry() {
    final id = _listeningTo;
    if (id == null || !_firestoreDS.isAvailable) return;
    _subscribe(id);
  }

  void _reset() {
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _requestSubscription?.cancel();
    _requestSubscription = null;
    _requestClosed = false;
    _currentStatus = null;
    _lastUpdatedAt = null;
    _historyList = [];
    _hasNewUpdate = false;
    _isLoaded = false;
  }

  void _subscribe(String ownerUid) {
    _retryTimer?.cancel();
    _statusSubscription?.cancel();
    _statusSubscription = _firestoreDS
        .intimacyStatusStream(ownerUid)
        .listen(
          _onSnapshot,
          onError: (Object error) {
            debugPrint('Partner status stream error: $error');
            final denied =
                error is FirebaseException && error.code == 'permission-denied';
            _state = denied
                ? PartnerLinkState.awaitingApproval
                : PartnerLinkState.unreachable;
            _currentStatus = null;
            _isLoaded = true;
            notifyListeners();
            if (denied) _watchRequest(ownerUid);
            _retryTimer?.cancel();
            _retryTimer = Timer(retryInterval, () => _subscribe(ownerUid));
          },
          onDone: () {
            _isLoaded = true;
            notifyListeners();
          },
        );
  }

  /// Onay beklerken partnerin kendi isteğini dinler.
  ///
  /// Önceden onay yalnızca yeniden denemeyle fark ediliyordu: sahip
  /// onayladıktan sonra partnerin ekranı yarım dakikaya kadar "Onay
  /// bekleniyor" diyordu ve TestFlight'ta bu hata gibi göründü. Sahip
  /// onaylayınca isteği siliyor; silindiği an okuma yeniden deneniyor.
  void _watchRequest(String ownerUid) {
    final token = _requestToken;
    final uid = _myUid;
    if (_requestSubscription != null || _requestClosed) return;
    if (token == null || uid == null) return;
    _requestSubscription = _firestoreDS
        .watchOwnPairingRequest(token, uid)
        .listen(
          (snapshot) {
            if (snapshot.exists) return;
            _requestClosed = true;
            _requestSubscription?.cancel();
            _requestSubscription = null;
            _subscribe(ownerUid);
          },
          onError: (Object error) {
            // Dinlenemiyorsa yeniden deneme zaten sürüyor.
            debugPrint('Pairing request watch error: $error');
            _requestSubscription?.cancel();
            _requestSubscription = null;
          },
        );
  }

  void _onSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    _requestSubscription?.cancel();
    _requestSubscription = null;
    _state = PartnerLinkState.connected;
    final data = snapshot.exists ? snapshot.data() : null;
    final desire = data?['sexualDesire'] as String?;
    final needs = List<String>.from(data?['affectionNeeds'] ?? const []);
    final isShared = data?['isShared'] as bool? ?? true;

    if (data != null && isShared && (desire != null || needs.isNotEmpty)) {
      final timestamp = _parseTimestamp(data['timestamp']);
      final newStatus = IntimacyStatus(
        sexualDesire: desire ?? '',
        affectionNeeds: needs,
        timestamp: timestamp,
        isShared: true,
      );
      if (_currentStatus == null ||
          _currentStatus!.sexualDesire != newStatus.sexualDesire ||
          _currentStatus!.affectionNeeds.toString() !=
              newStatus.affectionNeeds.toString()) {
        _hasNewUpdate = true;
      }
      _currentStatus = newStatus;
      _lastUpdatedAt = timestamp;
      if (_historyList.isEmpty ||
          _historyList.first.timestamp != newStatus.timestamp) {
        _historyList.insert(0, newStatus);
        if (_historyList.length > 5) {
          _historyList = _historyList.sublist(0, 5);
        }
      }
    } else {
      // Paylaşılan durum yok: sahip hiç paylaşmadı ya da paylaşımı kapattı
      // (kapatınca doküman siliniyor). İkisi ayırt edilemiyor; ekran da
      // ayırt ediyormuş gibi yapmıyor.
      _currentStatus = null;
      _lastUpdatedAt = null;
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Firestore'daki `timestamp` alanını tipten bağımsız okur (eski kayıtlar
  /// ISO-8601 metin olarak yazılmıştı).
  static DateTime _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  /// Yeni güncelleme animasyonunu sıfırla.
  void clearNewUpdateFlag() {
    _hasNewUpdate = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _requestSubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
