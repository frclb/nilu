import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../models/intimacy_status.dart';
import '../services/partner_suggestion_engine.dart';

/// Partner tarafında duygusal durum verisini tüketen ViewModel.
/// Real-time güncelleme (Firestore Stream), geçmiş takibi ve bağlantı yönetimi sağlar.
class PartnerViewModel extends ChangeNotifier {
  final FirestoreDataSource _firestoreDS = FirestoreDataSource();

  // ─── State ───
  IntimacyStatus? _currentStatus;
  DateTime? _lastUpdatedAt;
  bool _isConnected = false;
  bool _isSharingEnabled = true;
  bool _notificationsMuted = false;
  List<IntimacyStatus> _historyList = [];
  bool _isLoaded = false;
  bool _hasNewUpdate = false;

  // ─── Stream ───
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _statusSubscription;

  // ─── Getters ───
  IntimacyStatus? get currentStatus => _currentStatus;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  bool get isConnected => _isConnected;
  bool get isSharingEnabled => _isSharingEnabled;
  bool get notificationsMuted => _notificationsMuted;
  List<IntimacyStatus> get historyList => List.unmodifiable(_historyList);
  bool get isLoaded => _isLoaded;
  bool get hasNewUpdate => _hasNewUpdate;
  bool get hasData => _currentStatus != null;

  /// Suggestion engine'den mevcut öneriler.
  List<PartnerSuggestion> get suggestions =>
      PartnerSuggestionEngine.generate(_currentStatus);

  /// Son güncellemenin üzerinden geçen süre. Metne çevirme işi View'a aittir
  /// (bkz. `presentation/.../relative_time.dart`) — domain katmanı dile bağlı
  /// metin üretmez.
  Duration? get timeSinceLastUpdate => _lastUpdatedAt == null
      ? null
      : DateTime.now().difference(_lastUpdatedAt!);

  /// >24 saat eski veri kontrolü.
  bool get isDataStale {
    if (_lastUpdatedAt == null) return false;
    return DateTime.now().difference(_lastUpdatedAt!).inHours >= 24;
  }

  /// Partner ID verilerek ViewModel başlatılır
  void init(String? partnerId) {
    if (partnerId != null && partnerId.isNotEmpty) {
      _isConnected = true;
      _startListeningToPartner(partnerId);
    } else {
      _isConnected = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Firestore'dan partnerin intimacy durumunu dinler
  void _startListeningToPartner(String partnerId) {
    _statusSubscription?.cancel();
    _statusSubscription = _firestoreDS
        .intimacyStatusStream(partnerId)
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              final data = snapshot.data()!;

              final desire = data['sexualDesire'] as String?;
              final needs = List<String>.from(data['affectionNeeds'] ?? []);
              final isShared = data['isShared'] as bool? ?? true;

              final timestamp = _parseTimestamp(data['timestamp']);

              if (isShared && (desire != null || needs.isNotEmpty)) {
                final newStatus = IntimacyStatus(
                  sexualDesire: desire ?? '',
                  affectionNeeds: needs,
                  timestamp: timestamp,
                  isShared: true,
                );

                // Değişiklik varsa animasyon tetikle
                if (_currentStatus == null ||
                    _currentStatus!.sexualDesire != newStatus.sexualDesire ||
                    _currentStatus!.affectionNeeds.toString() !=
                        newStatus.affectionNeeds.toString()) {
                  _hasNewUpdate = true;
                }

                _currentStatus = newStatus;
                _lastUpdatedAt = timestamp;
                _isSharingEnabled = true;

                // Geçmişe ekle (gerçekte Firestore'da history collection da tutulabilir)
                if (_historyList.isEmpty ||
                    _historyList.first.timestamp != newStatus.timestamp) {
                  _historyList.insert(0, newStatus);
                  if (_historyList.length > 5) {
                    _historyList = _historyList.sublist(0, 5);
                  }
                }
              } else {
                // Paylaşım kapatılmış veya veri yok
                _isSharingEnabled = false;
                _currentStatus = null;
              }
            } else {
              _isSharingEnabled = false;
              _currentStatus = null;
            }

            _isLoaded = true;
            notifyListeners();
          },
          onError: (error) {
            debugPrint("Error listening to partner intimacy status: $error");
            _isLoaded = true;
            notifyListeners();
          },
          // Akış hiç veri vermeden kapanabiliyor: Firebase yapılandırılmamışsa
          // `intimacyStatusStream` boş bir akış döndürüyor — ne `onData` ne
          // `onError` çalışıyor. Bu ele alınmayınca `_isLoaded` hiç `true`
          // olmuyor ve partner panosu sonsuza kadar dönen bir çarkta
          // kalıyordu. Uygulama Firebase'siz de çalışacak biçimde
          // tasarlandığı için bu, yapılandırma eklenene kadar partner
          // modunun tek ekranının hiç açılmaması demekti.
          onDone: () {
            _isLoaded = true;
            notifyListeners();
          },
        );
  }

  /// Firestore'daki `timestamp` alanını tipten bağımsız okur.
  ///
  /// Yeni kayıtlar [Timestamp] olarak yazılır; ancak eski kayıtlar ISO-8601
  /// string olarak yazılmıştı. Sabit bir `as Timestamp` cast'i eski verilerde
  /// TypeError fırlatıp stream'i `onError`'a düşürüyordu.
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

  /// Bildirimleri kapat/aç.
  void toggleMuteNotifications() {
    _notificationsMuted = !_notificationsMuted;
    notifyListeners();
  }

  /// Partner bağlantısını kes.
  void disconnect() {
    _isConnected = false;
    _currentStatus = null;
    _lastUpdatedAt = null;
    _historyList.clear();
    _statusSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
