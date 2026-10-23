import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/date_names.dart';

/// Kayıt ekranının başlığı: kaydedilen gün. Bugünse "Bugün, …".
///
/// Önceden `log_date_example`
/// adında sabit bir metin çiziliyordu: her kullanıcı, her gün "Bugün,
/// 24 Ekim" görüyordu. Sağlık verisi girilen ekranın yanlış günü söylemesi,
/// toplanan verinin kendisine olan güveni zedeliyor.
///
/// Gül tülü bir kartın içinde; varsa üstünde döngü günü ([eyebrow]).
class LogEntryHeader extends StatelessWidget {
  const LogEntryHeader({super.key, this.date, this.eyebrow});

  /// Kaydedilen gün. Boşsa bugün.
  final DateTime? date;

  /// Tarihin üstündeki küçük etiket (ör. "Döngü günü 18"). Gün döngüde
  /// değilse (gebelik, lohusalık, veri yok) verilmiyor.
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final now = DateTime.now();
    final day = date ?? now;
    final today =
        day.year == now.year && day.month == now.month && day.day == now.day;

    final dateText = Text(
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
      style: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 28,
        color: theme.colorScheme.primary,
        letterSpacing: -0.4,
        height: 1.15,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [t.secondaryTint, t.brandTint],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (eyebrow != null) ...[
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: t.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: AppSectionLabel(eyebrow!, color: t.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            dateText,
            const SizedBox(height: 8),
            Text(
              context.tr('log_subtitle'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
