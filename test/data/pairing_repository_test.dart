import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/pairing_repository.dart';
import 'package:period_tracker/domain/services/pairing_token.dart';

/// Eşleştirme kodu okunduğunda **değişmemeli**.
///
/// Kodun üretimi ve doğrulaması ayrıca sınanıyor (bkz. `pairing_token_test`),
/// ama `currentToken`'ın kalıcılığı sınanmıyordu. Oysa yanlış giderse sonucu
/// sessiz ve ağır: kod her okumada yenilenirse kullanıcının paylaştığı QR
/// ekranı bir daha açtığı anda geçersiz oluyor ve eşleşme hiç kurulamıyor.
/// Ekranı açmak kodu döndürmemeli — döndürmek yalnızca "Kodu yenile"nin işi.
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  final repo = PairingRepository();

  test('aynı kod tekrar tekrar döner', () async {
    final first = await repo.currentToken('uid-1');
    final second = await repo.currentToken('uid-1');
    final third = await repo.currentToken('uid-1');

    expect(PairingToken.isWellFormed(first), isTrue);
    expect(
      [second, third],
      everyElement(first),
      reason:
          'QR ekranını her açışta kod değişirse daha önce paylaşılan kod '
          'çalışmaz; kullanıcı neden eşleşemediğini de anlamaz',
    );
  });

  test('yenileme kodu değiştirir', () async {
    final before = await repo.currentToken('uid-1');
    final after = await repo.rotate('uid-1');

    expect(
      after,
      isNot(before),
      reason: 'Yenilemenin tek anlamı önceki QR\'ların çalışmayı bırakması',
    );
    expect(await repo.currentToken('uid-1'), after);
  });

  test('bozuk kayıt yerine geçerli kod üretilir', () async {
    // Eski sürümlerde burada UID duruyordu; artık geçerli bir kod değil.
    FlutterSecureStorage.setMockInitialValues({'pairing_token': 'uid-1'});

    final token = await repo.currentToken('uid-1');

    expect(PairingToken.isWellFormed(token), isTrue);
    expect(
      token,
      isNot('uid-1'),
      reason:
          'Geçersiz kod olduğu gibi döndürülürse QR okunuyor ama hiçbir '
          'kullanıcıya çözülmüyor',
    );
  });
}
