/// Cihazın bölgesine göre acil çağrı numarası.
///
/// Dil ülke demek değil: İngilizce telefonlu biri ABD'de, Portekizce telefonlu
/// biri Brezilya'da olabilir. Yanlış bir acil numara göstermek hiç
/// göstermemekten tehlikeli, o yüzden yalnızca emin olunan bölgeler listede;
/// bilinmeyen bölgede numara yok, "yerel acil numarası" yazısı var.
///
/// Avrupa'daki 112 AB mevzuatıyla (Avrupa Elektronik İletişim Kodu) bütün üye
/// ülkelerde zorunlu; Birleşik Krallık'ta 999 ve 112 ikisi de çalışıyor,
/// yerleşik olan 999 gösteriliyor.
class EmergencyNumber {
  const EmergencyNumber._();

  static const Map<String, String> _bolgeler = {
    'TR': '112',
    // AB ve AEA
    'DE': '112', 'FR': '112', 'ES': '112', 'PT': '112', 'IT': '112',
    'NL': '112', 'BE': '112', 'LU': '112', 'AT': '112', 'IE': '112',
    'DK': '112', 'SE': '112', 'FI': '112', 'PL': '112', 'CZ': '112',
    'SK': '112', 'HU': '112', 'RO': '112', 'BG': '112', 'GR': '112',
    'HR': '112', 'SI': '112', 'EE': '112', 'LV': '112', 'LT': '112',
    'CY': '112', 'MT': '112', 'NO': '112', 'IS': '112', 'CH': '112',
    'GB': '999',
    'US': '911', 'CA': '911', 'MX': '911',
    'BR': '192', // SAMU
    'AU': '000',
    'NZ': '111',
  };

  /// Bölge kodu (ISO 3166-1 alfa-2) için numara; bilinmiyorsa `null`.
  static String? forRegion(String? countryCode) =>
      countryCode == null ? null : _bolgeler[countryCode.toUpperCase()];
}
