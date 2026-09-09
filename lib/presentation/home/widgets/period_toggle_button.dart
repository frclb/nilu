import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// Reglin başlangıcını ve bitişini kaydeden düğme.
///
/// Bu eylem eskiden yalnızca takvimde gizliydi: ana ekrandan takvime git, güne
/// dokun, sayfayı kaydır, "Regl işaretle"ye bas. Uygulamanın en sık yapılan
/// işi dört dokunuş uzaktaydı.
///
/// Üç durum var, çünkü iki durum yetmiyordu. Düğme eskiden günü kaydın
/// dışına çıkarıp içine alan kör bir anahtardı; "Reglim bitti" son kanama
/// gününü işaretlemek yerine siliyordu. Şimdi eylemler açık: başlat, bitir,
/// bir de bitirdikten sonra geri al.
class PeriodToggleButton extends StatefulWidget {
  const PeriodToggleButton({super.key});

  @override
  State<PeriodToggleButton> createState() => _PeriodToggleButtonState();
}

class _PeriodToggleButtonState extends State<PeriodToggleButton> {
  bool _busy = false;

  Future<void> _run(Future<bool> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.tr('home_period_toggle_failed');

    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();
    final action = viewModel.periodActionToday;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: SizedBox(
        height: 52,
        child: switch (action) {
          PeriodAction.start => FilledButton.icon(
            onPressed: _busy ? null : () => _run(viewModel.startPeriodToday),
            icon: const Icon(Icons.water_drop_outlined, size: 20),
            label: Text(context.tr('home_period_start')),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Bitirme yıkıcı bir eylem değil ama geri alınabilir olduğu belli
          // olsun diye daha sakin duruyor.
          PeriodAction.end => OutlinedButton.icon(
            onPressed: _busy ? null : () => _run(viewModel.endPeriodToday),
            icon: const Icon(Icons.stop_circle_outlined, size: 20),
            label: Text(context.tr('home_period_end')),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: t.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Kaydedildi. Düğme yerine onay duruyor: basılacak bir şey
          // kalmadığında düğme göstermek, basınca bir şey olmayacağı için
          // uygulamayı bozuk gösteriyor.
          PeriodAction.endedToday => _EndedToday(
            onUndo: _busy ? null : () => _run(viewModel.reopenPeriodToday),
          ),
        },
      ),
    );
  }
}

class _EndedToday extends StatelessWidget {
  final VoidCallback? onUndo;

  const _EndedToday({required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.only(left: 18, right: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: t.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('home_period_ended_today'),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onUndo,
            child: Text(context.tr('home_period_undo')),
          ),
        ],
      ),
    );
  }
}
