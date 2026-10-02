import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Kilo ve tansiyon — gebelik ve lohusalıkta, isteğe bağlı.
///
/// Denetleyiciler kayıt ekranında: değerler kaydederken orada okunup
/// doğrulanıyor (bkz. `Vitals`). Bölüm yalnızca alanları çiziyor.
class MeasurementsSection extends StatelessWidget {
  const MeasurementsSection({
    super.key,
    required this.weight,
    required this.systolic,
    required this.diastolic,
  });

  final TextEditingController weight;
  final TextEditingController systolic;
  final TextEditingController diastolic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    InputDecoration kutu(String etiket, String ipucu, {String? sonEk}) =>
        InputDecoration(
          labelText: etiket,
          hintText: ipucu,
          suffixText: sonEk,
          border: const OutlineInputBorder(),
          isDense: true,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('log_measure_title'),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('log_measure_hint'),
            style: TextStyle(fontSize: 13, height: 1.45, color: t.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('log_measure_weight'),
            controller: weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: kutu(
              context.tr('log_measure_weight'),
              '64,5',
              sonEk: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('log_measure_bp'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('log_measure_systolic'),
                  controller: systolic,
                  keyboardType: TextInputType.number,
                  decoration: kutu(context.tr('log_measure_systolic'), '120'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '/',
                  style: TextStyle(fontSize: 20, color: t.textMuted),
                ),
              ),
              Expanded(
                child: TextField(
                  key: const Key('log_measure_diastolic'),
                  controller: diastolic,
                  keyboardType: TextInputType.number,
                  decoration: kutu(
                    context.tr('log_measure_diastolic'),
                    '80',
                    sonEk: 'mmHg',
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
