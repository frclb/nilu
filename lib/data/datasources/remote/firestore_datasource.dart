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

  Future<void> savePartnerConnection(String uid, String partnerId) async {
    if (!_available) return;
    try {
      // Connect me to partner
      await _firestore.collection('users').doc(uid).set({
        'partnerId': partnerId,
        'hasPartner': true,
      }, SetOptions(merge: true));

      // Connect partner to me
      await _firestore.collection('users').doc(partnerId).set({
        'partnerId': uid,
        'hasPartner': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving partner connection: $e");
    }
  }

  Future<void> disconnectPartner(String uid, String partnerId) async {
    if (!_available) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'partnerId': FieldValue.delete(),
        'hasPartner': false,
      });

      await _firestore.collection('users').doc(partnerId).update({
        'partnerId': FieldValue.delete(),
        'hasPartner': false,
      });
    } catch (e) {
      debugPrint("Error disconnecting partner: $e");
    }
  }
}
