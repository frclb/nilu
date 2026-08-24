import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// "Regl başladı" / "Regl bitti" — duruma göre değişen tek düğme.
///
/// İki ayrı düğme yerine bir tane var: aynı anda yalnızca biri anlamlı ve iki
/// düğme kullanıcıyı hangisine basacağını düşünmeye zorluyor.
///
/// Bu eylem eskiden yalnızca takvimde gizliydi: ana ekrandan takvime git, güne
/// dokun, sayfayı kaydır, "Regl işaretle"ye bas. Uygulamanın en sık yapılan
/// işi dört dokunuş uzaktaydı.
class PeriodToggleButton extends StatefulWidget {
  const PeriodToggleButton({super.key});

  @override
  State<PeriodToggleButton> createState() => _PeriodToggleButtonState();
}

class _PeriodToggleButtonState extends State<PeriodToggleButton> {
  bool _busy = false;

  Future<void> _toggle(CalendarViewModel viewModel, bool bleedingToday) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.tr('home_period_toggle_failed');

    setState(() => _busy = true);
    final ok = await viewModel.togglePeriodDay(DateTime.now());
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
    final bleedingToday = viewModel.isPeriodDay(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: SizedBox(
        height: 52,
        child: bleedingToday
            // Bitirme yıkıcı bir eylem değil ama geri alınabilir olduğu
            // belli olsun diye daha sakin duruyor.
            ? OutlinedButton.icon(
                onPressed: _busy ? null : () => _toggle(viewModel, true),
                icon: const Icon(Icons.stop_circle_outlined, size: 20),
                label: Text(context.tr('home_period_end')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: t.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            : FilledButton.icon(
                onPressed: _busy ? null : () => _toggle(viewModel, false),
                icon: const Icon(Icons.water_drop_outlined, size: 20),
                label: Text(context.tr('home_period_start')),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
      ),
    );
  }
}
