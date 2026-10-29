import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/firebase/firebase_config.dart';
import '../../../core/platform/app_platform.dart';

/// Giriş sağlayıcısı.
enum AccountProvider { apple, google }

/// Apple ya da Google ile giriş yapmış kullanıcı. Eski sürümlerden kalmış
/// anonim bir kimlik hesap sayılmıyor.
@immutable
class AccountUser {
  final String uid;
  final AccountProvider provider;
  final String? email;
  final String? displayName;

  const AccountUser({
    required this.uid,
    required this.provider,
    this.email,
    this.displayName,
  });
}

enum SignInStatus { signedIn, cancelled, failed, unavailable }

class SignInResult {
  final SignInStatus status;
  final AccountUser? user;

  const SignInResult(this.status, {this.user});
}

/// Hesap girişi. Testte sahtesiyle değiştiriliyor.
abstract class AccountAuth {
  bool get isAvailable;
  AccountUser? get currentAccount;
  Stream<AccountUser?> get accountChanges;

  Future<SignInResult> signIn(AccountProvider provider);
  Future<void> signOut();

  /// Hesap silmeden önce: kimliği yeniden doğrular ve Apple ile girildiyse
  /// Apple jetonunu iptal eder (Apple'ın şartı). Kullanıcı vazgeçerse ya
  /// da doğrulama başarısızsa `false`.
  Future<bool> reauthenticateForDeletion();
}

/// Firebase Authentication ile giriş.
///
/// Apple, Firebase'in kendi sağlayıcı akışıyla açılıyor
/// (`signInWithProvider`): iOS'un yerel "Apple ile giriş" sayfası.
///
/// Google iOS'ta Google'ın kendi giriş kitaplığıyla (`google_sign_in`):
/// sistem sayfası doğrudan accounts.google.com'u açıyor, çıkan kimlik
/// jetonu Firebase'e veriliyor. Önceden o da `signInWithProvider` idi ve
/// araya Firebase'in yönlendirme sayfası giriyordu: kullanıcı önce
/// `nilu-3b870.firebaseapp.com` adresini görüyordu (TestFlight bulgusu).
/// İstemci kimliği `GoogleService-Info.plist`'ten (CLIENT_ID), dönüş adresi
/// Info.plist'teki REVERSED_CLIENT_ID şemasından. Android'de şimdilik
/// Firebase'in akışı: yerel kitaplık orada google-services.json istiyor.
///
/// Partner eşleşmesi de hesap istiyor; anonim kimlik yok. Eskiden eşleşme
/// için açılan anonim kimliğe hesap bağlanıyordu (`linkWithProvider`).
class FirebaseAccountAuth implements AccountAuth {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  bool get isAvailable => FirebaseConfig.isAvailable;

  static AuthProvider _provider(AccountProvider p) => switch (p) {
    AccountProvider.apple =>
      AppleAuthProvider()
        ..addScope('email')
        ..addScope('name'),
    AccountProvider.google => GoogleAuthProvider()..addScope('email'),
  };

  static AccountUser? fromUser(User? u) {
    if (u == null || u.isAnonymous) return null;
    for (final info in u.providerData) {
      final provider = switch (info.providerId) {
        'apple.com' => AccountProvider.apple,
        'google.com' => AccountProvider.google,
        _ => null,
      };
      if (provider == null) continue;
      return AccountUser(
        uid: u.uid,
        provider: provider,
        email: u.email ?? info.email,
        displayName: u.displayName ?? info.displayName,
      );
    }
    return null;
  }

  @override
  AccountUser? get currentAccount =>
      isAvailable ? fromUser(_auth.currentUser) : null;

  @override
  Stream<AccountUser?> get accountChanges => isAvailable
      ? _auth.userChanges().map(fromUser)
      : const Stream<AccountUser?>.empty();

  static bool _cancelled(FirebaseAuthException e) =>
      e.code.contains('cancel') || e.code == 'user-cancelled';

  /// Google'ın yerel kitaplığı kullanılıyor mu (bkz. sınıf belgesi)?
  static bool get _nativeGoogle => !kIsWeb && !AppPlatform.isAndroid;

  /// `GoogleSignIn` her şeyden önce bir kez başlatılmalı.
  static Future<void>? _googleReady;

  /// Google hesabı seçtirir ve Firebase'in kabul ettiği kimlik bilgisini
  /// döndürür. Vazgeçilirse [GoogleSignInException] (`canceled`).
  static Future<AuthCredential> _googleCredential() async {
    final google = GoogleSignIn.instance;
    await (_googleReady ??= google.initialize());
    final hesap = await google.authenticate(scopeHint: const ['email']);
    final idToken = hesap.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'Google returned no ID token',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  @override
  Future<SignInResult> signIn(AccountProvider provider) async {
    if (!isAvailable) return const SignInResult(SignInStatus.unavailable);
    try {
      final UserCredential c;
      if (provider == AccountProvider.google && _nativeGoogle) {
        c = await _auth.signInWithCredential(await _googleCredential());
      } else {
        c = await _auth.signInWithProvider(_provider(provider));
      }
      return SignInResult(SignInStatus.signedIn, user: fromUser(c.user));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const SignInResult(SignInStatus.cancelled);
      }
      debugPrint('Google sign-in failed: ${e.code} ${e.description}');
      return const SignInResult(SignInStatus.failed);
    } on FirebaseAuthException catch (e) {
      if (_cancelled(e)) return const SignInResult(SignInStatus.cancelled);
      debugPrint('Account sign-in failed: ${e.code}');
      return const SignInResult(SignInStatus.failed);
    } catch (e) {
      debugPrint('Account sign-in failed: $e');
      return const SignInResult(SignInStatus.failed);
    }
  }

  @override
  Future<void> signOut() async {
    if (!isAvailable) return;
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Account sign-out failed: $e');
    }
    // Google kitaplığının kendi oturumu da kapansın: bir sonraki girişte
    // hesap yeniden seçilebilsin.
    if (_googleReady != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign-out failed: $e');
      }
    }
  }

  @override
  Future<bool> reauthenticateForDeletion() async {
    if (!isAvailable) return false;
    final user = _auth.currentUser;
    final hesap = fromUser(user);
    if (user == null || hesap == null) return true;
    try {
      final c = hesap.provider == AccountProvider.google && _nativeGoogle
          ? await user.reauthenticateWithCredential(await _googleCredential())
          : await user.reauthenticateWithProvider(_provider(hesap.provider));
      if (hesap.provider == AccountProvider.apple) {
        // Apple, "Apple ile giriş" kullanan uygulamaların hesap silinirken
        // jetonu iptal etmesini istiyor (App Store kuralı 5.1.1(v)).
        final kod = c.additionalUserInfo?.authorizationCode;
        if (kod != null) await _auth.revokeTokenWithAuthorizationCode(kod);
      }
      return true;
    } on GoogleSignInException catch (e) {
      debugPrint('Google reauthentication failed: ${e.code}');
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Reauthentication failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Reauthentication failed: $e');
      return false;
    }
  }
}
