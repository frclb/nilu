import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';

/// Tahmini doğum tarihini düzeltme.
///
/// ACOG Committee Opinion 700 ve Bakanlık rehberi: ilk trimester ultrasonu
/// yapıldıysa ya da son adet tarihi şüpheliyse gebelik yaşı ultrasona göre
/// belirleniyor — yani hekimin verdiği tarih uygulamanınkini ezer. Bu alanı
/// kilitlemek tıbben yanlış olurdu.
Future<void> showDueDateSheet(BuildContext context) async {
  final vm = context.read<PregnancyViewModel>();
  final g = vm.current;
  if (g == null || !g.isActive) return;

  final bugun = DateTime.now();
  final secilen = await showDatePicker(
    context: context,
    initialDate: g.estimatedDueDate.isBefore(bugun)
        ? bugun
        : g.estimatedDueDate,
    firstDate: DateTime(bugun.year, bugun.month, bugun.day),
    // Bugünden itibaren tam bir gebelik.
    lastDate: bugun.add(const Duration(days: 300)),
    helpText: context.tr('preg_due_edit_title'),
  );
  if (secilen == null || !context.mounted) return;

  final hekimden = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      return AlertDialog(
        title: Text(ctx.tr('preg_due_source_title')),
        content: Text(
          ctx.tr(
            'preg_due_source_body',
            params: {
              'date':
                  '${secilen.day} ${ctx.monthName(secilen.month)} '
                  '${secilen.year}',
            },
          ),
          style: TextStyle(color: t.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('preg_due_source_self')),
          ),
          FilledButton(
            // Temanın tam genişlik asgarisi düğmeyi "Hayır"ın altına itiyordu.
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('preg_due_source_clinician')),
          ),
        ],
      );
    },
  );
  if (hekimden == null) return;

  await vm.updateDueDate(secilen, fromClinician: hekimden);
}
