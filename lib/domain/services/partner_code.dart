/// Taranan QR kodunun eşleştirme için geçerli olup olmadığı.
enum PartnerCodeStatus {
  valid,

  /// QR boş ya da yalnızca boşluk.
  empty,

  /// Kullanıcı kendi kodunu okuttu.
  ownCode,

  /// Zaten bu partnere bağlı.
  alreadyConnected,

  /// İçerik bir eşleştirme kodu değil (afişteki bir bağlantı, wifi QR'ı…).
  malformed;

  bool get isValid => this == PartnerCodeStatus.valid;

  /// Kullanıcıya gösterilecek hata metninin anahtarı.
  String? get messageKey => switch (this) {
    PartnerCodeStatus.valid => null,
    PartnerCodeStatus.empty => 'partner_scan_error_empty',
    PartnerCodeStatus.ownCode => 'partner_scan_error_own_code',
    PartnerCodeStatus.alreadyConnected => 'partner_scan_error_already',
    PartnerCodeStatus.malformed => 'partner_scan_error_malformed',
  };
}

/// Eşleştirme kodunun doğrulaması.
///
/// Tarayıcı eskiden okuduğu **her** QR'ı kabul ediyordu: `rawValue` doğrudan
/// `partnerId` olarak kaydediliyordu. Sonuçları:
///
/// - Afişteki bir bağlantıyı okutmak kullanıcıyı var olmayan bir "partnere"
///   bağlıyor, uygulama partner moduna geçiyor ve kendi takip ekranlarını
///   kaybediyordu.
/// - Kendi QR'ını okutmak kişiyi kendi partneri yapıyordu.
///
/// Doğrulama saf bir fonksiyon: kamera açmadan tüm durumlar test edilebiliyor.
class PartnerCode {
  const PartnerCode._();

  /// Kimlikler Firebase UID (28 karakter) ya da yerel UUID v4 (36 karakter).
  /// Aralık biraz geniş tutuldu ki ileride kimlik biçimi değişirse doğrulama
  /// sessizce kırılmasın.
  static const int minLength = 16;
  static const int maxLength = 64;

  /// UID ve UUID'nin ortak karakter kümesi.
  static final RegExp _allowed = RegExp(r'^[A-Za-z0-9_-]+$');

  static PartnerCodeStatus validate(
    String? scanned, {
    required String? myId,
    String? currentPartnerId,
  }) {
    final code = scanned?.trim();

    if (code == null || code.isEmpty) return PartnerCodeStatus.empty;

    if (code.length < minLength ||
        code.length > maxLength ||
        !_allowed.hasMatch(code)) {
      return PartnerCodeStatus.malformed;
    }

    // Kendi kodu: kişi kendi partneri olamaz.
    if (myId != null && myId.isNotEmpty && code == myId) {
      return PartnerCodeStatus.ownCode;
    }

    if (currentPartnerId != null && code == currentPartnerId) {
      return PartnerCodeStatus.alreadyConnected;
    }

    return PartnerCodeStatus.valid;
  }
}
