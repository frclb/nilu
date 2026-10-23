import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/life_stage.dart';
import '../../localization/app_localizations.dart';
import 'danger_signs_screen.dart';

/// Regl kaydının tutulmadığı evrede "Regl işaretle" düğmesinin yerine.
///
/// Önceden düğme duruyordu, koruma basışı reddediyordu ve ekran "gelecek bir
/// tarihe regl girilemez" hatası gösteriyordu — tamamen yanlış bir mesaj.
/// Basılabilir görünüp çalışmayan bir düğme uygulamayı bozuk gösterir;
/// burada neden olmadığını ve ne yapılacağını söylüyoruz.
class StageBleedingNote extends StatelessWidget {
  const StageBleedingNote({super.key, required this.stage});

  final LifeStage stage;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gebelik = stage == LifeStage.pregnancy;

    return Container(
      key: const Key('stage_bleeding_note'),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: gebelik ? t.accentTint.withAlpha(150) : t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: gebelik ? t.warning.withAlpha(50) : t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: gebelik
                ? Icons.health_and_safety_outlined
                : Icons.info_outline_rounded,
            size: 32,
            circle: true,
            background: t.surface.withAlpha(200),
            color: gebelik ? t.warning : t.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    gebelik
                        ? 'calendar_preg_bleeding_note'
                        : 'calendar_pp_bleeding_note',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    height: 1.45,
                    color: t.text,
                  ),
                ),
                if (gebelik)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: t.secondary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => context.pushNamed(
                      RouteNames.dangerSigns,
                      queryParameters: {'period': DangerPeriod.pregnancy.name},
                    ),
                    child: Text(context.tr('preg_danger_entry_title')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
