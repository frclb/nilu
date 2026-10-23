import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/date_names.dart';

/// Panoların ana kartı: halka ve çevresindeki bilgi.
///
/// Döngü, gebelik ve lohusalık panosunda aynı kart. Standart karttan
/// ([AppCard]) daha yuvarlak ve içinde iki yumuşak ışıma var: ekranın
/// odağı bu kart, diğer kartlarla aynı ağırlıkta durmasın.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  static const double radius = 30;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    final body = Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppCard.borderColor(t)),
        boxShadow: AppCard.shadow(t),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Sağ üstte sıcak, sol altta menekşe bir ışıma.
          Positioned(
            top: -70,
            right: -70,
            width: 190,
            height: 190,
            child: _Glow(colors: [t.accentTint, t.flowTint]),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            width: 170,
            height: 170,
            child: _Glow(colors: [t.ovulationTint, t.flowTint]),
          ),
          Padding(padding: padding, child: child),
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

class _Glow extends StatelessWidget {
  const _Glow({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              colors[0].withAlpha(150),
              colors[1].withAlpha(70),
              colors[1].withAlpha(0),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}

/// Kartın üst satırı: takvim simgesi ve bugünün tarihi, sağda bir hap.
///
/// Ajandadaki satırlar "4 gün", "23 gün" diyor; bunların neye göre
/// sayıldığı ekranda yazılı olmalı.
class HeroDateLine extends StatelessWidget {
  const HeroDateLine({super.key, required this.date, this.trailing});

  final DateTime date;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    // Büyük yazıda hap alt satıra iniyor; taşmıyor.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 16, color: t.secondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${date.day} ${context.monthName(date.month)} '
                '${date.year} · ${context.weekdayName(date.weekday)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                  color: t.textMuted,
                ),
              ),
            ),
          ],
        ),
        ?trailing,
      ],
    );
  }
}

/// Kartın içindeki bölüm ayracı: kenarlara doğru kaybolan ince çizgi.
class HeroDivider extends StatelessWidget {
  const HeroDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = AppCard.dividerColor(context.tokens);
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [line.withAlpha(0), line, line.withAlpha(0)],
        ),
      ),
    );
  }
}
