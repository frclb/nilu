import 'package:flutter/material.dart';
import '../../../localization/date_names.dart';
import '../../../design_system/app_colors.dart';
import '../../../domain/services/insights_service.dart';

/// Gözlenmiş döngü uzunluklarının sütun grafiği.
///
/// Eskiden burada sabit bir eğri çizen `CustomPaint` vardı (kodda yorumu
/// "Area Chart Mockup" idi) ve X ekseni de sabit "Oca,Şub,Mar,Nis,May,Haz"
/// etiketleriydi — kullanıcının verisiyle hiçbir ilgisi yoktu.
///
/// Artık her sütun, kullanıcının işaretlediği iki ardışık regl başlangıcı
/// arasındaki gerçek gün sayısıdır.
class CycleTrendChart extends StatelessWidget {
  final List<CycleLengthPoint> points;

  const CycleTrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    final barColor = isDark
        ? theme.colorScheme.primary.withAlpha(200)
        : theme.colorScheme.primary;
    final labelColor = isDark
        ? AppColors.textMutedWarmDark
        : AppColors.textMutedLight;

    return SizedBox(
      height: 176,
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: _Bar(
                // Tek döngü varsa oran 1.0 çıkıp sütun tavana yapışır;
                // 0.75 ile ölçeksiz ama dengeli görünür.
                heightFactor: points.length == 1
                    ? 0.75
                    : ((point.lengthInDays - base) / span).clamp(0.08, 1.0),
                value: point.lengthInDays,
                label: context.shortMonthName(point.startDate.month),
                color: barColor,
                labelColor: labelColor,
                valueColor: isDark ? Colors.white : AppColors.textMainLight,
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double heightFactor;
  final int value;
  final String label;
  final Color color;
  final Color labelColor;
  final Color valueColor;

  const _Bar({
    required this.heightFactor,
    required this.value,
    required this.label,
    required this.color,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value',
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                widthFactor: 0.62,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: labelColor),
          ),
        ],
      ),
    );
  }
}
