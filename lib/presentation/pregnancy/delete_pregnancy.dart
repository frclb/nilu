import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';

/// Gebelik kaydını silmeden önce onay ister; silindiyse `true`.
///
/// Sonlandırmanın yanında ayrı bir yol: yanlışlıkla eklenmiş bir kayıt
/// "bitmiş gebelik" değil.
Future<bool> confirmDeletePregnancy(BuildContext context, String id) async {
  final onay = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('preg_delete_title')),
      content: Text(ctx.tr('preg_delete_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('cancel')),
        ),
        FilledButton(
          key: const Key('preg_delete_confirm'),
          style: AppTheme.dialogAction().copyWith(
            backgroundColor: WidgetStatePropertyAll(ctx.tokens.danger),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('preg_delete_confirm')),
        ),
      ],
    ),
  );
  if (onay != true || !context.mounted) return false;
  await context.read<PregnancyViewModel>().deletePregnancy(id);
  return true;
}
