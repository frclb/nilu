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
  const CycleRing({super.key, required this.info, required this.currentDay});

  final CycleInfo info;
  final int currentDay;

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

    return Center(
      child: SizedBox(
        width: 196,
        height: 196,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(196),
              painter: _RingPainter(
                colors: colors,
                currentDay: currentDay,
                marker: t.text,
              ),
            ),
            // Merkezde döngünün uzunluğu: halkanın neyi temsil ettiğini
            // söyleyen tek bilgi, ekranda başka yerde yok.
            Text(
              context.tr('home_ring_cycle_length', params: {'n': '$length'}),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 12,
                height: 1.4,
                color: t.textMuted,
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
    required this.marker,
  });

  final List<Color> colors;
  final int currentDay;
  final Color marker;

  int get length => colors.length;

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0) return;

    const stroke = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final sweep = 2 * math.pi / length;
    // Parçalar arasında ince boşluk: günler sayılabilsin, tek bir halka gibi
    // görünmesin.
    final gap = sweep * 0.14;

    for (var day = 1; day <= length; day++) {
      final isToday = day == currentDay;
      final isPast = day < currentDay;
      final color = colors[day - 1];

      final paint = Paint()
        ..color = isPast ? color.withAlpha(90) : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isToday ? stroke + 5 : stroke
        ..strokeCap = StrokeCap.butt;

      // Saat 12'den başla.
      final start = -math.pi / 2 + (day - 1) * sweep + gap / 2;
      canvas.drawArc(rect, start, sweep - gap, false, paint);

      if (isToday) {
        // Bugünün dışına küçük bir işaret: hangi parçanın bugün olduğu
        // kalınlık farkından bağımsız olarak da okunsun.
        final mid = start + (sweep - gap) / 2;
        final dotAt = Offset(
          center.dx + (radius + stroke / 2 + 8) * math.cos(mid),
          center.dy + (radius + stroke / 2 + 8) * math.sin(mid),
        );
        canvas.drawCircle(dotAt, 3, Paint()..color = marker);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.currentDay != currentDay ||
      old.marker != marker ||
      !listEquals(old.colors, colors);
}
