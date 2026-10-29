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

  /// Paylaşılmış son davet bağlantısının kodu.
  static const String _inviteKey = 'pairing_invite_token';

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

  /// Kodu tamamen iptal eder (veri silme akışında). Açık davet
  /// bağlantısı da.
  Future<void> revoke() async {
    final invite = await existingInvite();
    if (invite != null) await closeInvite(invite);
    final token = await existingToken();
    if (token == null) return;
    await _remote.revokePairingToken(token);
    await _store.remove(_tokenKey);
  }

  // ─── Davet bağlantısı ───
  //
  // QR kodundan ayrı, tek kullanımlık ve bir saatlik bir kod (bkz.
  // `firestore.rules`). Aynı anda tek davet: yenisi eskisini siliyor.

  /// Paylaşılmış son davet bağlantısının kodu; yoksa `null`. Kullanılmış
  /// ya da süresi dolmuş olabilir: istekler bölümü onu dinlemeye devam
  /// ediyor ki gelen istek kaçmasın.
  Future<String?> existingInvite() async {
    final token = await _store.getString(_inviteKey);
    return PairingToken.isWellFormed(token) ? token : null;
  }

  /// Yeni bir davet bağlantısı kodu üretip yayımlar; yayımlanamazsa `null`.
  Future<String?> createInvite(String uid) async {
    final previous = await existingInvite();
    final token = PairingToken.generate();
    final ok = await _remote.publishInvite(uid, token, previousToken: previous);
    if (!ok) return null;
    await _store.setString(_inviteKey, token);
    return token;
  }

  /// Davetin işi bitti (onay ya da ret): kod sunucudan siliniyor, bağlantı
  /// bundan sonra hiçbir işe yaramıyor.
  Future<void> closeInvite(String token) async {
    await _remote.revokePairingToken(token);
    if (await existingInvite() == token) await _store.remove(_inviteKey);
  }
}
