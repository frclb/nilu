import '../../domain/services/pairing_token.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../local/secure_store.dart';

/// Kullanıcının eşleştirme kodunu tutar ve yeniler.
///
/// Kod, QR'da paylaşılan şey. Önceden orada UID vardı ve UID hiç değişmediği
/// için paylaşılan kod kalıcı olarak geçerli kalıyordu — ayrılmak erişimi
/// koparmıyordu. Kod artık döndürülebilir: yenilendiğinde daha önce
/// paylaşılmış bütün QR'lar geçersiz oluyor.
class PairingRepository {
  static const String _tokenKey = 'pairing_token';

  final SecureStore _store;
  final FirestoreDataSource _remote;

  PairingRepository({
    SecureStore store = const SecureStore(),
    FirestoreDataSource? remote,
  }) : _store = store,
       _remote = remote ?? FirestoreDataSource();

  /// Mevcut kodu döndürür; yoksa üretip saklar.
  Future<String> currentToken(String uid) async {
    final existing = await _store.getString(_tokenKey);
    if (existing != null && PairingToken.isWellFormed(existing)) {
      return existing;
    }
    return rotate(uid);
  }

  /// Yeni bir kod üretir, saklar ve yayımlar.
  ///
  /// Eski kod sunucudan siliniyor: yenilemenin anlamı önceki QR'ların
  /// çalışmayı bırakması.
  Future<String> rotate(String uid) async {
    final previous = await _store.getString(_tokenKey);
    final token = PairingToken.generate();

    await _store.setString(_tokenKey, token);
    await _remote.publishPairingToken(uid, token, previousToken: previous);

    return token;
  }

  /// Kodu tamamen iptal eder (hesap silme akışında).
  Future<void> revoke() async {
    final token = await _store.getString(_tokenKey);
    if (token == null) return;
    await _remote.revokePairingToken(token);
    await _store.remove(_tokenKey);
  }
}
