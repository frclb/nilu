import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../domain/services/pairing_token.dart';

/// Cloud Firestore sarmalayıcısı — yalnızca partner eşleşmesi için.
///
/// Uygulamanın sunucuya yazdığı tek kişisel veri, sahibin paylaşmayı
/// **seçtiği** yakınlık durumu (`intimacy/{uid}`) ve eşleşmenin kendisi
/// (`users/{uid}.partners`, `pairingTokens`). Döngü kaydı, belirti, not
/// hiçbir koşulda buraya gelmiyor.
///
/// Yazan metotlar sonucu `bool` döndürüyor. Önceden hatalar yutulup her şey
/// başarılı görünüyordu: Firebase yapılandırılmamışken paylaşım "gönderildi"
/// diyor, QR geçerli görünüyordu.
///
/// `FirebaseFirestore.instance` **getter** olarak tutulur (field değil):
/// Firebase yapılandırılmamışken sınıfın kurulması bile çökmesin diye.
class FirestoreDataSource {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Uzak taraf kullanılabilir mi? Değilse partner ekranları bunu
  /// söylüyor; geçerli görünen bir QR göstermiyor.
  bool get isAvailable => FirebaseConfig.isAvailable;

  Future<bool> _write(String what, Future<void> Function() op) async {
    if (!isAvailable) return false;
    try {
      await op();
      return true;
    } catch (e) {
      debugPrint('Firestore $what failed: $e');
      return false;
    }
  }

  // --- Yakınlık durumu ---

  /// Sahibin paylaştığı durumu yazar.
  Future<bool> updateIntimacyStatus(String uid, Map<String, dynamic> data) =>
      _write(
        'intimacy update',
        () => _firestore
            .collection('intimacy')
            .doc(uid)
            .set(data, SetOptions(merge: true)),
      );

  /// Paylaşılmış durumu geri çeker.
  ///
  /// Paylaşım kapatılınca ya da partnerin erişimi kaldırılınca çağrılıyor.
  /// Önceden doküman yerinde kalıyordu: paylaşımı kapatan kullanıcının son
  /// durumu, erişimi olan herkes için okunur kalıyordu.
  Future<bool> deleteIntimacyStatus(String uid) => _write(
    'intimacy delete',
    () => _firestore.collection('intimacy').doc(uid).delete(),
  );

  Stream<DocumentSnapshot<Map<String, dynamic>>> intimacyStatusStream(
    String ownerUid,
  ) {
    if (!isAvailable) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore.collection('intimacy').doc(ownerUid).snapshots();
  }

  // ── Eşleştirme ──
  //
  // Erişim `users/{uid}.partners` listesine bağlı ve o listeye yalnızca
  // sahibi ekleme yapabiliyor (bkz. firestore.rules). Partner yalnızca
  // **kendini** çıkarabiliyor.

  /// Kullanıcının eşleştirme kodunu yayımlar. Eski kod siliniyor: kodu
  /// yenilemek daha önce paylaşılmış bütün QR'ları geçersiz kılmalı.
  Future<bool> publishPairingToken(
    String uid,
    String token, {
    String? previousToken,
  }) => _write('pairing token publish', () async {
    if (previousToken != null && previousToken != token) {
      await _firestore.collection('pairingTokens').doc(previousToken).delete();
    }
    await _firestore.collection('pairingTokens').doc(token).set({
      'ownerUid': uid,
    });
  });

