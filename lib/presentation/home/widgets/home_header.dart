import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/profile_repository.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';
import '../../widgets/profile_avatar_button.dart';

/// Panoların en üstü: marka çubuğu (logo, "Nilu", profil düğmesi).
///
/// Döngü, gebelik ve lohusalık panosu aynı çubuğu kullanıyor; profil
/// düğmesi eskiden selamlamanın yanındaydı.
class HomeBrandBar extends StatelessWidget {
  const HomeBrandBar({super.key});

  @override
  Widget build(BuildContext context) =>
      const AppBrandBar(trailing: ProfileAvatarButton());
}

/// Selamlama ve ad; sağda isteğe bağlı bir hap (ör. döngü evresi).
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key, this.trailing});

  /// Satırın sağındaki öğe. Döngü panosunda evre hapı ([HomePhasePill]).
  final Widget? trailing;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await const ProfileRepository().getName();
    if (!mounted) return;
    setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final isPartner = context.watch<UserViewModel>().isPartner;

    final serif = theme.textTheme.headlineLarge?.copyWith(
      fontSize: 32,
      height: 1.1,
      letterSpacing: -0.5,
      color: theme.colorScheme.primary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: isPartner
                // Partner modunda ad yok; "Partnerinin Döngüsü" başlığın
                // kendisi.
                ? Text(
                    context.tr('home_greeting_partner'),
                    style: serif?.copyWith(fontSize: 28),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home_greeting'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                          color: t.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Ad profilden gelir; girilmemişse nötr bir hitap.
                      Text(
                        (_name?.isNotEmpty ?? false)
                            ? _name!
                            : context.tr('home_greeting_no_name'),
                        style: serif,
                      ),
                    ],
                  ),
          ),
          // Hap ekranın en fazla %45'ini alıyor; büyük yazıda ad ezilmesin.
          if (widget.trailing != null)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.45,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: widget.trailing,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bugünün döngü evresi: renk noktası ve evrenin adı.
///
/// Evre bilinmiyorsa (kayıt yok) ya da hormonal korunmada evreler
/// ayrılmıyorsa hiçbir şey göstermiyor — orada söylenecek bir evre yok.
class HomePhasePill extends StatelessWidget {
  const HomePhasePill({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final phase = context.select<CalendarViewModel, CyclePhase>(
      (vm) => vm.cycleInfo.currentPhase,
    );

    if (phase == CyclePhase.unknown || phase == CyclePhase.suppressed) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: t.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: t.flowTint),
        boxShadow: AppShadows.soft(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: phase.color(t),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.tr('phase_title_${phase.name}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
