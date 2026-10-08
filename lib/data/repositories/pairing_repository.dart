import '../../domain/services/pairing_token.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../local/secure_store.dart';

/// Kullanıcının eşleştirme kodunu tutar ve yeniler.
///
/// Kod, QR'da paylaşılan şey. Önceden orada UID vardı ve UID hiç değişmediği
/// için paylaşılan kod kalıcı olarak geçerli kalıyordu — ayrılmak erişimi
/// koparmıyordu. Kod artık döndürülebilir: yenilendiğinde daha önce
/// paylaşılmış bütün QR'lar geçersiz oluyor.
///
/// Kod yalnızca sunucuda yayımlandıktan **sonra** saklanıyor: yayımlanmamış
/// bir kodun QR'ı geçerli görünür ama okutan kişiye "geçersiz kod" derdi.
class PairingRepository {
  static const String _tokenKey = 'pairing_token';

  final SecureStore _store;
  final FirestoreDataSource _remote;

  PairingRepository({
    SecureStore store = const SecureStore(),
    FirestoreDataSource? remote,
  }) : _store = store,
       _remote = remote ?? FirestoreDataSource();

  /// Daha önce yayımlanmış kod; yoksa `null`. Hiçbir şey üretmez.
  ///
  /// Partner sekmesini açmak tek başına kod üretip sunucuya yazmamalı.
  Future<String?> existingToken() async {
    final existing = await _store.getString(_tokenKey);
    return PairingToken.isWellFormed(existing) ? existing : null;
  }

  /// Mevcut kod; yoksa üretip yayımlar. Yayımlanamazsa `null`.
  Future<String?> currentToken(String uid) async =>
      await existingToken() ?? rotate(uid);

  /// Yeni bir kod üretir ve yayımlar; eskisi sunucudan siliniyor.
  /// Yayımlanamazsa `null` — eski kod yerinde kalıyor.
  Future<String?> rotate(String uid) async {
    final previous = await existingToken();
    final token = PairingToken.generate();
    final ok = await _remote.publishPairingToken(
      uid,
      token,
      previousToken: previous,
    );
    if (!ok) return null;
    await _store.setString(_tokenKey, token);
    return token;
  }

  /// Kodu tamamen iptal eder (veri silme akışında).
  Future<void> revoke() async {
    final token = await existingToken();
    if (token == null) return;
    await _remote.revokePairingToken(token);
    await _store.remove(_tokenKey);
  }
}
