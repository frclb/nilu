import 'package:flutter/material.dart';

import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import 'log_section_header.dart';

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

    // Çerçeve ve dolgu temadan (16 pt köşe, odakta böğürtlen).
    InputDecoration kutu(String etiket, String ipucu, {String? sonEk}) =>
        InputDecoration(
          labelText: etiket,
          hintText: ipucu,
          suffixText: sonEk,
          isDense: true,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogSectionHeader(
            icon: Icons.monitor_heart_outlined,
            title: context.tr('log_measure_title'),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('log_measure_hint'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: t.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('log_measure_weight'),
                  controller: weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: kutu(
                    context.tr('log_measure_weight'),
                    '64,5',
                    sonEk: 'kg',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr('log_measure_bp'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
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
                        decoration: kutu(
                          context.tr('log_measure_systolic'),
                          '120',
                        ),
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
          ),
        ],
      ),
    );
  }
}
