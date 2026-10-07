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

  /// Anonim giriş yapar. Firebase yoksa null döner.
  Future<UserCredential?> signInAnonymously() async {
    if (!FirebaseConfig.isAvailable) return null;
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Anonymous sign in error: $e");
      return null;
    }
  }

  /// Kimlik hesabını **kalıcı olarak** siler.
  ///
  /// App Store 5.1.1(v): hesap oluşturmayı destekleyen uygulama, hesabın
  /// silinmesini de sunmak zorunda. "Hesabımı Sil" yalnızca Firestore
  /// verisini siliyor ve oturumu kapatıyordu; Apple hesabıyla girmiş bir
  /// kullanıcının kimliği Firebase'de duruyordu — yeniden giriş yaptığında
  /// aynı uid ile geri geliyordu, yani hesap silinmemişti.
  ///
  /// Kimlik bilgisi eskimişse Firebase `requires-recent-login` döndürür; o
  /// durumda çağıran tarafın kullanıcıyı yeniden doğrulaması gerekir.
  /// Silinemezse `false` döner ki akış sessizce başarılı görünmesin.
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
