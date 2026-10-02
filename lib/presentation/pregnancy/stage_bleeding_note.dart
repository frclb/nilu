import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/route_names.dart';
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            gebelik ? Icons.health_and_safety_outlined : Icons.info_outline,
            size: 20,
            color: gebelik ? t.warning : t.textMuted,
          ),
          const SizedBox(width: 10),
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
                  style: TextStyle(fontSize: 13, height: 1.45, color: t.text),
                ),
                if (gebelik)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
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
