import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color primaryLight = Color(0xFF551B26); // #551b26
  static const Color backgroundLight = Color(0xFFF8F6F6); // #f8f6f6
  static const Color secondaryPinkLight = Color(0xFFF9F1F2); // #f9f1f2
  static const Color textMainLight = Color(0xFF161213); // #161213
  static const Color textMutedLight = Color(0xFF816A6E); // #816a6e

  // Dark Theme Colors
  static const Color primaryDark = Color(
    0xFFFBCFE8,
  ); // pink-200 for dark primary text/icons
  static const Color backgroundDark = Color(0xFF1E1416); // #1e1416
  static const Color secondaryPinkDark = Color(0x33551B26); // primary/20
  static const Color textMainDark = Color(0xFFFFFFFF); // white
  static const Color textMutedDark = Color(0xFF9CA3AF); // gray-400
  static const Color borderDark = Color(0xFF374151); // gray-700
  static const Color surfaceDark = Color(0xFF1F2937); // gray-800

  // Calendar & Flow Colors
  static const Color primaryLightTint = Color(0xFFFDF2F4); // primary-light
  static const Color flowHeavy = Color(0xFF8A2C3C);
  static const Color flowMedium = Color(0xFFB5465A);
  static const Color flowLight = Color(
    0xFFD98A96,
  ); // actually #d98a96 -> 0xFFD98A96
  static const Color fertileLight = Color(0xFFFCECEE);

  // Status Chip Colors
  static const Color moodOrangeText = Color(0xFF9A3412); // orange-800
  static const Color moodOrangeBg = Color(0xFFFFF7ED); // orange-50
  static const Color moodOrangeIcon = Color(0xFFFB923C); // orange-400

  static const Color energyPurpleText = Color(0xFF6B21A8); // purple-800
  static const Color energyPurpleBg = Color(0xFFFAF5FF); // purple-50
  static const Color energyPurpleIcon = Color(0xFFC084FC); // purple-400

  static const Color suggestionTealText = Color(0xFF0D9488); // teal-600
  static const Color suggestionTealBg = Color(0xFFF0FDFA); // teal-50

  // ─────────────────────────────────────────────────────────────
  // Ekranlarda tekrar eden değerler.
  //
  // Bu renkler daha önce onlarca dosyada satır içi hex olarak yazılıyordu;
  // aynı rengin birden çok "sürümü" oluşmuştu (ör. 0xFF1E1415 / 0xFF1E1416).
  // Yeni renk eklerken önce buraya bakın.
  // ─────────────────────────────────────────────────────────────

  /// Alternatif açık tema zemini (bazı ayar ekranları).
  static const Color backgroundLightAlt = Color(0xFFF6F6F8);

  /// Lacivert tonlu koyu tema (profil/ayar ekranları).
  static const Color backgroundNavyDark = Color(0xFF101622);
  static const Color surfaceNavyDark = Color(0xFF1A2230);

  /// Sıcak tonlu koyu tema (partner/onboarding ekranları).
  static const Color surfaceWarmDark = Color(0xFF2A1F20);
  static const Color backgroundDeepDark = Color(0xFF1A0C13);

  /// Koyu temada silik metin (sıcak ton).
  static const Color textMutedWarmDark = Color(0xFFD0C0C2);

  /// Marka kırmızısının koyu tonu (partner ekranları).
  static const Color primaryDeep = Color(0xFF541C24);

  // Slate ölçeği — metin ve kenarlıklar
  static const Color textMainSlate = Color(0xFF0F172A); // slate-900
  static const Color textMutedSlate = Color(0xFF64748B); // slate-500
  static const Color textMutedSlateDark = Color(0xFF94A3B8); // slate-400
  static const Color borderSlateLight = Color(0xFFF1F5F9); // slate-100
  static const Color borderSlate = Color(0xFFE2E8F0); // slate-200
  static const Color borderSlateDark = Color(0xFF334155); // slate-700
  static const Color borderGrayLight = Color(0xFFF3F4F6); // gray-100

  // Vurgu renkleri
  static const Color accentAmber = Color(0xFFD97706); // amber-600
  static const Color accentGreen = Color(0xFF10B981); // emerald-500
  static const Color accentRose = Color(0xFFE11D48); // rose-600
}
