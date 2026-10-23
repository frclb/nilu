import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/navigation_service.dart';

/// Kayıt ekranının üst çubuğu: solda kapat, ortada serif başlık.
///
/// Zemin ekranla aynı: çubuk ayrı bir şerit gibi değil, sayfanın başı gibi
/// okunuyor.
class LogEntryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LogEntryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return ColoredBox(
      color: t.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => NavigationService().pop(),
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: t.brandTint,
                  foregroundColor: theme.colorScheme.primary,
                  fixedSize: const Size(40, 40),
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: Text(
                  context.tr('log_title'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              // Kapat düğmesini dengeler; başlık tam ortada kalsın.
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}
