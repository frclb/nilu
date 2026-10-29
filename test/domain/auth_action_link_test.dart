import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/services/auth_action_link.dart';

/// E-postadaki doğrulama ve şifre yenileme bağlantıları uygulamayı açıyor.
void main() {
  AuthActionLink? oku(String link) => AuthActionLink.fromUri(Uri.parse(link));

  test('Firebase bağlantısı: işlem ve kod', () {
    final dogrula = oku(
      'https://frclb.github.io/nilu/auth/?mode=verifyEmail&oobCode=ABC123'
      '&apiKey=k&lang=tr',
    );
    expect(dogrula?.action, AuthAction.verifyEmail);
    expect(dogrula?.code, 'ABC123');

    final yenile = oku(
      'https://frclb.github.io/nilu/auth/?mode=resetPassword&oobCode=XYZ',
    );
    expect(yenile?.action, AuthAction.resetPassword);
    expect(yenile?.code, 'XYZ');
  });

  test('sitedeki düğmenin bağlantısı', () {
    expect(
      oku('nilu://auth?mode=resetPassword&oobCode=XYZ')?.action,
      AuthAction.resetPassword,
    );
    expect(oku('nilu://auth?mode=verified')?.action, AuthAction.verified);
  });

  test('başka adres, kodsuz işlem ve bilinmeyen işlem kabul edilmiyor', () {
    for (final link in [
      'https://ornek.com/nilu/auth/?mode=verifyEmail&oobCode=A',
      'https://frclb.github.io/nilu/p/?mode=verifyEmail&oobCode=A',
      'https://frclb.github.io/nilu/auth/?mode=verifyEmail',
      'https://frclb.github.io/nilu/auth/?mode=recoverEmail&oobCode=A',
      'nilu://p#ABCDEFGHJKMNPQRSTUVW',
    ]) {
      expect(oku(link), isNull, reason: link);
    }
  });
}
