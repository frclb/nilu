import 'package:flutter/material.dart';
import 'app_palette.dart';

/// Uygulama teması (renk çeşidi).
///
/// Yalnızca **marka ailesi** değişir; nötrler, akış (regl) ve yumurtlama
/// renkleri sabit kalır. Takvimin okuması temadan temaya kaymasın diye:
/// kullanıcı regl rengini her temada aynı yerde görmeli.
///
/// Paywall "Özel Temalar" vaat ediyordu ama böyle bir şey hiç yoktu.
enum AppFlavor {
  plum(
    'flavor_plum',
    AppPalette.plum700,
    AppPalette.plum300,
    AppPalette.rose50,
  ),
  ocean(
    'flavor_ocean',
    AppPalette.ocean700,
    AppPalette.ocean300,
    Color(0xFFE8F2F4),
  ),
  forest(
    'flavor_forest',
    AppPalette.forest700,
    AppPalette.forest300,
    Color(0xFFE9F2EC),
  ),
  graphite(
    'flavor_graphite',
    AppPalette.graphite700,
    AppPalette.graphite300,
    Color(0xFFEDEFF2),
  );

  const AppFlavor(this.labelKey, this.brand, this.brandDark, this.tint);

  /// Ayar ekranında görünen adın lokalizasyon anahtarı.
  final String labelKey;

  /// Açık temada marka rengi. Beyaz metinle en az 4.5:1.
  final Color brand;

  /// Koyu temada marka rengi. Gece zeminine karşı en az 4.5:1.
  final Color brandDark;

  /// Markanın çok açık tonu — rozet ve seçili sekme zemini.
  final Color tint;

  /// Varsayılan; ücretsiz kullanıcı bunu görür.
  static const free = AppFlavor.plum;

  /// Premium gerektirenler.
  bool get requiresPremium => this != free;

  static AppFlavor fromName(String? name) =>
      AppFlavor.values.firstWhere((f) => f.name == name, orElse: () => free);
}
