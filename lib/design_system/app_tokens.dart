import 'package:flutter/material.dart';
import 'app_flavor.dart';
import 'app_palette.dart';

/// Role göre renkler.
///
/// Ekranlar `isDark ? A : B` diye kendi kararını vermek yerine buradan okur.
/// Önceki kodda sunum katmanında ~970 sabit renk vardı (yalnız `Colors.grey`
/// 135 yerde); palet değiştirmek otuz dosyaya tek tek dokunmayı
/// gerektiriyordu. Rol katmanı bunu tek yere indirir.
///
/// Kullanım: `final t = context.tokens;` → `t.surface`, `t.textMuted`…
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  /// Ekranın en arka zemini.
  final Color background;

  /// Kartlar, sayfalar, listeler.
  final Color surface;

  /// Zeminden bir kademe ayrışan yüzey (seçili satır, iç kutu).
  final Color surfaceAlt;

  /// Marka renginin çok açık tonu — rozetler, seçili sekme zemini.
  final Color brandTint;

  /// Ana metin.
  final Color text;

  /// İkincil metin, alt başlık.
  final Color textMuted;

  /// Üçüncül metin, ipucu.
  final Color textFaint;

  /// Ayırıcı ve kenarlık.
  final Color border;

  /// Vurgu (tek vurgu rengi — CTA, öne çıkarma).
  final Color accent;
  final Color accentTint;

  /// Akış (regl) rengi ve tonları.
  final Color flow;
  final Color flowSoft;
  final Color flowTint;

  /// Yumurtlama.
  final Color ovulation;
  final Color ovulationTint;

  /// Doğurganlık penceresi işareti.
  ///
  /// `flowTint`ten ayrı: o, hücrenin altına serilen bir zemin tülü ve koyu
  /// temada zeminle 1.35:1 kontrasta düşüyor. Açıklama satırındaki nokta ise
  /// **ön planda** duruyor, görünmesi gerekiyor. İkisini aynı sayması
  /// doğurganlık noktasını koyu temada kaybetmişti.
  final Color fertile;

  /// Döngü fazları.
  ///
  /// Menstrüasyon [flow], yumurtlama [ovulation] renklerini kullanır —
  /// takvimdeki açıklama satırıyla aynı olsun diye. Kalan iki faz için
  /// ayrı rol gerekiyor.
  ///
  /// Bu dört renk eskiden ana ekranda sabit yazılıydı: yumurtlama açık mavi
  /// (#4FC3F7), foliküler yeşil, luteal turuncu. Hiçbiri palete ait değildi
  /// ve halka ekranın ortasında yabancı duruyordu.
  final Color phaseFollicular;
  final Color phaseLuteal;

  final Color success;
  final Color warning;
  final Color danger;

  const AppTokens({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.brandTint,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.accent,
    required this.accentTint,
    required this.flow,
    required this.flowSoft,
    required this.flowTint,
    required this.ovulation,
    required this.ovulationTint,
    required this.fertile,
    required this.phaseFollicular,
    required this.phaseLuteal,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// Seçili çeşide göre rol renkleri.
  ///
  /// Yalnızca marka rengi ve tonu değişir; nötrler, akış ve yumurtlama
  /// sabit kalır (bkz. [AppFlavor]).
  static AppTokens of(AppFlavor flavor, Brightness brightness) {
    final base = brightness == Brightness.light ? light : dark;
    return base.copyWith(
      brandTint: brightness == Brightness.light ? flavor.tint : base.brandTint,
    );
  }

  static const light = AppTokens(
    background: AppPalette.sand50,
    surface: Colors.white,
    surfaceAlt: AppPalette.sand100,
    brandTint: AppPalette.rose50,
    text: AppPalette.ink900,
    textMuted: AppPalette.ink600,
    textFaint: AppPalette.ink400,
    border: AppPalette.sand200,
    accent: AppPalette.clay600,
    accentTint: AppPalette.clay100,
    flow: AppPalette.rose600,
    flowSoft: AppPalette.rose400,
    flowTint: AppPalette.rose200,
    ovulation: AppPalette.iris500,
    ovulationTint: AppPalette.iris100,
    fertile: AppPalette.rose200,
    phaseFollicular: AppPalette.success,
    phaseLuteal: AppPalette.clay600,
    success: AppPalette.success,
    warning: AppPalette.warning,
    danger: AppPalette.danger,
  );

  static const dark = AppTokens(
    background: AppPalette.night900,
    surface: AppPalette.night800,
    surfaceAlt: AppPalette.night700,
    brandTint: AppPalette.night700,
    text: AppPalette.nightInk,
    textMuted: AppPalette.nightInkMuted,
    textFaint: Color(0xFF8A7B85),
    border: AppPalette.night600,
    accent: AppPalette.clay400,
    accentTint: Color(0xFF3D2A22),
    flow: AppPalette.rose400,
    flowSoft: AppPalette.rose600,
    flowTint: Color(0xFF43222C),
    ovulation: Color(0xFF9E85C6),
    ovulationTint: Color(0xFF2E2540),
    // Açık pembe her iki zeminde de okunuyor; rol rengi ikisinde de aynı.
    fertile: AppPalette.rose200,
    phaseFollicular: Color(0xFF5FB3A1),
    phaseLuteal: AppPalette.clay400,
    success: Color(0xFF5FB3A1),
    warning: Color(0xFFD9A845),
    danger: Color(0xFFD4736D),
  );

  @override
  AppTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? brandTint,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? border,
    Color? accent,
    Color? accentTint,
    Color? flow,
    Color? flowSoft,
    Color? flowTint,
    Color? ovulation,
    Color? ovulationTint,
    Color? fertile,
    Color? phaseFollicular,
    Color? phaseLuteal,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return AppTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      brandTint: brandTint ?? this.brandTint,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentTint: accentTint ?? this.accentTint,
      flow: flow ?? this.flow,
      flowSoft: flowSoft ?? this.flowSoft,
      flowTint: flowTint ?? this.flowTint,
      ovulation: ovulation ?? this.ovulation,
      ovulationTint: ovulationTint ?? this.ovulationTint,
      fertile: fertile ?? this.fertile,
      phaseFollicular: phaseFollicular ?? this.phaseFollicular,
      phaseLuteal: phaseLuteal ?? this.phaseLuteal,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      brandTint: mix(brandTint, other.brandTint),
      text: mix(text, other.text),
      textMuted: mix(textMuted, other.textMuted),
      textFaint: mix(textFaint, other.textFaint),
      border: mix(border, other.border),
      accent: mix(accent, other.accent),
      accentTint: mix(accentTint, other.accentTint),
      flow: mix(flow, other.flow),
      flowSoft: mix(flowSoft, other.flowSoft),
      flowTint: mix(flowTint, other.flowTint),
      ovulation: mix(ovulation, other.ovulation),
      ovulationTint: mix(ovulationTint, other.ovulationTint),
      fertile: mix(fertile, other.fertile),
      phaseFollicular: mix(phaseFollicular, other.phaseFollicular),
      phaseLuteal: mix(phaseLuteal, other.phaseLuteal),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
    );
  }
}

/// Ölçek değerleri.
///
/// Boşluk ve köşe yarıçapı da göz kararı bırakılmasın: 4'ün katları,
/// yarıçaplar tek bir merdivende.
class AppSpacing {
  const AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  const AppRadius._();
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

extension AppTokensContext on BuildContext {
  /// Rol renklerini okur.
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
