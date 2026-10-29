import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/app_info.dart';
import '../../../core/firebase/firebase_config.dart';
import '../../../core/platform/app_platform.dart';

/// Giriş sağlayıcısı.
enum AccountProvider { apple, google, email }

/// Apple, Google ya da e-postayla giriş yapmış kullanıcı. Eski sürümlerden
/// kalmış anonim bir kimlik hesap sayılmıyor.
@immutable
class AccountUser {
  final String uid;
  final AccountProvider provider;
  final String? email;
  final String? displayName;

  /// E-posta hesabında adres doğrulandı mı? Apple ve Google hesapları
  /// sağlayıcıda doğrulanmış sayılıyor.
  final bool emailVerified;

  const AccountUser({
    required this.uid,
    required this.provider,
    this.email,
    this.displayName,
    this.emailVerified = true,
  });

  /// E-postayla açılmış ama adresi henüz doğrulanmamış hesap: uygulama
  /// doğrulanana kadar kullanılmıyor (bkz. `resolveRedirect`).
  bool get needsEmailVerification =>
      provider == AccountProvider.email && !emailVerified;
}

enum SignInStatus { signedIn, cancelled, failed, unavailable }

/// E-postayla girişte kullanıcıya söylenebilecek sebep. Bilinmeyen bir
/// hata `null`: genel "giriş yapılamadı".
enum EmailAuthError {
  /// E-posta ya da şifre yanlış. Firebase'in e-posta numaralandırma
  /// koruması açık: "böyle bir hesap yok" ile "şifre yanlış" ayrılmıyor.
  invalidCredential,
  emailInUse,
  weakPassword,
  invalidEmail,
  tooManyRequests,
  network,
}

/// Şifre yenileme bağlantısıyla yeni şifre belirlemenin sonucu.
enum PasswordResetResult { done, invalidLink, weakPassword, failed }

class SignInResult {
  final SignInStatus status;
  final AccountUser? user;
  final EmailAuthError? emailError;

  const SignInResult(this.status, {this.user, this.emailError});
}

/// Hesap girişi. Testte sahtesiyle değiştiriliyor.
abstract class AccountAuth {
  bool get isAvailable;
  AccountUser? get currentAccount;
  Stream<AccountUser?> get accountChanges;

  /// Apple ya da Google ile giriş.
  Future<SignInResult> signIn(AccountProvider provider);

  /// E-posta ve şifreyle giriş; [create] ise yeni hesap. Yeni hesaba
  /// doğrulama e-postası gidiyor, ama giriş onu beklemiyor.
  ///
  /// [languageCode] Firebase'in göndereceği e-postanın dili.
  Future<SignInResult> signInWithEmail(
    String email,
    String password, {
    required bool create,
    String? languageCode,
  });

  /// Şifre sıfırlama bağlantısı gönderir. Adrese kayıtlı hesap olmasa da
  /// `true`: hangi adreslerin kayıtlı olduğu böylece öğrenilemiyor.
  Future<bool> sendPasswordReset(String email, {String? languageCode});

  /// Doğrulama bağlantısını yeniden gönderir.
  Future<bool> sendEmailVerification({String? languageCode});

  /// Hesabı sunucudan yeniden okur; e-posta doğrulandıysa kimlik jetonunu
  /// da yeniler (sunucu kuralları doğrulamaya bakıyor). Güncel hesabı
  /// döndürür.
  Future<AccountUser?> reloadAccount();

  /// E-postadaki doğrulama bağlantısının kodunu uygular.
  Future<bool> applyEmailVerification(String code);

  /// Şifre yenileme kodu geçerliyse hangi adrese ait olduğu; değilse `null`.
  Future<String?> checkPasswordResetCode(String code);

  /// Şifre yenileme kodu ile yeni şifreyi belirler.
  Future<PasswordResetResult> confirmPasswordReset(
    String code,
    String newPassword,
  );

  Future<void> signOut();

