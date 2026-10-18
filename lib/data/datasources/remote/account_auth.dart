import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_config.dart';

/// Giriş sağlayıcısı.
enum AccountProvider { apple, google }

/// Apple ya da Google ile giriş yapmış kullanıcı. Anonim (yalnızca partner
/// eşleşmesi için açılmış) kimlik bir hesap sayılmıyor.
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

  /// Anonim kimlik hesaba bağlanamadı, var olan bir hesaba geçildi: kimlik
  /// değişti. Bu cihazdaki partner bağlantısı eski kimliğe bağlıydı.
  final bool switchedIdentity;

  const SignInResult(this.status, {this.user, this.switchedIdentity = false});
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
/// Apple ve Google, Firebase'in kendi sağlayıcı akışıyla açılıyor
/// (`signInWithProvider`): ayrı bir giriş paketi yok. Apple'da iOS'un yerel
/// "Apple ile giriş" sayfası, Google'da sistemin güvenli web sayfası.
///
/// Partner eşleşmesi için zaten anonim bir kimlik varsa hesap **ona
/// bağlanıyor** (`linkWithProvider`): kimlik değişmiyor, eşleşme kopmuyor.
/// Hesap başka bir cihazda daha önce kullanılmışsa bağlanamaz; o zaman o
/// hesaba geçiliyor.
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

  @override
  Future<SignInResult> signIn(AccountProvider provider) async {
    if (!isAvailable) return const SignInResult(SignInStatus.unavailable);
    final saglayici = _provider(provider);
    final simdiki = _auth.currentUser;
    try {
      if (simdiki != null && simdiki.isAnonymous) {
        try {
          final c = await simdiki.linkWithProvider(saglayici);
          return SignInResult(SignInStatus.signedIn, user: fromUser(c.user));
        } on FirebaseAuthException catch (e) {
          const zatenVar = {
            'credential-already-in-use',
            'email-already-in-use',
            'account-exists-with-different-credential',
          };
          if (!zatenVar.contains(e.code)) rethrow;
          final kimlik = e.credential;
          final c = kimlik != null
              ? await _auth.signInWithCredential(kimlik)
              : await _auth.signInWithProvider(saglayici);
          return SignInResult(
            SignInStatus.signedIn,
            user: fromUser(c.user),
            switchedIdentity: true,
          );
        }
      }
      final c = await _auth.signInWithProvider(saglayici);
      return SignInResult(SignInStatus.signedIn, user: fromUser(c.user));
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
  }

  @override
  Future<bool> reauthenticateForDeletion() async {
    if (!isAvailable) return false;
    final user = _auth.currentUser;
    final hesap = fromUser(user);
    if (user == null || hesap == null) return true;
    try {
      final c = await user.reauthenticateWithProvider(
        _provider(hesap.provider),
      );
      if (hesap.provider == AccountProvider.apple) {
        // Apple, "Apple ile giriş" kullanan uygulamaların hesap silinirken
        // jetonu iptal etmesini istiyor (App Store kuralı 5.1.1(v)).
        final kod = c.additionalUserInfo?.authorizationCode;
        if (kod != null) await _auth.revokeTokenWithAuthorizationCode(kod);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Reauthentication failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Reauthentication failed: $e');
      return false;
    }
  }
}
