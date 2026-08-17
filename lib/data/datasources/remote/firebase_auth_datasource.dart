import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  Future<UserCredential?> signInWithApple() async {
    if (!FirebaseConfig.isAvailable) return null;
    try {
      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oauthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oauthProvider.credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Apple Sign In error: $e");
      return null;
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
