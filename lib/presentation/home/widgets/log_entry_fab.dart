import 'package:flutter/material.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_decor.dart';
import '../../../localization/app_localizations.dart';

/// Günlük kayıt ekranını açan "+" düğmesi.
///
/// Döngü, gebelik ve lohusa panolarında aynı düğme. Önce yalnızca döngü
/// ana ekranındaydı: gebe ya da lohusa kullanıcının kayıt ekranına hiç
/// girişi yoktu — gebelik belirtileri, tansiyon ve kilo, gebelikte kanama
/// uyarısı yazılmış ama ulaşılamaz durumdaydı.
class LogEntryFab extends StatelessWidget {
  const LogEntryFab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      // Gölge degradeyle aynı erik tonunda; varsayılan gri gölge yerine.
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.floating(context),
      ),
      child: FloatingActionButton(
        key: const Key('log_entry_fab'),
        heroTag: 'home_fab',
        // VoiceOver "Kayıt Ekle, düğme" desin; yalnızca "+" simgesi bir şey
        // söylemiyor.
        tooltip: context.tr('log_title'),
        onPressed: () => NavigationService().push(RouteNames.logEntry),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.mark(context),
          ),
          child: const SizedBox.expand(
            child: Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ),
    );
  }
}
