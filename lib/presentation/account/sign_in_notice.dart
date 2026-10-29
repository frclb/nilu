import 'package:flutter/material.dart';

import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';

/// Giriş düğmelerinin altında kısa aydınlatma (KVKK m.10): girişte ne
/// saklanıyor, nerede ve neden. Ayrıntısı gizlilik politikasında.
///
/// Uyum denetimi: hesap verisi Firebase'e (yurt dışı) giderken kullanıcıya
/// yalnızca politikanın bağlantısı gösteriliyordu.
class SignInNotice extends StatelessWidget {
  const SignInNotice({super.key});

  @override
  Widget build(BuildContext context) => Text(
    context.tr('sign_in_notice'),
    key: const Key('sign_in_notice'),
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 13,
      height: 1.45,
      color: context.tokens.textMuted,
    ),
  );
}
