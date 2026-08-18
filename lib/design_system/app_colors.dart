import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Eski renk adlarının yeni palete köprüsü.
///
/// Bu isimler otuza yakın ekran dosyasından okunuyor. Palet yenilenirken iki
/// yol vardı: her dosyaya tek tek dokunmak, ya da isimleri yerinde bırakıp
/// **değerlerini** yeni palete yönlendirmek. İkincisi seçildi — tek dosyayla
/// tüm uygulama boyandı ve ekranlar aşamalı olarak `context.tokens`'a
/// taşınabiliyor.
///
/// Yeni kod bunu **kullanmamalı**; rol tabanlı `AppTokens` kullanın:
/// `context.tokens.surface`, `context.tokens.textMuted`…
///
/// Eskiden buradaki tonlar üç ayrı kaynaktan geliyordu — marka kırmızısı,
/// Tailwind'in slate/gray ölçeği ve turuncu/mor/teal çip renkleri. Üçü
/// birbirine ait değildi; ekranlar da hangisini kullanacağını dosya bazında
/// seçiyordu. Hepsi tek bir sıcak paletle değiştirildi.
class AppColors {
  const AppColors._();

  // ── Açık tema ──
  static const Color primaryLight = AppPalette.plum700;
  static const Color backgroundLight = AppPalette.sand50;
  static const Color secondaryPinkLight = AppPalette.rose50;
  static const Color textMainLight = AppPalette.ink900;
  static const Color textMutedLight = AppPalette.ink600;

  // ── Koyu tema ──
  static const Color primaryDark = AppPalette.plum300;
  static const Color backgroundDark = AppPalette.night900;
  static const Color secondaryPinkDark = AppPalette.night700;
  static const Color textMainDark = AppPalette.nightInk;
  static const Color textMutedDark = AppPalette.nightInkMuted;
  static const Color borderDark = AppPalette.night600;
  static const Color surfaceDark = AppPalette.night800;

  // ── Takvim ve akış ──
  static const Color primaryLightTint = AppPalette.rose50;
  static const Color flowHeavy = AppPalette.plum700;
  static const Color flowMedium = AppPalette.rose600;
  static const Color flowLight = AppPalette.rose400;
  static const Color fertileLight = AppPalette.rose200;

  // ── Çipler ──
  //
  // Turuncu/mor/teal Tailwind varsayılanlarıydı ve palete ait değillerdi.
  // Ruh hâli kil, enerji mor (yumurtlamayla aynı aile), öneri yeşil oldu.
  static const Color moodOrangeText = AppPalette.clay600;
  static const Color moodOrangeBg = AppPalette.clay100;
  static const Color moodOrangeIcon = AppPalette.clay400;

  static const Color energyPurpleText = Color(0xFF5B4483);
  static const Color energyPurpleBg = AppPalette.iris100;
  static const Color energyPurpleIcon = AppPalette.iris500;

  static const Color suggestionTealText = AppPalette.success;
  static const Color suggestionTealBg = Color(0xFFE6F2EF);

  // ── Yüzeyler ──
  static const Color backgroundLightAlt = AppPalette.sand100;
  static const Color backgroundNavyDark = AppPalette.night900;
  static const Color surfaceNavyDark = AppPalette.night800;
  static const Color surfaceWarmDark = AppPalette.night800;
  static const Color backgroundDeepDark = AppPalette.night900;
  static const Color textMutedWarmDark = AppPalette.nightInkMuted;
  static const Color primaryDeep = AppPalette.plum900;

  // ── Metin ve kenarlık ──
  //
  // "Slate" adları Tailwind'den kalma; değerleri artık sıcak kum ölçeği.
  static const Color textMainSlate = AppPalette.ink900;
  static const Color textMutedSlate = AppPalette.ink600;
  static const Color textMutedSlateDark = AppPalette.nightInkMuted;
  static const Color borderSlateLight = AppPalette.sand200;
  static const Color borderSlate = AppPalette.sand200;
  static const Color borderSlateDark = AppPalette.night600;
  static const Color borderGrayLight = AppPalette.sand200;

  // ── Durum ──
  static const Color accentAmber = AppPalette.warning;
  static const Color accentGreen = AppPalette.success;
  static const Color accentRose = AppPalette.danger;
}
