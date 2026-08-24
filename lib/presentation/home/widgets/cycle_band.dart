import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import '../../../domain/models/cycle_info.dart';

/// Döngüyü yatay bir şerit olarak çizer.
///
/// Buradaki alternatif, ortada büyük bir daire ve içinde gün sayısı olan
/// düzendi. O halka bu kategorideki hemen her uygulamada aynı: tanıdık ama
/// ayırt edici değil, ve tek bir sayıdan başka bir şey söylemiyor.
///
/// Şerit döngünün **tamamını** aynı anda gösteriyor: evrelerin nerede
/// başlayıp bittiği, bugünün o yay içindeki yeri, kalan mesafe. Gelgit
/// cetveli ya da almanak sayfası gibi okunuyor.
class CycleBand extends StatelessWidget {
  const CycleBand({super.key, required this.info, required this.currentDay});

  final CycleInfo info;
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final length = info.averageCycleLength;

    // Renkler burada, boyayıcıya girmeden hesaplanıyor. Boyayıcı bir kapanış
    // (closure) alsaydı `shouldRepaint` onu karşılaştıramaz ve evre renkleri
    // değiştiğinde — gün sayısı aynı kaldığı için — tuval yeniden çizilmezdi.
    // Hormonal doğum kontrolü ayarı değiştirildiğinde tam bu oluyordu:
    // şerit ancak uygulama yeniden başlatılınca güncelleniyordu.
    final colors = [
      for (var day = 1; day <= length; day++) info.getPhaseForDay(day).color(t),
    ];

    return SizedBox(
      height: 76,
      child: CustomPaint(
        painter: _BandPainter(
          colors: colors,
          currentDay: currentDay,
          baseline: t.border,
          marker: t.text,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.colors,
    required this.currentDay,
    required this.baseline,
    required this.marker,
  });

  /// Gün başına renk; sırayla 1. günden son güne.
  final List<Color> colors;
  final int currentDay;
  final Color baseline;
  final Color marker;

  int get length => colors.length;

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0) return;

    const gap = 3.0;
    final slot = size.width / length;
    final barWidth = (slot - gap).clamp(2.0, 14.0);

    // Taban çizgisi: şeridin bir cetvel olduğunu belli eder.
    final base = Paint()
      ..color = baseline
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 18),
      Offset(size.width, size.height - 18),
      base,
    );

    for (var day = 1; day <= length; day++) {
      final isToday = day == currentDay;
      final isPast = day < currentDay;

      // Geçmiş günler soluk: bakış bugüne ve önündeki yola gitsin.
      final color = colors[day - 1];
      final paint = Paint()
        ..color = isPast ? color.withAlpha(90) : color
        ..style = PaintingStyle.fill;

      // Bugün en uzun çubuk; kalanlar sabit ve daha kısa. Yükseklik veri
      // taşımıyor, yalnızca bugünü işaretliyor — yoksa okuyan kişi
      // olmayan bir ölçüyü okumaya çalışır.
      final height = isToday ? 44.0 : 26.0;
      final left = day * slot - slot + gap / 2;
      final top = size.height - 18 - height;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, height),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );

      if (isToday) {
        // Bugünün altına küçük bir işaret.
        final dot = Paint()..color = marker;
        canvas.drawCircle(
          Offset(left + barWidth / 2, size.height - 9),
          2.5,
          dot,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.currentDay != currentDay ||
      old.baseline != baseline ||
      old.marker != marker ||
      !listEquals(old.colors, colors);
}
