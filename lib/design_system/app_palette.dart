import 'package:flutter/material.dart';

/// Ham renk basamakları — markanın tek kaynağı.
///
/// Ekranlar buradan **okumaz**; `AppTokens` üzerinden role göre okur
/// (`tokens.surface`, `tokens.textMuted`…). Böylece palet değiştiğinde
/// dokunulacak tek yer burasıdır.
///
/// Önceki palet oksikan kırmızı (#551B26) üzerine kuruluydu ve iki sorunu
/// vardı: büyük yüzeylerde ağır/klinik duruyordu, açık temada soluk pembe
/// ile soğuk gri arasındaki kontrast düşük olduğu için her şey birbirine
/// karışıyordu. Yeni palet derin erik + sıcak kum üzerine kurulu; vurgu
/// için tek bir kil tonu var.
///
/// Metin/zemin eşleşmeleri WCAG AA (4.5:1) eşiğine göre seçildi.
class AppPalette {
  const AppPalette._();

  // ── Marka: derin erik ──
  static const plum900 = Color(0xFF3E1B33);
  static const plum700 = Color(0xFF6B2F55); // birincil
  static const plum500 = Color(0xFF8E4571);
  static const plum300 = Color(0xFFC79BB4); // koyu temada marka metni

  // ── Akış: gül. Erikten ayrışır ama akrabadır. ──
  static const rose600 = Color(0xFFB24A66);
  static const rose400 = Color(0xFFD07E93);
  static const rose200 = Color(0xFFF0CDD5);
  static const rose50 = Color(0xFFFBEEF1);

  // ── Vurgu: sıcak kil. Tek vurgu rengi; her yere serpiştirilmez. ──
  /// Beyaz metinle 4.65:1 — AA. Daha açık tonlarda beyaz metin kullanmayın.
  static const clay600 = Color(0xFFB85936);
  static const clay400 = Color(0xFFE08A5F);
  static const clay100 = Color(0xFFF7DFD1);

  // ── Yumurtlama: mor. Gülden net ayrılsın diye ayrı aile. ──
  static const iris500 = Color(0xFF7B5EA7);
  static const iris100 = Color(0xFFE4DCF2);

  // ── Nötr: sıcak kum. Soğuk gri değil; ten rengiyle çakışmaz. ──
  static const sand50 = Color(0xFFFBF8F5);
  static const sand100 = Color(0xFFF3ECE6);
  static const sand200 = Color(0xFFE6DBD2);

  static const ink900 = Color(0xFF241A21);
  static const ink600 = Color(0xFF6B5C65);
  static const ink400 = Color(0xFF9A8B94);

  // ── Koyu tema ──
  static const night900 = Color(0xFF151014);
  static const night800 = Color(0xFF1E1720);
  static const night700 = Color(0xFF2B2130);
  static const night600 = Color(0xFF3A2D40);

  static const nightInk = Color(0xFFF2E9EE);
  static const nightInkMuted = Color(0xFFB9A8B3);

  // ── Durum ──
  static const success = Color(0xFF3E8E7E);
  static const warning = Color(0xFFB8862F);
  static const danger = Color(0xFFB3453F);
}
