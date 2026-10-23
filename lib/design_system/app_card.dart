import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

/// Uygulamanın standart kartı.
///
/// Kart görünümü otuzdan fazla yerde elle kuruluyordu ve her biri kendi
/// yarıçapını, kenarlığını ve gölgesini seçiyordu. Sonuç: ekranlar arasında
/// tutarsız derinlik, ve alan sınırları görünmeyecek kadar soluk.
///
/// Ölçülen değerler (açık tema, beyaz yüzey üstünde):
///   eski kenarlık `t.border` → 1.35:1  — pratikte görünmüyordu
///   eski gölge %2 opaklık          — hiçbir şey yapmıyordu
///
/// Ekim 2026 yenilemesi: beyaz kart, 24 pt köşe, neredeyse görünmez pembe
/// kenar ve erik tonlu yayvan gölge. Gölge iki katman: yere değdiği yerde
/// keskin, yukarıda yayvan.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Kartın kenar yuvarlaklığı. Bölümlü kartlarda da aynı değer kullanılsın
  /// diye dışarı açık.
  static const double radius = 24;

  static bool _isLight(AppTokens t) => t.background.computeLuminance() > 0.5;

  /// Kart kenarlığı — beyaz kartı sıcak zeminden ayıran çok açık pembe.
  /// Asıl ayrımı gölge yapıyor (bkz. [shadow]).
  static Color borderColor(AppTokens t) =>
      _isLight(t) ? const Color(0xFFF5E4EB) : t.border;

  /// Bölümleri ayıran çizgi.
  static Color dividerColor(AppTokens t) =>
      _isLight(t) ? const Color(0xFFF0DEE6) : t.border;

  /// Erik tonlu ortam gölgesi: kart, gri bir boşlukta yüzmek yerine sıcak
  /// bir ışıkta duruyor gibi görünsün.
  static List<BoxShadow> shadow([AppTokens? t]) {
    final dark = t != null && !_isLight(t);
    return [
      BoxShadow(
        color: dark
            ? Colors.black.withAlpha(60)
            : AppPalette.plum700.withAlpha(15),
        blurRadius: 36,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: dark
            ? Colors.black.withAlpha(30)
            : AppPalette.plum700.withAlpha(6),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static BoxDecoration decoration(AppTokens t) => BoxDecoration(
    color: t.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor(t)),
    boxShadow: shadow(t),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final body = Container(
      decoration: decoration(t),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return body;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}

/// İki bölümden oluşan kart: üstte ana içerik, altta bir ton ayrışan şerit.
///
/// Şeridin tint'i tek başına yetmiyor (beyaza karşı 1.17:1); bölümleri keskin
/// bir çizgi ayırıyor.
class AppSectionedCard extends StatelessWidget {
  const AppSectionedCard({
    super.key,
    required this.header,
    this.footer,
    this.headerPadding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.footerPadding = const EdgeInsets.symmetric(horizontal: 20),
    this.onTap,
  });

  final Widget header;
  final Widget? footer;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry footerPadding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final body = Container(
      decoration: AppCard.decoration(t),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: headerPadding, child: header),
          if (footer != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: t.surfaceAlt,
                border: Border(top: BorderSide(color: AppCard.dividerColor(t))),
              ),
              padding: footerPadding,
              child: footer,
            ),
        ],
      ),
    );

    if (onTap == null) return body;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}
