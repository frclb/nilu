import 'package:flutter/widgets.dart';

/// Uygulamanın desteklediği diller.
///
/// **Sıra anlamlı.** Cihazın dili bu listede yoksa Flutter listenin *ilk*
/// öğesine düşüyor. Türkçe baştayken İtalyanca, Japonca ya da Lehçe bir
/// telefon uygulamayı **Türkçe** açıyordu — o kullanıcı için okunamaz bir
/// ekran. İngilizce başta olunca eşleşmeyen herkes anlayabileceği bir dile
/// düşüyor.
///
/// Eşleşen kullanıcıyı sıra etkilemiyor: Türkçe telefon yine Türkçe açılır.
/// Sıralama yalnızca "hiçbiri tutmadı" durumunu belirliyor.
///
/// iOS tarafında karşılığı `ios/Runner/Info.plist` içindeki
/// `CFBundleLocalizations` ve `ios/Runner/*.lproj` klasörleri. Onlar
/// olmadan iOS cihazın dil tercihlerini uygulamaya eksik bildiriyor.
const List<Locale> appSupportedLocales = [
  Locale('en'),
  Locale('tr'),
  Locale('de'),
  Locale('fr'),
  Locale('es'),
  Locale('pt'),
];
