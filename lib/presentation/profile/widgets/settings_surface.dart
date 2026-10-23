import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';

/// Ayar ve belge ekranlarının üst çubuğu: ortada serif başlık.
///
/// Profilin alt ekranları başlığı gövde yazı tipinde ve her biri kendi
/// ölçüsüyle yazıyordu; yenilemede hepsi aynı çubuğu paylaşıyor.
class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({super.key, required this.title, this.onBack});

  final String title;

  /// Verilirse ekranın kendi geri oku; verilmezse `AppBar`ın varsayılanı.
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppBar(
      centerTitle: true,
      leading: onBack == null
          ? null
          : IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: Icon(Icons.arrow_back_ios_new, color: t.text, size: 20),
              onPressed: onBack,
            ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: t.text,
        ),
      ),
    );
  }
}

/// Ayar kartı: uygulamanın standart kartı, üstüne mürekkep çizilebilen bir
/// `Material` katmanıyla.
///
/// `AppCard` yalnızca bir `Container` süslemesi. İçine konan `ListTile` ve
/// `InkWell` mürekkebini en yakın `Material`e — yani kartın **altındaki**
/// sayfaya — çiziyor; dokunma geri bildirimi beyaz kartın arkasında
/// kalıyordu.
class SettingsCard extends StatelessWidget {
  const SettingsCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCard.decoration(context.tokens),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Tül zeminli açıklama kutusu: solda yuvarlak simge, sağda metin.
class SettingsNote extends StatelessWidget {
  const SettingsNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.iconColor,
  });

  final String text;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.lg - 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: icon,
            size: 36,
            circle: true,
            background: t.surface,
            color: iconColor ?? t.secondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              // İlk satır simgenin ortasına hizalı: tek satırlık not da
              // simgeyle aynı hizada dursun.
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  height: 1.45,
                  color: t.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satır başlığı ve alt satırı için ortak yazı biçimleri.
class SettingsText {
  const SettingsText._();

  static TextStyle? title(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: color ?? context.tokens.text,
      );

  static TextStyle? subtitle(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
        fontSize: 13,
        height: 1.4,
        color: color ?? context.tokens.textMuted,
      );
}
