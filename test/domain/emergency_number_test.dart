import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/emergency_number.dart';

void main() {
  test('Türkiye 112', () => expect(EmergencyNumber.forRegion('TR'), '112'));

  test('dil değil bölge belirliyor', () {
    // İngilizce telefon ABD'de 911, Birleşik Krallık'ta 999.
    expect(EmergencyNumber.forRegion('US'), '911');
    expect(EmergencyNumber.forRegion('GB'), '999');
    // Portekizce telefon Brezilya'da SAMU 192, Portekiz'de 112.
    expect(EmergencyNumber.forRegion('BR'), '192');
    expect(EmergencyNumber.forRegion('PT'), '112');
  });

  test('bilinmeyen bölgede numara uydurulmuyor', () {
    expect(
      EmergencyNumber.forRegion('ZZ'),
      isNull,
      reason: 'Yanlış acil numara göstermek hiç göstermemekten tehlikeli',
    );
    expect(EmergencyNumber.forRegion(null), isNull);
  });

  test('küçük harf de çalışıyor', () {
    expect(EmergencyNumber.forRegion('tr'), '112');
  });
}