  /// Tek kullanımlık davet bağlantısının kodunu yayımlar. Saati sunucu
  /// koyuyor; kural bir saat sonra kullanılmasına izin vermiyor. Önceki
  /// davet siliniyor (kullanılıp silinmişse silinemez; önemi yok).
  Future<bool> publishInvite(
    String uid,
    String token, {
    String? previousToken,
  }) => _write('invite publish', () async {
    if (previousToken != null && previousToken != token) {
      try {
        await _firestore
            .collection('pairingTokens')
            .doc(previousToken)
            .delete();
      } catch (e) {
        debugPrint('Previous invite delete skipped: $e');
      }
    }
    await _firestore.collection('pairingTokens').doc(token).set({
      'ownerUid': uid,
      'oneTime': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  /// Kodu iptal eder. Bundan sonra o QR hiçbir işe yaramaz.
  Future<bool> revokePairingToken(String token) => _write(
    'pairing token revoke',
    () => _firestore.collection('pairingTokens').doc(token).delete(),
  );

  /// Kodun sahibinin UID'sini çözer. Kod geçersizse `null`.
  Future<String?> resolvePairingToken(String token) async =>
      (await resolvePairingTokenInfo(token))?.ownerUid;

  /// Kodun sahibi ve — davet bağlantısıysa — kullanılıp kullanılmadığı.
  /// Kod geçersizse `null`.
  ///
  /// Uzak taraf kullanılamıyorsa [PairingUnavailable] fırlatır: "geçersiz
  /// kod" demek yanlış olurdu.
  Future<PairingTokenInfo?> resolvePairingTokenInfo(String token) async {
    if (!isAvailable) throw const PairingUnavailable();
    try {
      final doc = await _firestore.collection('pairingTokens').doc(token).get();
      final data = doc.data();
      final owner = data?['ownerUid'] as String?;
      if (!doc.exists || owner == null) return null;
      return PairingTokenInfo(
        ownerUid: owner,
        oneTime: data?['oneTime'] == true,
        usedBy: data?['usedBy'] as String?,
        createdAt: (data?['createdAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      debugPrint('Error resolving pairing token: $e');
      throw const PairingUnavailable();
    }
  }

  /// Kodu okuyan taraf eşleştirme isteği bırakır. İstek tek başına erişim
  /// vermiyor; sahip onaylayana kadar hiçbir şey okunamaz.
  ///
  /// [claim]: kod bir davet bağlantısı. Bağlantı aynı yazımda bu kişiye
  /// bağlanıyor (`usedBy`); kural ikinci bir kullanıma izin vermiyor.
  Future<bool> requestPairing(
    String token,
    String requesterUid, {
    bool claim = false,
  }) => _write('pairing request', () {
    final kod = _firestore.collection('pairingTokens').doc(token);
    final istek = kod.collection('requests').doc(requesterUid);
    final veri = {'requestedAt': FieldValue.serverTimestamp()};
    if (!claim) return istek.set(veri);
    return (_firestore.batch()
          ..update(kod, {'usedBy': requesterUid})
          ..set(istek, veri))
        .commit();
  });

  /// Partnerin kendi isteğini dinlemesi. Sahip onaylayınca (ya da
  /// reddedince) istek siliniyor: partner onayı bundan anında öğreniyor.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOwnPairingRequest(
    String token,
    String requesterUid,
  ) {
    if (!isAvailable) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore
        .collection('pairingTokens')
        .doc(token)
        .collection('requests')
        .doc(requesterUid)
        .snapshots();
  }

  /// Sahibin kendi eşleştirme isteklerini dinlemesi.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPairingRequests(
    String token,
  ) {
    if (!isAvailable) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore
        .collection('pairingTokens')
        .doc(token)
        .collection('requests')
        .snapshots();
  }

  /// İşlenen isteği siler; aksi hâlde sahip aynı isteği her açılışta
  /// yeniden görür.
  Future<bool> clearPairingRequest(String token, String requesterUid) => _write(
    'pairing request clear',
    () => _firestore
        .collection('pairingTokens')
        .doc(token)
        .collection('requests')
        .doc(requesterUid)
        .delete(),
  );

  /// Sahip erişimi verir. **Tek partner**: liste yeni partnerle değişiyor.
  ///
  /// Önceden `arrayUnion` ile ekleniyordu; ikinci bir partner onaylanınca
  /// ilki listede kalıyor ve sahip farkında olmadan iki kişiyle paylaşıyordu.
  Future<bool> approvePartner(String uid, String partnerUid) => _write(
    'partner approve',
    () => _firestore.collection('users').doc(uid).set({
      'partners': [partnerUid],
    }, SetOptions(merge: true)),
  );

  /// Sahip erişimi geri alır. Karşı taraf kendini geri ekleyemez.
  Future<bool> removePartner(String uid, String partnerUid) => _write(
    'partner remove',
    () => _firestore.collection('users').doc(uid).set({
      'partners': FieldValue.arrayRemove([partnerUid]),
    }, SetOptions(merge: true)),
  );

  /// Partner kendi erişimini bırakır: sahibin listesinden **yalnızca
  /// kendini** çıkarır (kurallar başka bir değişikliğe izin vermiyor).
  ///
  /// Önceden partner tarafındaki "Bağlantıyı Kes" yalnızca bu cihazdaki
  /// kaydı siliyordu; sahibin listesinde kalan partner yeniden okuyabiliyordu.
  Future<bool> leavePartner({
    required String ownerUid,
    required String myUid,
  }) => _write(
    'partner leave',
    () => _firestore.collection('users').doc(ownerUid).update({
      'partners': FieldValue.arrayRemove([myUid]),
    }),
  );

  /// Kullanıcının uzak verisini kalıcı olarak siler ("Tüm verilerimi sil").
  ///
  /// Partner erişimi önce geri alınır; eşleştirme kodu da iptal edilir.
  /// `logs` alt koleksiyonu eski sürümlerden kalmış olabilir: artık
  /// yazılmıyor ama silinmesi gerekiyor.
  Future<bool> deleteUserData(
    String uid, {
    String? partnerId,
    String? pairingToken,
  }) => _write('user data delete', () async {
    if (partnerId != null && partnerId.isNotEmpty) {
      await removePartner(uid, partnerId);
    }
    if (pairingToken != null && pairingToken.isNotEmpty) {
      await revokePairingToken(pairingToken);
    }
    final logs = await _firestore
        .collection('users')
        .doc(uid)
        .collection('logs')
        .get();
    for (final doc in logs.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('intimacy').doc(uid).delete();
    await _firestore.collection('users').doc(uid).delete();
  });
}

/// Çözülmüş eşleştirme kodu.
@immutable
class PairingTokenInfo {
  const PairingTokenInfo({
    required this.ownerUid,
    this.oneTime = false,
    this.usedBy,
    this.createdAt,
  });

  final String ownerUid;

  /// Tek kullanımlık davet bağlantısı (QR kodu değil).
  final bool oneTime;

  /// Bağlantıyı kullanan kişi; kullanılmadıysa `null`.
  final String? usedBy;
  final DateTime? createdAt;

  /// Davet bağlantısı bir kez kullanıldı.
  bool get used => oneTime && usedBy != null;

  /// Davet bağlantısının süresi doldu. Sunucunun saati esas; buradaki
  /// kontrol yalnızca doğru mesajı göstermek için.
  bool expired(DateTime now) =>
      oneTime &&
      (createdAt == null ||
          !now.isBefore(createdAt!.add(PairingToken.inviteLifetime)));
}

/// Eşleştirme sunucusuna ulaşılamıyor (Firebase yapılandırılmamış ya da
/// bağlantı yok). Kodun geçersiz olduğu anlamına gelmiyor.
class PairingUnavailable implements Exception {
  const PairingUnavailable();
}
