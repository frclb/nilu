import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_config.dart';

/// Cloud Firestore sarmalayıcısı.
///
/// `FirebaseFirestore.instance` **getter** olarak tutulur (field değil):
/// Firebase yapılandırılmamışken sınıfın kurulması bile çökmesin diye.
/// Her metot önce [FirebaseConfig.isAvailable] kontrolü yapar.
class FirestoreDataSource {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  bool get _available => FirebaseConfig.isAvailable;

  // --- Users ---
  Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    if (!_available) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error creating user profile: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (!_available) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      return null;
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(String uid) {
    if (!_available) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // --- Logs & Cycles ---
  Future<void> saveDailyLog(
    String uid,
    String dateStr,
    Map<String, dynamic> logData,
  ) async {
    if (!_available) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('logs')
          .doc(dateStr)
          .set(logData, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving daily log: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getLogs(String uid) async {
    if (!_available) return [];
    try {
      final qs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('logs')
          .get();
      return qs.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error getting logs: $e");
      return [];
    }
  }

  // --- Intimacy & Partner ---
  Future<void> updateIntimacyStatus(
    String uid,
    Map<String, dynamic> data,
  ) async {
    if (!_available) return;
    try {
      await _firestore
          .collection('intimacy')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating intimacy status: $e");
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> intimacyStatusStream(
    String partnerUid,
  ) {
    if (!_available) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore.collection('intimacy').doc(partnerUid).snapshots();
  }

  // ── Eşleştirme ──
  //
  // Erişim `users/{uid}.partners` listesine bağlı ve o listeye yalnızca
  // sahibi yazıyor. Önceki modelde her iki taraf da karşısının dokümanına
  // yazıyordu; bu yüzden ayrılan taraf kendini geri ekleyebiliyor ve erişim
  // gerçekten iptal edilemiyordu (bkz. firestore.rules).

  /// Kullanıcının eşleştirme kodunu yayımlar.
  ///
  /// Kod QR'da paylaşılan şey; onu bilen sahibin UID'sini çözebilir. Eski kod
  /// varsa siliniyor — kodu yenilemek daha önce paylaşılmış bütün QR'ları
  /// geçersiz kılmalı.
  Future<void> publishPairingToken(
    String uid,
    String token, {
    String? previousToken,
  }) async {
    if (!_available) return;
    try {
      if (previousToken != null && previousToken != token) {
        await _firestore
            .collection('pairingTokens')
            .doc(previousToken)
            .delete();
      }
      await _firestore.collection('pairingTokens').doc(token).set({
        'ownerUid': uid,
      });
    } catch (e) {
      debugPrint('Error publishing pairing token: $e');
    }
  }

  /// Kodu iptal eder. Bundan sonra o QR hiçbir işe yaramaz.
  Future<void> revokePairingToken(String token) async {
    if (!_available) return;
    try {
      await _firestore.collection('pairingTokens').doc(token).delete();
    } catch (e) {
      debugPrint('Error revoking pairing token: $e');
    }
  }

  /// Kodun sahibinin UID'sini çözer. Kod geçersizse `null`.
  Future<String?> resolvePairingToken(String token) async {
    if (!_available) return null;
    try {
      final doc = await _firestore.collection('pairingTokens').doc(token).get();
      if (!doc.exists) return null;
      return doc.data()?['ownerUid'] as String?;
    } catch (e) {
      debugPrint('Error resolving pairing token: $e');
      return null;
    }
  }

  /// Kodu okuyan taraf eşleştirme isteği bırakır.
  ///
  /// İstek tek başına erişim vermiyor; sahip onaylayana kadar hiçbir şey
  /// okunamaz.
  Future<void> requestPairing(String token, String requesterUid) async {
    if (!_available) return;
    try {
      await _firestore
          .collection('pairingTokens')
          .doc(token)
          .collection('requests')
          .doc(requesterUid)
          .set({'requestedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error requesting pairing: $e');
    }
  }

  /// Sahibin kendi eşleştirme isteklerini dinlemesi.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPairingRequests(
    String token,
  ) {
    if (!_available) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore
        .collection('pairingTokens')
        .doc(token)
        .collection('requests')
        .snapshots();
  }

  /// İşlenen isteği siler.
  ///
  /// Onaylandıktan ya da reddedildikten sonra istek listede kalmamalı; aksi
  /// hâlde sahip aynı isteği her açılışta yeniden görür.
  Future<void> clearPairingRequest(String token, String requesterUid) async {
    if (!_available) return;
    try {
      await _firestore
          .collection('pairingTokens')
          .doc(token)
          .collection('requests')
          .doc(requesterUid)
          .delete();
    } catch (e) {
      debugPrint('Error clearing pairing request: $e');
    }
  }

  /// Sahip erişimi verir: partneri **kendi** listesine ekler.
  Future<void> approvePartner(String uid, String partnerUid) async {
    if (!_available) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'partners': FieldValue.arrayUnion([partnerUid]),
        'hasPartner': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error approving partner: $e');
    }
  }

  /// Sahip erişimi geri alır.
  ///
  /// Karşı taraf kendini geri ekleyemez: liste sahibin dokümanında ve
  /// kurallar yalnızca sahibin yazmasına izin veriyor. Asıl düzeltme bu.
  Future<void> removePartner(String uid, String partnerUid) async {
    if (!_available) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'partners': FieldValue.arrayRemove([partnerUid]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error removing partner: $e');
    }
  }

  /// Kullanıcının uzak verisini kalıcı olarak siler.
  ///
  /// "Tüm verilerimi sil" akışı yalnızca cihazdaki veriyi siliyordu; Firestore'daki
  /// `users/{uid}`, günlük logları ve `intimacy/{uid}` dokümanı yerinde
  /// kalıyordu. İki sonucu vardı: bağlı partner, hesap silindikten sonra da
  /// yakınlık verisini okumaya devam ediyordu; ve hem App Store hem Play
  /// Store, hesap silmenin sunucudaki veriyi de silmesini şart koşuyor.
  ///
  /// Partner erişimi önce geri alınır: doküman silinse bile karşı tarafta
  /// asılı kalan bir izin bırakılmaz. Eşleştirme kodu da iptal edilir, aksi
  /// hâlde hesap silindikten sonra paylaşılmış QR ortada kalırdı.
  Future<void> deleteUserData(
    String uid, {
    String? partnerId,
    String? pairingToken,
  }) async {
    if (!_available) return;
    try {
      if (partnerId != null && partnerId.isNotEmpty) {
        await removePartner(uid, partnerId);
      }
      if (pairingToken != null && pairingToken.isNotEmpty) {
        await revokePairingToken(pairingToken);
      }

      // Alt koleksiyon dokümanı silmekle gitmiyor; logları tek tek sil.
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
    } catch (e) {
      debugPrint("Error deleting user data: $e");
    }
  }
}
