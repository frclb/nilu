import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Parola yanlış ya da dosya değiştirilmiş: AES-GCM ikisini ayırt etmiyor.
class BackupPasswordException implements Exception {
  const BackupPasswordException();
}

/// Dosya şifreli yedek biçiminde değil ya da bozuk.
class BackupFormatException implements Exception {
  const BackupFormatException();
}

/// Yedeği parolayla şifreler ve çözer.
///
/// Yedek sağlık geçmişinin tamamı: regl günleri, belirtiler, gebelikler,
/// notlar. Paylaşım sayfasından e-postaya, buluta ya da bir mesajlaşma
/// uygulamasına gittiğinde orada düz metin olarak duruyordu.
///
/// Anahtar paroladan PBKDF2-HMAC-SHA256 ile türetiliyor, içerik
/// AES-256-GCM ile şifreleniyor. GCM bütünlüğü de doğruluyor: yanlış parola
/// ya da değiştirilmiş dosya açılmıyor, yarım yamalak veri içeri
/// alınmıyor. Başlık (biçim, sürüm, tekrar sayısı) ek veri olarak
/// doğrulamaya giriyor; tekrar sayısını düşürmek dosyayı bozar.
///
/// Parola hiçbir yerde saklanmıyor. Unutulursa yedek açılamaz — ekran
/// bunu baştan söylüyor.
class BackupCrypto {
  const BackupCrypto._();

  static const String format = 'nilu-encrypted-backup';
  static const int version = 1;

  /// PBKDF2 tekrar sayısı. Kaba kuvveti yavaşlatmak için yüksek; saf
  /// Dart'ta telefonda bir iki saniye sürüyor ve yalnızca dışa/içe
  /// aktarırken bir kez çalışıyor.
  static const int iterations = 200000;

  /// Kabul edilen en kısa parola.
  static const int minPasswordLength = 8;

  /// Okurken kabul edilen tekrar aralığı: kötü niyetli bir dosya
  /// milyarlarca tekrar isteyip uygulamayı kilitlemesin.
  static const int _minIterations = 100000;
  static const int _maxIterations = 5000000;

  static final AesGcm _aes = AesGcm.with256bits();

  /// Metin şifreli yedek mi? İçe aktarma ekranı buna göre parola soruyor.
  static bool isEncrypted(String text) {
    try {
      final data = jsonDecode(text);
      return data is Map && data['format'] == format;
    } catch (_) {
      return false;
    }
  }

  static Future<String> encrypt(
    String plain,
    String password, {
    int iterations = BackupCrypto.iterations,
    Random? random,
  }) async {
    final rnd = random ?? Random.secure();
    List<int> rastgele(int n) => [for (var i = 0; i < n; i++) rnd.nextInt(256)];

    final salt = rastgele(16);
    final nonce = rastgele(12);
    final key = await _derive(password, salt, iterations);
    final box = await _aes.encrypt(
      utf8.encode(plain),
      secretKey: key,
      nonce: nonce,
      aad: _aad(iterations),
    );

    return jsonEncode({
      'format': format,
      'version': version,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': iterations,
      'cipher': 'aes-256-gcm',
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'data': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  static Future<String> decrypt(String envelope, String password) async {
    final Map<String, dynamic> e;
    final int tekrar;
    final List<int> salt, nonce, data, mac;
    try {
      e = jsonDecode(envelope) as Map<String, dynamic>;
      if (e['format'] != format || e['version'] != version) {
        throw const BackupFormatException();
      }
      tekrar = e['iterations'] as int;
      salt = base64Decode(e['salt'] as String);
      nonce = base64Decode(e['nonce'] as String);
      data = base64Decode(e['data'] as String);
      mac = base64Decode(e['mac'] as String);
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      throw const BackupFormatException();
    }
    if (tekrar < _minIterations || tekrar > _maxIterations) {
      throw const BackupFormatException();
    }

    final key = await _derive(password, salt, tekrar);
    try {
      final plain = await _aes.decrypt(
        SecretBox(data, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: _aad(tekrar),
      );
      return utf8.decode(plain);
    } on SecretBoxAuthenticationError {
      throw const BackupPasswordException();
    }
  }

  static List<int> _aad(int iterations) =>
      utf8.encode('$format/$version/$iterations');

  static Future<SecretKey> _derive(
    String password,
    List<int> salt,
    int iterations,
  ) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);
}
