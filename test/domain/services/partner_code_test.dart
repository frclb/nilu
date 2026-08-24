import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/pairing_token.dart';
import 'package:period_tracker/domain/services/partner_code.dart';

void main() {
  // Geçerli biçimde bir eşleştirme kodu.
  final token = PairingToken.generate();
  const myId = 'aBcDeFgHiJkLmNoPqRsTuVwXyZ12';
  const otherId = 'zZyYxXwWvVuUtTsSrRqQpPoOnN34';

  group('biçim doğrulaması', () {
    test('geçerli kod kabul edilir', () {
      expect(PartnerCode.validateFormat(token), PartnerCodeStatus.valid);
    });

    test('baştaki ve sondaki boşluk yok sayılır', () {
      expect(PartnerCode.validateFormat('  $token  '), PartnerCodeStatus.valid);
    });

    test('gösterim biçimi (dörtlü gruplar) da kabul edilir', () {
      // Kamera çalışmadığında kullanıcı kodu elle yazabilmeli.
      expect(
        PartnerCode.validateFormat(PairingToken.forDisplay(token)),
        PartnerCodeStatus.valid,
      );
    });

    test('boş kod reddedilir', () {
      expect(PartnerCode.validateFormat(null), PartnerCodeStatus.empty);
      expect(PartnerCode.validateFormat('   '), PartnerCodeStatus.empty);
    });

    test('eşleştirme kodu olmayan içerik reddedilir', () {
      // Afişteki bir bağlantıyı okutmak kullanıcıyı var olmayan bir
      // "partnere" bağlıyordu.
      for (final junk in [
        'https://example.com',
        'WIFI:S:Cafe;T:WPA;P:1234;;',
        'merhaba',
        '12345',
      ]) {
        expect(
          PartnerCode.validateFormat(junk),
          PartnerCodeStatus.malformed,
          reason: junk,
        );
      }
    });

    test('UID biçimi artık geçerli bir kod değil', () {
      // Eski modelde QR'da UID vardı; kalıcı olduğu için iptal edilemiyordu.
      expect(PartnerCode.validateFormat(myId), PartnerCodeStatus.malformed);
    });
  });

  group('sahip doğrulaması', () {
    test('başka bir kullanıcının kodu geçerli', () {
      expect(
        PartnerCode.validateOwner(otherId, myId: myId),
        PartnerCodeStatus.valid,
      );
    });

    test('kendi kodu reddedilir', () {
      expect(
        PartnerCode.validateOwner(myId, myId: myId),
        PartnerCodeStatus.ownCode,
      );
    });

    test('zaten bağlı olunan partner reddedilir', () {
      expect(
        PartnerCode.validateOwner(
          otherId,
          myId: myId,
          currentPartnerId: otherId,
        ),
        PartnerCodeStatus.alreadyConnected,
      );
    });

    test('çözülemeyen kod reddedilir', () {
      // Sahip kodu yenilediyse ya da hesabını sildiyse kod çözülmez.
      // İptalin gerçekten çalıştığının işareti bu durumun oluşabilmesi.
      expect(
        PartnerCode.validateOwner(null, myId: myId),
        PartnerCodeStatus.unknownCode,
      );
      expect(
        PartnerCode.validateOwner('', myId: myId),
        PartnerCodeStatus.unknownCode,
      );
    });

    test('kimliğimiz yoksa yine bağlanılabilir', () {
      // Firebase kapalıysa yerel UUID henüz üretilmemiş olabilir.
      expect(
        PartnerCode.validateOwner(otherId, myId: null),
        PartnerCodeStatus.valid,
      );
    });
  });

  group('hata mesajları', () {
    test('her geçersiz durumun bir mesaj anahtarı var', () {
      for (final status in PartnerCodeStatus.values) {
        if (status.isValid) {
          expect(status.messageKey, isNull);
        } else {
          expect(status.messageKey, isNotNull, reason: '$status');
          expect(status.messageKey, isNotEmpty, reason: '$status');
        }
      }
    });
  });
}
