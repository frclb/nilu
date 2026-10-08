import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/date_names.dart';

/// Kayıt ekranının başlığı: kaydedilen gün. Bugünse "Bugün, …".
///
/// Önceden `log_date_example`
/// adında sabit bir metin çiziliyordu: her kullanıcı, her gün "Bugün,
/// 24 Ekim" görüyordu. Sağlık verisi girilen ekranın yanlış günü söylemesi,
/// toplanan verinin kendisine olan güveni zedeliyor.
class LogEntryHeader extends StatelessWidget {
  const LogEntryHeader({super.key, this.date});

  /// Kaydedilen gün. Boşsa bugün.
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final day = date ?? now;
    final today =
        day.year == now.year && day.month == now.month && day.day == now.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Gün ve ay ayrı parametre: İngilizce ayı öne alıyor, İspanyolca
            // ve Portekizce araya "de" koyuyor.
            context.tr(
              today ? 'log_date_today' : 'log_date_other',
              params: {
                'day': '${day.day}',
                'month': context.monthName(day.month),
                'year': '${day.year}',
              },
            ),
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('log_subtitle'),
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
