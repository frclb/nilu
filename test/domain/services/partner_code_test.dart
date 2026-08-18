import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/partner_code.dart';

void main() {
  const myId = 'aBcD1234efGH5678ijKL9012mnOP'; // Firebase UID biçimi
  const partnerId = '9f8e7d6c-5b4a-3210-fedc-ba9876543210'; // UUID biçimi

  group('geçerli kod', () {
    test('başka birinin UID\'i kabul edilir', () {
      expect(
        PartnerCode.validate(partnerId, myId: myId),
        PartnerCodeStatus.valid,
      );
    });

    test('baştaki ve sondaki boşluk kırpılır', () {
      expect(
        PartnerCode.validate('  $partnerId  ', myId: myId),
        PartnerCodeStatus.valid,
      );
    });

    test('kimlik henüz üretilmemişse yine de bağlanılabilir', () {
      // Partner uygulamayı ilk kez açıp doğrudan taramaya gidebiliyor.
      expect(
        PartnerCode.validate(partnerId, myId: null),
        PartnerCodeStatus.valid,
      );
    });
  });

  group('reddedilen kodlar', () {
    test('kendi kodu reddedilir', () {
      // Kişi kendi partneri olamaz; olursa uygulama partner moduna geçip
      // kendi takip ekranlarını kaybediyordu.
      expect(PartnerCode.validate(myId, myId: myId), PartnerCodeStatus.ownCode);
    });

    test('zaten bağlı olunan partner reddedilir', () {
      expect(
        PartnerCode.validate(
          partnerId,
          myId: myId,
          currentPartnerId: partnerId,
        ),
        PartnerCodeStatus.alreadyConnected,
      );
    });

    test('boş içerik reddedilir', () {
      for (final code in [null, '', '   ']) {
        expect(
          PartnerCode.validate(code, myId: myId),
          PartnerCodeStatus.empty,
          reason: 'girdi: ${code == null ? 'null' : '"$code"'}',
        );
      }
    });

    test('eşleştirme kodu olmayan QR içerikleri reddedilir', () {
      // Tarayıcı eskiden bunların hepsini partnerId olarak kaydediyordu.
      const notCodes = [
        'https://example.com/kampanya',
        'WIFI:S:EvAgi;T:WPA;P:parola123;;',
        'BEGIN:VCARD\nFN:Ayse\nEND:VCARD',
        'merhaba dünya',
        '12345',
      ];

      for (final code in notCodes) {
        expect(
          PartnerCode.validate(code, myId: myId),
          PartnerCodeStatus.malformed,
          reason: code,
        );
      }
    });

    test('sınır uzunlukları', () {
      final tooShort = 'a' * (PartnerCode.minLength - 1);
      final tooLong = 'a' * (PartnerCode.maxLength + 1);
      final shortest = 'a' * PartnerCode.minLength;

      expect(
        PartnerCode.validate(tooShort, myId: myId),
        PartnerCodeStatus.malformed,
      );
      expect(
        PartnerCode.validate(tooLong, myId: myId),
        PartnerCodeStatus.malformed,
      );
      expect(
        PartnerCode.validate(shortest, myId: myId),
        PartnerCodeStatus.valid,
      );
    });
  });

  group('yeni partnere geçiş', () {
    test('ayrıldıktan sonra farklı bir kod kabul edilir', () {
      const yeniPartner = 'ZZZZ1234efGH5678ijKL9012mnOP';

      // Ayrılmadan önce: eski partnere tekrar bağlanma engellenir.
      expect(
        PartnerCode.validate(
          partnerId,
          myId: myId,
          currentPartnerId: partnerId,
        ),
        PartnerCodeStatus.alreadyConnected,
      );

      // Ayrıldıktan sonra (currentPartnerId temizlenmiş): yeni kod serbest.
      expect(
        PartnerCode.validate(yeniPartner, myId: myId, currentPartnerId: null),
        PartnerCodeStatus.valid,
      );
    });
  });

  test('her durumun bir mesaj anahtarı var, geçerli olanın yok', () {
    for (final status in PartnerCodeStatus.values) {
      if (status.isValid) {
        expect(status.messageKey, isNull);
      } else {
        expect(status.messageKey, isNotNull, reason: status.name);
      }
    }
  });
}
