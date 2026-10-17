// `lib/core/release_config.dart`'taki sabitleri metin olarak okur.
//
// İçe aktarılmıyor: denetleyici ve site oluşturucu doldurulmuş ya da boş
// örnek projelerle test edilebilsin diye kaynak metinden okunuyor.

/// `static const String? ad = 'değer';` → değer. `null` ya da yer tutucu
/// ise `null`.
String? releaseValue(String source, String name) {
  final m = RegExp(
    'static const String\\?? $name\\s*=\\s*([^;]+);',
  ).firstMatch(source);
  if (m == null) return null;
  final raw = m.group(1)!.trim();
  if (raw == 'null' || raw == 'placeholder') return null;
  final quoted = RegExp(r"^'([^']*)'$").firstMatch(raw)?.group(1);
  if (quoted == null || quoted == 'YER_TUTUCU') return null;
  return quoted;
}
