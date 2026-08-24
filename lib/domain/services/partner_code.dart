import 'pairing_token.dart';

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
  malformed,

  /// Biçim doğru ama kod bir kullanıcıya karşılık gelmiyor: yenilenmiş,
  /// iptal edilmiş ya da hesabı silinmiş.
  unknownCode;

  bool get isValid => this == PartnerCodeStatus.valid;

  /// Kullanıcıya gösterilecek hata metninin anahtarı.
  String? get messageKey => switch (this) {
    PartnerCodeStatus.valid => null,
    PartnerCodeStatus.empty => 'partner_scan_error_empty',
    PartnerCodeStatus.ownCode => 'partner_scan_error_own_code',
    PartnerCodeStatus.alreadyConnected => 'partner_scan_error_already',
    PartnerCodeStatus.malformed => 'partner_scan_error_malformed',
    PartnerCodeStatus.unknownCode => 'partner_scan_error_unknown',
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
///
/// İki aşama var, çünkü QR'daki şey artık UID değil **döndürülebilir bir
/// eşleştirme kodu**. Kodun kime ait olduğu ancak sunucuda çözülüyor:
///
///  1. [validateFormat] — çevrimdışı biçim kontrolü. Afişteki bir bağlantıyı
///     ya da wifi QR'ını sunucuya hiç gitmeden ayıklar.
///  2. [validateOwner] — kod çözüldükten sonra: kendi kodum mu, zaten bağlı
///     olduğum kişi mi, kod hâlâ geçerli mi.
class PartnerCode {
  const PartnerCode._();

  /// Okunan içeriğin biçim olarak eşleştirme kodu olup olmadığı.
  static PartnerCodeStatus validateFormat(String? scanned) {
    final raw = scanned?.trim();
    if (raw == null || raw.isEmpty) return PartnerCodeStatus.empty;

    // Elle yazılmış ya da boşluklu gösterim biçimi de kabul edilsin.
    final code = PairingToken.normalize(raw);
    if (!PairingToken.isWellFormed(code)) return PartnerCodeStatus.malformed;

    return PartnerCodeStatus.valid;
  }

  /// Kodun sahibi çözüldükten sonraki doğrulama.
  ///
  /// [ownerUid] `null` ise kod bir kullanıcıya karşılık gelmiyor: sahibi kodu
  /// yenilemiş ya da hesabını silmiş olabilir. Eski modelde bu durum hiç
  /// oluşmuyordu çünkü UID kalıcıydı — iptalin çalıştığının işareti tam da bu.
  static PartnerCodeStatus validateOwner(
    String? ownerUid, {
    required String? myId,
    String? currentPartnerId,
  }) {
    if (ownerUid == null || ownerUid.isEmpty) {
      return PartnerCodeStatus.unknownCode;
    }

    // Kendi kodu: kişi kendi partneri olamaz.
    if (myId != null && myId.isNotEmpty && ownerUid == myId) {
      return PartnerCodeStatus.ownCode;
    }

    if (currentPartnerId != null && ownerUid == currentPartnerId) {
      return PartnerCodeStatus.alreadyConnected;
    }

    return PartnerCodeStatus.valid;
  }
}
