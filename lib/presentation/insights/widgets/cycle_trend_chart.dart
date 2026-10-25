import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/date_names.dart';
import '../../../domain/services/insights_service.dart';

/// Gözlenmiş döngü uzunluklarının sütun grafiği.
///
/// Eskiden burada sabit bir eğri çizen `CustomPaint` vardı (kodda yorumu
/// "Area Chart Mockup" idi) ve X ekseni de sabit "Oca,Şub,Mar,Nis,May,Haz"
/// etiketleriydi — kullanıcının verisiyle hiçbir ilgisi yoktu.
///
/// Artık her sütun, kullanıcının işaretlediği iki ardışık regl başlangıcı
/// arasındaki gerçek gün sayısıdır. En son döngü ve en uzun döngü
/// vurgulanıyor; kesikli çizgi ortalama.
class CycleTrendChart extends StatelessWidget {
  final List<CycleLengthPoint> points;

  /// Kesikli ortalama çizgisi. Tek döngüde çizilmiyor: ortalama, döngünün
  /// kendisi.
  final int? average;

  const CycleTrendChart({super.key, required this.points, this.average});

  /// Sütunların toplam yüksekliği (değer ve ay etiketleri hariç).
  static const double _plotHeight = 150;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    if (points.isEmpty) return const SizedBox.shrink();

    // Ölçek tabanı sıfır değil: döngüler 26–32 gün aralığında toplandığı için
    // sıfırdan başlayan bir eksende bütün sütunlar aynı boyda görünür ve fark
    // okunmaz olur. Taban en kısa döngünün 4 gün altı.
    var shortest = points.first.lengthInDays;
    var longest = points.first.lengthInDays;
    for (final p in points) {
      if (p.lengthInDays < shortest) shortest = p.lengthInDays;
      if (p.lengthInDays > longest) longest = p.lengthInDays;
    }
    final base = shortest - 4;
    final span = (longest + 1 - base).clamp(1, 1000);

    double factorOf(int days) => points.length == 1
        // Tek döngü varsa oran 1.0 çıkıp sütun tavana yapışır; 0.75 ile
        // ölçeksiz ama dengeli görünür.
        ? 0.75
        : ((days - base) / span).clamp(0.08, 1.0);

    final avg = average;
    final showAverage = avg != null && points.length > 1;
    final scaler = MediaQuery.textScalerOf(context);
    // Değer etiketinin yüksekliği: satır yüksekliği sabit (1.2) verildiği
    // için yazı ölçeğiyle birlikte hesaplanabiliyor.
    // Bir punto pay: yuvarlama farkı sütunu taşırmasın.
    final valueHeight = scaler.scale(12) * 1.2 + 6 + 1;
    final lastIndex = points.length - 1;

    return Semantics(
      container: true,
      child: Column(
        children: [
          SizedBox(
            height: _plotHeight + valueHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (showAverage)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _plotHeight * factorOf(avg),
                    child: ExcludeSemantics(
                      child: CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: _DashPainter(t.secondary.withAlpha(110)),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < points.length; i++)
                        Expanded(
                          child: _Bar(
                            gap: points.length > 8 ? 1.5 : 5,
                            height:
                                _plotHeight * factorOf(points[i].lengthInDays),
                            value: points[i].lengthInDays,
                            emphasis: i == lastIndex
                                ? _Emphasis.latest
                                : (points[i].lengthInDays == longest &&
                                          longest != shortest
                                      ? _Emphasis.longest
                                      : _Emphasis.none),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < points.length; i++)
                Expanded(
                  child: Text(
                    context.capitalized(
                      context.shortMonthName(points[i].startDate.month),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: i == lastIndex
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: i == lastIndex
                          ? theme.colorScheme.primary
                          : t.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Emphasis { none, latest, longest }

class _Bar extends StatelessWidget {
  final double height;
  final int value;
  final _Emphasis emphasis;

  /// Sütunun iki yanındaki boşluk; çok döngüde daralıyor.
  final double gap;

  const _Bar({
    required this.height,
    required this.value,
    required this.emphasis,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    final (Color bottom, Color top, Color label) = switch (emphasis) {
      _Emphasis.latest => (primary, t.secondary.withAlpha(150), primary),
      _Emphasis.longest => (
        t.secondary,
        t.secondary.withAlpha(120),
        t.secondary,
      ),
      _Emphasis.none => (
        primary.withAlpha(185),
        t.secondary.withAlpha(85),
        t.textMuted,
      ),
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gap),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value',
            maxLines: 1,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              height: 1.2,
              fontWeight: emphasis == _Emphasis.none
                  ? FontWeight.w600
                  : FontWeight.w800,
              color: label,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 34),
            child: Container(
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [bottom, top],
                ),
                boxShadow: emphasis == _Emphasis.longest
                    ? [
                        BoxShadow(
                          color: t.secondary.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ortalama çizgisi.
class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dash, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color;
}
