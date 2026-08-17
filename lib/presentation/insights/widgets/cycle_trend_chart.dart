import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class CycleTrendChart extends StatelessWidget {
  const CycleTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary; // #551b26

    final monthsRaw = context.tr('insights_months_short');
    final months = monthsRaw.split(',');

    return SizedBox(
      height: 192, // h-48 in tailwind
      width: double.infinity,
      child: Stack(
        children: [
          // Grid lines
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              4,
              (index) => Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE5E7EB),
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Area Chart Mockup
          Positioned.fill(
            child: CustomPaint(
              painter: _ChartPainter(
                primaryColor: primaryColor,
                isDark: isDark,
              ),
            ),
          ),

          // Floating Label for Active Point
          Positioned(
            top: 10,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                context.tr('insights_days', params: {'n': '29'}),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // X-Axis Labels
          Positioned(
            bottom: -20, // Positioned slightly below the chart area
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(months.length, (index) {
                final isLast = index == months.length - 1;
                return Text(
                  months[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                    color: isLast
                        ? (isDark ? Colors.white : primaryColor)
                        : (isDark
                              ? AppColors.textMutedWarmDark
                              : AppColors.textMutedLight),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Color primaryColor;
  final bool isDark;

  _ChartPainter({required this.primaryColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Define points based on SVG path: M0,35 Q16.6,20 33.3,25 T66.6,15 T100,20
    // Translated to a 0-1 coordinate space roughly
    final path = Path();
    path.moveTo(0, h * 0.7);
    path.quadraticBezierTo(w * 0.166, h * 0.4, w * 0.333, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 0.6, w * 0.666, h * 0.3);
    path.quadraticBezierTo(w * 0.833, h * 0.0, w, h * 0.4);

    // Gradient Fill
    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [primaryColor.withAlpha(51), primaryColor.withAlpha(0)],
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    canvas.drawPath(fillPath, paintFill);

    // Stroke
    final strokeColor = isDark ? Colors.white : primaryColor;
    final paintStroke = Paint()
      ..color = strokeColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paintStroke);

    // Points
    final points = [
      Offset(w * 0.166, h * 0.46),
      Offset(w * 0.333, h * 0.5),
      Offset(w * 0.5, h * 0.45), // approx
      Offset(w * 0.666, h * 0.3),
    ];

    final paintPointFill = Paint()
      ..color = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final paintPointStroke = Paint()
      ..color = strokeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var p in points) {
      canvas.drawCircle(p, 4, paintPointFill);
      canvas.drawCircle(p, 4, paintPointStroke);
    }

    // Active Point
    final activePoint = Offset(w * 0.833, h * 0.2); // approx
    final paintActivePointFill = Paint()
      ..color = isDark ? Colors.white : primaryColor;
    final paintActivePointStroke = Paint()
      ..color = isDark ? primaryColor : Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(activePoint, 8, paintActivePointFill);
    canvas.drawCircle(activePoint, 8, paintActivePointStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
