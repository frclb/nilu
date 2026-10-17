import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/services/backup_crypto.dart';

/// Parolalı yedek: şifreleme, bütünlük ve kötü niyetli dosyalar.
void main() {
  // Testte en düşük kabul edilen tekrar: hız için. Üretim değeri ayrı
  // sınanıyor.
  const tekrar = 100000;
  const metin = '{"periodLogs":[{"id":"1"}],"notes":"çok özel"}';

  Future<String> sifrele([String parola = 'dogru-parola']) =>
      BackupCrypto.encrypt(metin, parola, iterations: tekrar);

  Map<String, dynamic> zarf(String s) => jsonDecode(s) as Map<String, dynamic>;

  test('gidiş-dönüş', () async {
    final s = await sifrele();
    expect(s, isNot(contains('çok özel')));
    expect(await BackupCrypto.decrypt(s, 'dogru-parola'), metin);
  });

  test('yanlış parola açmıyor', () async {
    final s = await sifrele();
    await expectLater(
      BackupCrypto.decrypt(s, 'yanlis-parola'),
      throwsA(isA<BackupPasswordException>()),
    );
  });

  test('değiştirilmiş içerik açılmıyor (yarım veri içeri alınmaz)', () async {
    final e = zarf(await sifrele());
    final veri = base64Decode(e['data'] as String);
    veri[0] ^= 0x01;
    e['data'] = base64Encode(veri);
    await expectLater(
      BackupCrypto.decrypt(jsonEncode(e), 'dogru-parola'),
      throwsA(isA<BackupPasswordException>()),
    );
  });

  test('başlıktaki tekrar sayısı değiştirilirse açılmıyor', () async {
    final e = zarf(await sifrele());
    e['iterations'] = tekrar + 1;
    await expectLater(
      BackupCrypto.decrypt(jsonEncode(e), 'dogru-parola'),
      throwsA(isA<BackupPasswordException>()),
    );
  });

  test('aşırı ya da düşük tekrar isteyen dosya reddediliyor', () async {
    for (final n in [10, 999999999]) {
      final e = zarf(await sifrele());
      e['iterations'] = n;
      await expectLater(
        BackupCrypto.decrypt(jsonEncode(e), 'dogru-parola'),
        throwsA(isA<BackupFormatException>()),
        reason: '$n',
      );
    }
  });

  test('her şifrelemede tuz ve nonce farklı', () async {
    final a = zarf(await sifrele());
    final b = zarf(await sifrele());
    expect(a['salt'], isNot(b['salt']));
    expect(a['nonce'], isNot(b['nonce']));
    expect(a['data'], isNot(b['data']));
  });

  test('şifreli yedek tanınıyor, düz yedek ve çöp tanınmıyor', () async {
    expect(BackupCrypto.isEncrypted(await sifrele()), isTrue);
    expect(BackupCrypto.isEncrypted(metin), isFalse);
    expect(BackupCrypto.isEncrypted('çöp'), isFalse);
    expect(BackupCrypto.isEncrypted('[1,2]'), isFalse);
  });

  test('bozuk zarf biçim hatası veriyor', () async {
    for (final bozuk in [
      'çöp',
      '{"format":"nilu-encrypted-backup"}',
      '{"format":"nilu-encrypted-backup","version":99}',
      '{"format":"baska","version":1}',
    ]) {
      await expectLater(
        BackupCrypto.decrypt(bozuk, 'x'),
        throwsA(isA<BackupFormatException>()),
        reason: bozuk,
      );
    }
  });

  test('üretimde tekrar sayısı ve parola sınırı', () async {
    expect(BackupCrypto.iterations, greaterThanOrEqualTo(100000));
    expect(BackupCrypto.minPasswordLength, greaterThanOrEqualTo(8));
    final s = await BackupCrypto.encrypt('a', 'parola123', random: Random(1));
    expect(zarf(s)['iterations'], BackupCrypto.iterations);
  });
}
