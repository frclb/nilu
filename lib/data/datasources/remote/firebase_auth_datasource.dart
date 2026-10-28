import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../core/firebase/firebase_config.dart';

/// Firebase Authentication sarmalayıcısı.
///
/// `FirebaseAuth.instance` **getter** olarak tutulur (field değil): Firebase
/// yapılandırılmamışken sınıfın kurulması bile çökmesin diye. Her metot önce
/// [FirebaseConfig.isAvailable] kontrolü yapar ve yapılandırma yoksa
/// no-op / null döner.
class FirebaseAuthDataSource {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Stream<User?> get authStateChanges => FirebaseConfig.isAvailable
      ? _auth.authStateChanges()
      : const Stream<User?>.empty();

  User? get currentUser =>
      FirebaseConfig.isAvailable ? _auth.currentUser : null;

  /// Apple ya da Google hesabının uid'si; giriş yoksa `null`.
  ///
  /// Eski sürümlerden kalmış anonim bir oturum hesap sayılmıyor.
  String? get accountUid {
    final user = currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  /// Kimlik hesabını **kalıcı olarak** siler.
  ///
  /// "Tüm verilerimi sil" yalnızca Firestore verisini siliyordu; kimlik
  /// Firebase'de kalıyordu.
  ///
  /// Silinemezse (ör. bağlantı yok) `false` döner ki akış sessizce
  /// başarılı görünmesin.
  Future<bool> deleteAccount() async {
    if (!FirebaseConfig.isAvailable) return true;
    final user = _auth.currentUser;
    if (user == null) return true;
    try {
      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Account delete failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Account delete failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    if (!FirebaseConfig.isAvailable) return;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }
}
