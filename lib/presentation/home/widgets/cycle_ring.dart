import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../localization/app_localizations.dart';

/// Döngüyü halka olarak çizer: her gün bir yay parçası.
///
/// Halkanın içinde gün sayısı **yok**. Bu kategorideki uygulamalarda merkezdeki
/// sayı tek başına duruyor ve okumak için onun bir döngü günü olduğunu bilmek
/// gerekiyor. Burada cevabı üstteki cümle veriyor; halka yalnızca döngünün
/// şeklini gösteriyor — evrelerin nerede başlayıp bittiğini ve bugünün o yay
/// üzerindeki yerini.
class CycleRing extends StatelessWidget {
  const CycleRing({
    super.key,
    required this.info,
    required this.currentDay,
    required this.center,
  });

  final CycleInfo info;
  final int currentDay;

  /// Halkanın ortasında duran içerik.
  ///
  /// Başlık ve halka önce ayrı bloklardı; ikisi ayrı ayrı dikkat çekiyor ve
  /// aradaki boşluk kartı seyrek gösteriyordu. Tek bir odak nesnesi olarak
  /// daha derli toplu duruyor.
  final Widget center;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final length = info.averageCycleLength;

    // Renkler boyayıcıya girmeden hesaplanıyor: bir kapanış geçirilseydi
    // `shouldRepaint` onu karşılaştıramaz ve evre renkleri değişip gün sayısı
    // aynı kaldığında halka yeniden çizilmezdi.
    final colors = [
      for (var day = 1; day <= length; day++) info.getPhaseForDay(day).color(t),
    ];

    final phaseColor = info.currentPhase.color(t);

    return Center(
      child: SizedBox(
        width: 232,
        height: 232,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Evre renginde çok hafif bir hâle: halka düz zeminde yüzer gibi
            // duruyordu, bu onu yere oturtuyor.
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [phaseColor.withAlpha(20), phaseColor.withAlpha(0)],
                ),
              ),
            ),
            CustomPaint(
              size: const Size.square(232),
              painter: _RingPainter(
                colors: colors,
                currentDay: currentDay,
                track: t.border,
                marker: t.surface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  center,
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'home_ring_cycle_length',
                      params: {'n': '$length'},
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.colors,
    required this.currentDay,
    required this.track,
    required this.marker,
  });

  final List<Color> colors;
  final int currentDay;

  /// Parçaların altındaki ince iz: halka soluk günlerde de tam bir daire
  /// olarak okunsun.
  final Color track;

  /// Bugün işaretinin iç rengi.
  final Color marker;

  int get length => colors.length;

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0) return;

    const stroke = 11.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Altta tam bir halka izi.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final sweep = 2 * math.pi / length;
    // Parçalar arasında boşluk: günler sayılabilsin, tek bir dolu halka gibi
    // görünmesin. Yuvarlak uçlar boşluğun bir kısmını yiyor; dar bırakınca
    // gelecek günler bitişip geçmiş günler ayrık kalıyordu — aynı halkada iki
    // farklı görüntü.
    final gap = sweep * 0.42;

    for (var day = 1; day <= length; day++) {
      final isToday = day == currentDay;
      final isPast = day < currentDay;
      final color = colors[day - 1];

      final paint = Paint()
        ..color = isPast ? color.withAlpha(80) : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        // Yuvarlak uç: kesik uçlar halkayı bir barkod gibi gösteriyordu.
        ..strokeCap = StrokeCap.round;

      // Saat 12'den başla.
      final start = -math.pi / 2 + (day - 1) * sweep + gap / 2;
      canvas.drawArc(rect, start, sweep - gap, false, paint);

      if (isToday) {
        // Bugün halkanın üstünde duran dolu bir nokta. Önceden parçayı
        // kalınlaştırıyordum; kalınlık içe ve dışa birden büyüyüp halkanın
        // temiz kenarlarını bozuyordu.
        final mid = start + (sweep - gap) / 2;
        final at = Offset(
          center.dx + radius * math.cos(mid),
          center.dy + radius * math.sin(mid),
        );
        canvas.drawCircle(at, stroke * 0.95, Paint()..color = color);
        canvas.drawCircle(at, stroke * 0.42, Paint()..color = marker);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.currentDay != currentDay ||
      old.track != track ||
      old.marker != marker ||
      !listEquals(old.colors, colors);
}