  /// Hesap silmeden önce: kimliği yeniden doğrular ve Apple ile girildiyse
  /// Apple jetonunu iptal eder (Apple'ın şartı). E-posta hesabında
  /// [password] gerekiyor. Kullanıcı vazgeçerse ya da doğrulama başarısızsa
  /// `false`.
  Future<bool> reauthenticateForDeletion({String? password});
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
/// E-posta ve şifre Firebase'in kendi sağlayıcısı (`password`). Doğrulama
/// zorunlu: adres doğrulanmadan uygulama kullanılmıyor, sunucu kuralları da
/// doğrulanmamış e-posta hesabını reddediyor. Doğrulama ve şifre yenileme
/// e-postalarını Firebase gönderiyor. Bağlantı Firebase'in sayfasını açıyor
/// (action URL bu projede değiştirilemiyor), iş orada bitiyor ve "Devam"
/// Nilu'ya geri getiriyor ([_donus]). Action URL bir gün Nilu'nun sayfasına
/// (`AppInfo.authLinkBase`) çevrilebilirse uygulama ve site bağlantının
/// kendisini de karşılamaya hazır (`AuthActionLink`, `ResetPasswordScreen`).
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
    AccountProvider.email => throw ArgumentError.value(
      p,
      'provider',
      'e-posta signInWithEmail ile',
    ),
  };

  static AccountUser? fromUser(User? u) {
    if (u == null || u.isAnonymous) return null;
    for (final info in u.providerData) {
      final provider = switch (info.providerId) {
        'apple.com' => AccountProvider.apple,
        'google.com' => AccountProvider.google,
        'password' => AccountProvider.email,
        _ => null,
      };
      if (provider == null) continue;
      return AccountUser(
        uid: u.uid,
        provider: provider,
        email: u.email ?? info.email,
        displayName: u.displayName ?? info.displayName,
        emailVerified: provider != AccountProvider.email || u.emailVerified,
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

  static EmailAuthError? _emailError(FirebaseAuthException e) =>
      switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'INVALID_LOGIN_CREDENTIALS' => EmailAuthError.invalidCredential,
        'email-already-in-use' => EmailAuthError.emailInUse,
        'weak-password' ||
        'password-does-not-meet-requirements' => EmailAuthError.weakPassword,
        'invalid-email' => EmailAuthError.invalidEmail,
        'too-many-requests' => EmailAuthError.tooManyRequests,
        'network-request-failed' => EmailAuthError.network,
        _ => null,
      };

  /// E-postadaki bağlantının işi bitince "Devam" düğmesinin götürdüğü
  /// adres: Nilu'nun sayfası, telefonda Universal Link olarak uygulamayı
  /// açıyor ve uygulama hesabı yeniden okuyor (`AuthActionLink`).
  ///
  /// Firebase bu projede action URL'nin değiştirilmesine izin vermiyor
  /// (`EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`, konsolda da): bağlantı önce
  /// Firebase'in sayfasını açıyor, iş orada bitiyor, oradan Nilu'ya
  /// dönülüyor. Adresin alan adı Firebase'in yetkili alan adlarında.
  static ActionCodeSettings _donus(String mode) =>
      ActionCodeSettings(url: '${AppInfo.authLinkBase}?mode=$mode');

  Future<void> _setLanguage(String? languageCode) async {
    if (languageCode == null) return;
    try {
      await _auth.setLanguageCode(languageCode);
    } catch (e) {
      debugPrint('Auth language not set: $e');
    }
  }

  @override
  Future<SignInResult> signInWithEmail(
    String email,
    String password, {
    required bool create,
    String? languageCode,
  }) async {
    if (!isAvailable) return const SignInResult(SignInStatus.unavailable);
    final adres = email.trim();
    try {
      final UserCredential c;
      if (create) {
        c = await _auth.createUserWithEmailAndPassword(
          email: adres,
          password: password,
        );
        await _setLanguage(languageCode);
        try {
          await c.user?.sendEmailVerification(_donus('verified'));
        } catch (e) {
          debugPrint('Verification email failed: $e');
        }
      } else {
        c = await _auth.signInWithEmailAndPassword(
          email: adres,
          password: password,
        );
      }
      return SignInResult(SignInStatus.signedIn, user: fromUser(c.user));
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-in failed: ${e.code}');
      return SignInResult(SignInStatus.failed, emailError: _emailError(e));
    } catch (e) {
      debugPrint('Email sign-in failed: $e');
      return const SignInResult(SignInStatus.failed);
    }
  }

  @override
  Future<bool> sendPasswordReset(String email, {String? languageCode}) async {
    if (!isAvailable) return false;
    await _setLanguage(languageCode);
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: _donus('resetDone'),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset failed: ${e.code}');
      // Kayıtlı olmayan adres de başarı gibi: bkz. arayüz belgesi.
      return e.code == 'user-not-found';
    } catch (e) {
      debugPrint('Password reset failed: $e');
      return false;
    }
  }

  @override
  Future<bool> sendEmailVerification({String? languageCode}) async {
    final user = isAvailable ? _auth.currentUser : null;
    if (user == null) return false;
    await _setLanguage(languageCode);
    try {
      await user.sendEmailVerification(_donus('verified'));
      return true;
    } catch (e) {
      debugPrint('Verification email failed: $e');
      return false;
    }
  }

  @override
  Future<AccountUser?> reloadAccount() async {
    final user = isAvailable ? _auth.currentUser : null;
    if (user == null) return null;
    try {
      await user.reload();
      final guncel = _auth.currentUser;
      if (guncel != null && guncel.emailVerified) {
        // Jetondaki `email_verified` ancak yenilenince değişiyor.
        await guncel.getIdToken(true);
      }
    } catch (e) {
      debugPrint('Account reload failed: $e');
    }
    return fromUser(_auth.currentUser);
  }

  @override
  Future<bool> applyEmailVerification(String code) async {
    if (!isAvailable) return false;
    try {
      await _auth.applyActionCode(code);
      return true;
    } catch (e) {
      // Kod kullanılmış olabilir (ör. sayfada uygulandı); çağıran yine de
      // hesabı yeniden okuyor.
      debugPrint('Email verification failed: $e');
      return false;
    }
  }

  @override
  Future<String?> checkPasswordResetCode(String code) async {
    if (!isAvailable) return null;
    try {
      return await _auth.verifyPasswordResetCode(code);
    } catch (e) {
      debugPrint('Password reset code invalid: $e');
      return null;
    }
  }

  @override
  Future<PasswordResetResult> confirmPasswordReset(
    String code,
    String newPassword,
  ) async {
    if (!isAvailable) return PasswordResetResult.failed;
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return PasswordResetResult.done;
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset failed: ${e.code}');
      return switch (e.code) {
        'expired-action-code' ||
        'invalid-action-code' ||
        'user-disabled' ||
        'user-not-found' => PasswordResetResult.invalidLink,
        'weak-password' || 'password-does-not-meet-requirements' =>
          PasswordResetResult.weakPassword,
        _ => PasswordResetResult.failed,
      };
    } catch (e) {
      debugPrint('Password reset failed: $e');
      return PasswordResetResult.failed;
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
  Future<bool> reauthenticateForDeletion({String? password}) async {
    if (!isAvailable) return false;
    final user = _auth.currentUser;
    final hesap = fromUser(user);
    if (user == null || hesap == null) return true;
    try {
      final UserCredential c;
      if (hesap.provider == AccountProvider.email) {
        final adres = user.email;
        if (password == null || adres == null) return false;
        c = await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: adres, password: password),
        );
      } else if (hesap.provider == AccountProvider.google && _nativeGoogle) {
        c = await user.reauthenticateWithCredential(await _googleCredential());
      } else {
        c = await user.reauthenticateWithProvider(_provider(hesap.provider));
      }
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
