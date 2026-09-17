import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/date_names.dart';

/// Kayıt ekranının başlığı.
///
/// Ekran her zaman **bugünü** kaydediyor (`_saveLog` içinde `DateTime.now()`),
/// o yüzden tarih burada da bugünden okunuyor. Önceden `log_date_example`
/// adında sabit bir metin çiziliyordu: her kullanıcı, her gün "Bugün,
/// 24 Ekim" görüyordu. Sağlık verisi girilen ekranın yanlış günü söylemesi,
/// toplanan verinin kendisine olan güveni zedeliyor.
class LogEntryHeader extends StatelessWidget {
  const LogEntryHeader({super.key, this.date});

  /// Testlerin sabit bir gün verebilmesi için. Boşsa bugün kullanılır.
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = date ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Gün ve ay ayrı parametre: İngilizce ayı öne alıyor, İspanyolca
            // ve Portekizce araya "de" koyuyor.
            context.tr(
              'log_date_today',
              params: {
                'day': '${day.day}',
                'month': context.monthName(day.month),
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
