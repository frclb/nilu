import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/pairing_token.dart';

void main() {
  group('PairingToken', () {
    test('üretilen kod doğru uzunlukta ve alfabededir', () {
      for (var i = 0; i < 50; i++) {
        final token = PairingToken.generate();
        expect(token.length, PairingToken.length);
        for (final ch in token.split('')) {
          expect(PairingToken.alphabet, contains(ch));
        }
      }
    });

    test('üretilen kod geçerli sayılır', () {
      expect(PairingToken.isWellFormed(PairingToken.generate()), isTrue);
    });

    test('kodlar tekrarlanmaz', () {
      // Çakışma pratikte imkânsız; bu test üretecin sabit dönmediğini
      // garantiliyor.
      final seen = {for (var i = 0; i < 200; i++) PairingToken.generate()};
      expect(seen.length, 200);
    });

    test('karışması kolay karakterler alfabede yok', () {
      // Kod elle yazılabildiği için 0/O ve 1/I/l ayrımı gerekiyor.
      for (final ch in ['0', 'O', '1', 'I', 'L']) {
        expect(PairingToken.alphabet, isNot(contains(ch)));
      }
    });

    test('UID biçimi artık geçerli bir kod değil', () {
      // Asıl düzeltme bu: QR'da UID taşımak kalıcı bir bearer token
      // demekti, çünkü UID hiç değişmiyor.
      expect(
        PairingToken.isWellFormed('kK3nZ8pQrS1tUvWxYz2AbCdEfGh4'),
        isFalse,
      );
      expect(
        PairingToken.isWellFormed('550e8400-e29b-41d4-a716-446655440000'),
        isFalse,
      );
    });

    test('boş, kısa ve uzun değerler reddedilir', () {
      expect(PairingToken.isWellFormed(null), isFalse);
      expect(PairingToken.isWellFormed(''), isFalse);
      expect(PairingToken.isWellFormed('   '), isFalse);
      expect(PairingToken.isWellFormed('ABCD'), isFalse);
      expect(
        PairingToken.isWellFormed('A' * (PairingToken.length + 1)),
        isFalse,
      );
    });

    test('baştaki ve sondaki boşluk yok sayılır', () {
      final token = PairingToken.generate();
      expect(PairingToken.isWellFormed('  $token  '), isTrue);
    });

    test('gösterim dörtlü gruplara ayrılır', () {
      const token = 'ABCDEFGHJKMNPQRSTUVW';
      expect(PairingToken.forDisplay(token), 'ABCD EFGH JKMN PQRS TUVW');
    });

    test('elle yazılan kod kanonikleştirilir', () {
      expect(
        PairingToken.normalize('abcd efgh jkmn pqrs tuvw'),
        'ABCDEFGHJKMNPQRSTUVW',
      );
      expect(PairingToken.normalize(' ab\tcd\nef '), 'ABCDEF');
    });

    test('kanonikleştirilen gösterim yeniden geçerli olur', () {
      final token = PairingToken.generate();
      final round = PairingToken.normalize(PairingToken.forDisplay(token));
      expect(round, token);
      expect(PairingToken.isWellFormed(round), isTrue);
    });

    test('belirlenimli kaynakla aynı kod üretilir', () {
      final a = PairingToken.generate(random: Random(42));
      final b = PairingToken.generate(random: Random(42));
      expect(a, b);
    });
  });
}
