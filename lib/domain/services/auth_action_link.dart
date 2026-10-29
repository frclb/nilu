import '../../core/app_info.dart';

/// E-postadaki Firebase bağlantısının istediği işlem.
enum AuthAction {
  /// Adresi doğrula.
  verifyEmail,

  /// Yeni şifre belirle.
  resetPassword,

  /// Sayfa doğrulamayı kendisi bitirdi; uygulama hesabı yeniden okusun
  /// (sayfadaki "Nilu'ya dön" düğmesi).
  verified,
}

/// E-posta doğrulama ve şifre yenileme bağlantısı.
///
/// Firebase bağlantıyı `AppInfo.authLinkBase`'e yönlendiriyor:
/// `https://frclb.github.io/nilu/auth/?mode=verifyEmail&oobCode=…`. Telefonda
/// Universal Link olarak uygulamayı açıyor; sayfadaki düğme de aynı bilgiyi
/// `nilu://auth?mode=…&oobCode=…` ile veriyor.
class AuthActionLink {
  const AuthActionLink(this.action, [this.code]);

  final AuthAction action;

  /// Firebase'in tek kullanımlık kodu (`oobCode`).
  final String? code;

  /// Bağlantı Nilu'nun değilse ya da işlem tanınmıyorsa `null`.
  static AuthActionLink? fromUri(Uri uri) {
    final base = Uri.parse(AppInfo.authLinkBase);
    final bizim =
        (uri.scheme == 'https' &&
            uri.host == base.host &&
            uri.path.startsWith(base.path.replaceAll(RegExp(r'/$'), ''))) ||
        (uri.scheme == AppInfo.linkScheme && uri.host == 'auth');
    if (!bizim) return null;

    final kod = uri.queryParameters['oobCode'];
    final varKod = kod != null && kod.isNotEmpty;
    return switch (uri.queryParameters['mode']) {
      'verifyEmail' when varKod => AuthActionLink(AuthAction.verifyEmail, kod),
      'resetPassword' when varKod => AuthActionLink(
        AuthAction.resetPassword,
        kod,
      ),
      'verified' => const AuthActionLink(AuthAction.verified),
      _ => null,
    };
  }
}
