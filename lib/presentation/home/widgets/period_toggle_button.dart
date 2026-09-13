import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_snack.dart';
import '../../../design_system/app_theme.dart';
import '../../../localization/date_names.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// Reglin başlangıcını ve bitişini kaydeden düğme.
///
/// Bu eylem eskiden yalnızca takvimde gizliydi: ana ekrandan takvime git, güne
/// dokun, sayfayı kaydır, "Regl işaretle"ye bas. Uygulamanın en sık yapılan
/// işi dört dokunuş uzaktaydı.
///
/// Alan tek bir şey gösteriyor: sıradaki eylem. Eylem kalmadığında — regl
/// bugün kapatıldığında — yerini sessiz bir durum satırı alıyor. Geri alma
/// ikisinde de aynı yerden geliyor: eylemin hemen ardından çıkan geçici
/// bildirimden. Ekranda sürekli duran bir "Geri al" hem tutarsızdı hem de
/// geri alınacak bir şey kalmadığında da orada duruyordu.
class PeriodToggleButton extends StatefulWidget {
  const PeriodToggleButton({super.key});

  @override
  State<PeriodToggleButton> createState() => _PeriodToggleButtonState();
}

class _PeriodToggleButtonState extends State<PeriodToggleButton> {
  bool _busy = false;

  Future<void> _run(
    Future<bool> Function() action, {
    required String confirmation,
    required VoidCallback undo,
  }) async {
    final failed = context.tr('home_period_toggle_failed');
    final undoLabel = context.tr('home_period_undo');

    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    if (!ok) {
      AppSnack.error(context, failed);
      return;
    }
    AppSnack.show(context, confirmation, undoLabel: undoLabel, onUndo: undo);
  }

  /// Tahmin edilen tarihten çok önce regl başlatılıyorsa onay ister.
  ///
  /// Kazara dokunuş döngüyü sessizce yeniden yazıyordu: "17 gün var" bir
  /// anda "1. gün" oluyor, `lastPeriodStart` kayıyor ve bütün tahminler
  /// bununla birlikte kayıyor. Geri alma yolu var ama geçici; kazayı baştan
  /// durdurmak daha iyi.
  ///
  /// Gecikmede **sormuyoruz**: regl gecikmesi olağan ve kullanıcı zaten
  /// bekliyor olur. Yalnızca beklenenden bir haftadan fazla erkenken
  /// soruluyor — o kadar erken bir başlangıç ya gerçekten olağandışı ya da
  /// yanlış dokunuş.
  static const int _earlyStartThresholdDays = 7;

  Future<bool> _confirmEarlyStart(CalendarViewModel viewModel) async {
    final info = viewModel.cycleInfo;
    final daysLeft = info.daysUntilNextPeriod;
    final predicted = info.predictedNextPeriod;

    if (daysLeft == null ||
        predicted == null ||
        daysLeft <= _earlyStartThresholdDays) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('home_period_early_title')),
        content: Text(
          ctx.tr(
            'home_period_early_body',
            params: {
              'n': '$daysLeft',
              'date': '${predicted.day} ${ctx.monthName(predicted.month)}',
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('home_period_early_confirm')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
            onPressed: _busy
                ? null
                : () async {
                    // Metin onay diyaloğundan **önce** okunuyor: sonrasında
                    // `context` bir async boşluğun ötesinde kalıyor.
                    final confirmation = context.tr('home_period_started');
                    if (!await _confirmEarlyStart(viewModel)) return;
                    if (!mounted) return;
                    await _run(
                      viewModel.startPeriodToday,
                      confirmation: confirmation,
                      undo: () => viewModel.undoPeriodStart(),
                    );
                  },
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
            onPressed: _busy
                ? null
                : () => _run(
                    viewModel.endPeriodToday,
                    confirmation: context.tr('home_period_ended'),
                    undo: () => viewModel.reopenPeriodToday(),
                  ),
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

          // Basılacak bir şey kalmadı. Düğme bırakmak, basınca hiçbir şey
          // olmayacağı için uygulamayı bozuk gösterirdi.
          PeriodAction.endedToday => const _EndedToday(),
        },
      ),
    );
  }
}

class _EndedToday extends StatelessWidget {
  const _EndedToday();

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
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: t.success),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              context.tr('home_period_ended_today'),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
