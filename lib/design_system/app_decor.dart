import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import 'app_palette.dart';
import 'app_tokens.dart';
import 'brand_lotus.dart';

/// "Luminous Editorial Wellness" yenilemesinin ortak parçaları.
///
/// Ekranlar degrade, etiket, simge kutusu ve ışıma gibi süsleri buradan
/// alıyor; her ekran kendi gölgesini ve degradesini yazınca derinlik
/// ekrandan ekrana kayıyordu (bkz. `AppCard`).

/// Markanın degradeleri.
class AppGradients {
  const AppGradients._();

  /// Ana eylem: marka → ikincil (erikte böğürtlen gülü). Yalnızca dolgu;
  /// üstündeki yazı her zaman `onPrimary`.
  static LinearGradient primary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = context.tokens;
    final deep = Color.lerp(scheme.primary, Colors.black, 0.18)!;
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [deep, scheme.primary, t.secondary],
      stops: const [0, 0.45, 1],
    );
  }

  /// Simge ve logo dairesi: marka → ikincil, çapraz.
  static LinearGradient mark(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.primary, context.tokens.secondary],
    );
  }

  /// Sıcak öneri kartı (mercan → şeftali).
  static LinearGradient warm(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const LinearGradient(
        colors: [Color(0xFF2E1E1A), Color(0xFF332019)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF2EB), Color(0xFFFEEAE1), Color(0xFFFDE5DA)],
    );
  }

  /// Mercan eylem düğmesi ("Başla"). Beyaz yazıyla AA.
  static const LinearGradient coral = LinearGradient(
    colors: [AppPalette.clay600, Color(0xFFEA580C)],
  );

  /// Gül → menekşe tülü: partner ve yakınlık kartları.
  static LinearGradient blush(BuildContext context) {
    final t = context.tokens;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [t.brandTint, t.ovulationTint.withAlpha(180)],
    );
  }
}

/// Erik tonlu gölgeler.
class AppShadows {
  const AppShadows._();

  /// Yüzen öğeler: ana düğme, alt menü, "+" düğmesi.
  static List<BoxShadow> floating(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = dark ? Colors.black : Theme.of(context).colorScheme.primary;
    return [
      BoxShadow(
        color: c.withAlpha(dark ? 90 : 64),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Hafif: küçük kutular, etiketler.
  static List<BoxShadow> soft(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (dark ? Colors.black : AppPalette.plum700).withAlpha(
          dark ? 50 : 10,
        ),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

/// Degrade dolgulu ana eylem düğmesi.
///
/// `FilledButton` temada düz renk; degrade yalnızca ekranın **bir** ana
/// eylemi için (ör. "Reglim başladı", "Kaydet"). Her düğme degrade olursa
/// hiçbiri öne çıkmıyor.
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.height = 54,
    this.radius = AppRadius.md,
    this.gradient,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Sürüyor: düğme kilitli, simgenin yerinde dönen gösterge.
  final bool busy;
  final double height;
  final double radius;

  /// Verilmezse markanın ana degradesi.
  final Gradient? gradient;

  /// Tam genişlik mi, içeriği kadar mı.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !busy;
    final fg = scheme.onPrimary;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: fg),
        if (busy || icon != null) const SizedBox(width: 10),
        Flexible(
          // İki satıra kadar sarıyor: Almanca "Meine Periode hat begonnen"
          // 1.5× yazıda dar telefonda tek satıra sığmayıp "…" ile
          // kesiliyordu. Düğme yüksekliği içeriğe göre büyüyor.
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled || busy ? 1 : 0.45,
        child: Container(
          constraints: BoxConstraints(minHeight: height),
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: gradient ?? AppGradients.primary(context),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: enabled ? AppShadows.floating(context) : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                // `heightFactor: 1`: ortalayıcı içerik kadar yükseliyor.
                // Olmadan, yüksekliği sınırlı bir yerde (iskeletin alt
                // çubuğu) bütün alanı kaplıyor ve düğme ekranı örtüyordu.
                child: Center(widthFactor: 1, heightFactor: 1, child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo: degrade dairenin içinde beyaz lotus.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.mark(context),
        boxShadow: AppShadows.soft(context),
      ),
      child: const BrandLotus(color: Colors.white, sideOpacity: 0.8),
    );
  }
}

/// Sekme köklerinin üst çubuğu: solda logo ve "Nilu", sağda [trailing].
class AppBrandBar extends StatelessWidget {
  const AppBrandBar({super.key, this.title = 'Nilu', this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const AppLogoMark(),
            const SizedBox(width: 8),
            // Başlık esnek: uzun başlık (ör. Fransızca "Statut du
            // partenaire") büyük yazıda dar telefonda taşmak yerine kısalıyor.
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 23,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Bölüm etiketi: küçük, büyük harf, aralıklı ("SIRADA", "HESAP").
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      // Dile göre büyütme (Türkçede i → İ).
      context.upper(text),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: color ?? context.tokens.textMuted,
      ),
    );
  }
}

/// Küçük hap etiket: rozet, sayaç, evre adı.
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.background,
    this.foreground,
    this.icon,
    this.dotColor,
    this.border,
  });

  final String label;
  final Color? background;
  final Color? foreground;
  final IconData? icon;

  /// Başta küçük renkli nokta (ör. evre rengi).
  final Color? dotColor;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = foreground ?? t.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? t.secondaryTint.withAlpha(140),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simge kutusu: yuvarlatılmış kare ya da daire; degrade ya da tül zemin.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.size = 40,
    this.color,
    this.background,
    this.gradient,
    this.circle = false,
  });

  final IconData icon;
  final double size;

  /// Simgenin rengi. Degradede varsayılan beyaz.
  final Color? color;

  /// Tül zemin. [gradient] verilirse yok sayılır.
  final Color? background;
  final Gradient? gradient;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.32),
        gradient: gradient,
        color: gradient == null ? (background ?? t.brandTint) : null,
        boxShadow: gradient == null ? null : AppShadows.soft(context),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        // Degradenin üstünde `onPrimary`: koyu temada marka açık pembe ve
        // beyaz simge üstünde okunmuyordu.
        color: color ?? (gradient != null ? scheme.onPrimary : scheme.primary),
      ),
    );
  }
}

/// Sayfanın üstüne düşen yumuşak renk ışımaları (gül, kehribar, menekşe).
///
/// Bulanıklık filtresi yerine radyal degrade: kaydırırken her karede
/// yeniden bulanıklaştırmak pahalı, degrade aynı izlenimi bedavaya veriyor.
/// Yalnızca açık temada; koyu temada parlama göz yoruyor.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) return child;
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -60,
          right: -60,
          height: 420,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.3),
                  radius: 0.9,
                  colors: [
                    AppPalette.rose200.withAlpha(90),
                    const Color(0xFFFDE8D0).withAlpha(70),
                    AppPalette.iris100.withAlpha(40),
                    AppPalette.sand50.withAlpha(0),
                  ],
                  stops: const [0, 0.35, 0.6, 1],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
