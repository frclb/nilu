import 'package:flutter/material.dart';

/// Ham renk basamakları — markanın tek kaynağı.
///
/// Ekranlar buradan **okumaz**; `AppTokens` üzerinden role göre okur
/// (`tokens.surface`, `tokens.textMuted`…). Böylece palet değiştiğinde
/// dokunulacak tek yer burasıdır.
///
/// Ekim 2026 yenilemesi ("Luminous Editorial Wellness", Stitch): derin
/// botanik erik, böğürtlen gülü vurgu ve sıcak, hafif pembe bir zemin.
/// Evre renkleri doygunlaştı (gül, adaçayı, menekşe, kehribar) — soluk
/// pasteller yerine canlı ama okunur tonlar.
///
/// Metin/zemin eşleşmeleri WCAG AA (4.5:1) eşiğine göre seçildi; açık
/// tonlar (pink400, rose400…) yalnızca işaret ve dolgu içindir, üstüne
/// küçük metin yazılmaz.
class AppPalette {
  const AppPalette._();

  // ── Marka: derin botanik erik ──
  static const plum900 = Color(0xFF3A022C); // en koyu; degradenin başı
  static const plum700 = Color(0xFF541942); // birincil
  static const plum600 = Color(0xFF611846); // degradenin ortası
  static const plum500 = Color(0xFF8B4772);
  static const plum300 = Color(0xFFFFAEDE); // koyu temada marka metni

  // ── İkincil: böğürtlen gülü. Bağlantılar, etkin durumlar. ──
  static const berry600 = Color(0xFFB02751); // metin olarak AA
  static const berry500 = Color(0xFFE04D74); // dolgu, degrade, odak
  static const berry100 = Color(0xFFFFD9DE);

  // ── Akış (regl): canlı çilek gülü ──
  static const rose800 = Color(0xFF9F1239); // açık zeminde gül metin
  static const rose600 = Color(0xFFE11D48);
  static const rose400 = Color(0xFFFB7185);
  static const rose200 = Color(0xFFFBCFE8);
  static const rose100 = Color(0xFFFFE4E6);
  static const rose50 = Color(0xFFFFF0F6);

  /// Tahmini doğurgan dönem işareti (nokta, kare). Üstüne metin yazılmaz.
  static const pink400 = Color(0xFFF472B6);

  // ── Vurgu: sıcak mercan. Tek vurgu; her yere serpiştirilmez. ──
  /// Beyaz metinle 5.2:1 — AA.
  static const clay600 = Color(0xFFC2410C);
  static const clay400 = Color(0xFFF78E69);
  static const clay100 = Color(0xFFFFEDE5);

  // ── Yumurtlama: menekşe. Gülden net ayrılsın diye ayrı aile. ──
  static const iris700 = Color(0xFF5B21B6);
  static const iris500 = Color(0xFF7C3AED);
  static const iris100 = Color(0xFFEDE9FE);

  // ── Evreler ──
  static const sage600 = Color(0xFF059669); // foliküler
  static const amber600 = Color(0xFFD97706); // luteal
  static const orchid400 = Color(0xFFC084AB); // hormonal korunma

  // ── Nötr: sıcak, hafif pembe kum. Soğuk gri değil. ──
  static const sand50 = Color(0xFFFBF7F6); // zemin
  static const sand100 = Color(0xFFFAF0F4); // ikincil yüzey
  static const sand200 = Color(0xFFEEDEE5); // kenarlık

  static const ink900 = Color(0xFF21191E);
  static const ink600 = Color(0xFF51434A);
  static const ink400 = Color(0xFF83737A);

  // ── Koyu tema ──
  static const night900 = Color(0xFF150E12);
  static const night800 = Color(0xFF20171C);
  static const night700 = Color(0xFF2C2027);
  static const night600 = Color(0xFF3E2F38);

  static const nightInk = Color(0xFFF7E9F0);
  static const nightInkMuted = Color(0xFFCDB8C3);

  // ── Tema çeşitleri ──
  //
  // Her tema yalnızca **marka ailesini** değiştirir; nötrler, akış ve
  // yumurtlama renkleri sabit kalır. Böylece takvim okuması temadan temaya
  // kaymaz — kullanıcı regl rengini her temada aynı yerde görür.
  //
  // Tonlar aynı yöntemle seçildi: beyaz metinle 4.5:1'i geçen bir "700",
  // koyu temada zemine karşı 4.5:1'i geçen bir "300".

  /// Okyanus — soğuk mavi-yeşil.
  static const ocean700 = Color(0xFF1F5F6B);
  static const ocean500 = Color(0xFF2A8C9C);
  static const ocean300 = Color(0xFF8FC4CE);

  /// Orman — derin yeşil.
  static const forest700 = Color(0xFF2E5F3E);
  static const forest500 = Color(0xFF3E8E5E);
  static const forest300 = Color(0xFF9CC7A9);

  /// Gece — grafit; renk istemeyen kullanıcı için.
  static const graphite700 = Color(0xFF3F4550);
  static const graphite500 = Color(0xFF5A6273);
  static const graphite300 = Color(0xFFB6BCC7);

  // ── Durum ──
  static const success = Color(0xFF047857);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFBA1A1A);
}
