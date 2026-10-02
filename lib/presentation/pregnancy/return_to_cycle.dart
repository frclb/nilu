import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';

/// Lohusalığı erken bitirip regl takibine dönme — onaylı.
///
/// Lohusalık doğumdan sonra 42 gün sürüyor; ilk regl daha önce gelebilir,
/// kullanıcı lohusa ekranlarını istemeyebilir. Önceden bu evreden çıkmanın
/// bir yolu yoktu: kullanıcı 42 gün boyunca lohusa panosunda kalıyordu.
/// Doğum kaydı ve randevular silinmiyor.
Future<void> confirmReturnToCycle(BuildContext context) async {
  final vm = context.read<PregnancyViewModel>();
  final router = GoRouter.of(context);
  final onay = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('pp_return_dialog'),
      title: Text(ctx.tr('pp_return_title')),
      content: Text(ctx.tr('pp_return_body')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('cancel')),
        ),
        FilledButton(
          key: const Key('pp_return_confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('pp_return_to_cycle')),
        ),
      ],
    ),
  );
  if (onay != true) return;
  await vm.endPostpartum();
  // Ana sekme evreye göre çiziliyor; döngü ana ekranı açılıyor.
  router.goNamed(RouteNames.home);
}
