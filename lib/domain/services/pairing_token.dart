import 'dart:math';

/// Paylaşılabilir, **döndürülebilir** eşleştirme kodu.
///
/// Önceden QR kodunun içinde kullanıcının UID'si vardı ve bu pratikte kalıcı
/// bir "bearer token" gibi çalışıyordu: UID hiç değişmediği için bir kez
/// paylaşılan kod sonsuza kadar geçerli kalıyordu. Ayrılmak erişimi
/// koparmıyordu — eski partner elindeki kodla kendini yeniden bağlayabiliyor,
/// yeni bir partner bağlamak da eskisini atmıyordu.
///
/// Kod artık UID'den bağımsız ve değiştirilebilir. Kullanıcı kodu
/// yenilediğinde daha önce paylaşılmış bütün QR'lar geçersiz oluyor.
class PairingToken {
  const PairingToken._();

  /// Kod uzunluğu.
  ///
  /// 20 karakter × 32 alfabe ≈ 100 bit; kaba kuvvetle bulunamaz. QR'a sığar
  /// ve gerekirse elle de okunabilir.
  static const int length = 20;

  /// Karışması kolay karakterler dışarıda: `0/O`, `1/I/l`.
  ///
  /// Kullanıcı kodu elle yazmak zorunda kalırsa bu fark eder.
  static const String alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static final RegExp _pattern = RegExp('^[$alphabet]{$length}\$');

  /// Yeni bir kod üretir.
  ///
  /// [random] testte belirlenimli bir kaynak verilebilsin diye dışarıdan
  /// alınıyor; üretimde kriptografik kaynak kullanılıyor.
  static String generate({Random? random}) {
    final rng = random ?? Random.secure();
    return List.generate(
      length,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
  }

  /// Biçim olarak geçerli bir eşleştirme kodu mu?
  ///
  /// Yalnızca biçim: kodun gerçekten bir kullanıcıya karşılık gelip
  /// gelmediği sunucuda çözülür.
  static bool isWellFormed(String? value) {
    final code = value?.trim();
    if (code == null) return false;
    return _pattern.hasMatch(code);
  }

  /// Kullanıcıya gösterilecek biçim: dörtlü gruplar.
  ///
  /// Telefonla okurken ya da sesli söylerken 20 karakterlik tek blok
  /// takip edilemiyor.
  static String forDisplay(String token) {
    final buffer = StringBuffer();
    for (var i = 0; i < token.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(token.substring(i, min(i + 4, token.length)));
    }
    return buffer.toString();
  }

  /// Kullanıcının elle yazdığı kodu kanonik hâle getirir.
  static String normalize(String input) =>
      input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
}
