import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_palette.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

/// İçgörüler başlığı.
///
/// Burada eskiden üç sekme vardı — Genel / Aktivite / Beslenme — ama yalnızca
/// ilki bir şey gösteriyordu; diğer ikisi "yakında eklenecek" uyarısı basıyordu.
/// Var olmayan bölümleri sekme olarak göstermek kullanıcıya olmayan bir içerik
/// vaat ediyordu, kaldırıldı.
///
/// Geri düğmesi de kaldırıldı: ekran artık alt menüdeki kök sekmelerden biri,
/// geri gidilecek bir yer yok.
class InsightsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InsightsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final textColor = isDark ? AppPalette.nightInk : AppColors.textMainLight;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              const SizedBox(width: 56),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insights,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.tr('insights_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Verine soru sorma girişi buradan: sorular zaten bu ekranın
              // hesapladığı sayılarla cevaplanıyor.
              IconButton(
                onPressed: () => context.pushNamed(RouteNames.assistant),
                tooltip: context.tr('assistant_title'),
                icon: Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
