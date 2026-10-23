import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/services/phase_guide.dart';
import '../../../domain/services/session_plan.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';

class DailySuggestionCard extends StatelessWidget {
  /// Ana ekranın "+" düğmesi için sağda yer bırakılsın mı?
  ///
  /// Bu, kaydırma alanındaki **tek sağa yaslı dokunulabilir** öğe; FAB da
  /// sağa yaslı. İkisi aynı sütunda olduğu için "Tümünü Gör" düğmenin altında
  /// kalıyor ve okunmuyordu. Kartların üstünden geçmesi sorun değil — onlar
  /// köşeye yaslı bağlantı değil.
  final bool reserveFabSpace;

  const DailySuggestionCard({super.key, this.reserveFabSpace = false});

  /// FAB'ın kapladığı genişlik: 56 çap + 16 kenar boşluğu + 8 pay.
  static const double _fabClearance = 80;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();
    final phase = viewModel.cycleInfo.currentPhase;
    final guidance = PhaseGuide.forPhase(phase);
    final hasSession = guidance.activity.hasSession;
    final activityIcon = _iconFor(guidance.activity);

    // Öneri evreye göre seçiliyor; etiket bunu söylüyor. Evre bilinmiyorsa
    // ya da hormonal korunmada evreler ayrılmıyorsa etiket yok.
    final showPhaseTag =
        phase != CyclePhase.unknown && phase != CyclePhase.suppressed;

    final stacked = MediaQuery.textScalerOf(context).scale(16) > 16 * 1.3;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(guidance.activityTitleKey),
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: t.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr(guidance.activityDescKey),
          maxLines: hasSession && !stacked ? 3 : 5,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            height: 1.5,
            color: t.textMuted,
          ),
        ),
      ],
    );

    final start = hasSession
        ? AppGradientButton(
            key: const Key('suggestion_start'),
            label: context.tr('home_start_button'),
            icon: Icons.play_arrow_rounded,
            gradient: AppGradients.coral,
            height: 44,
            radius: AppRadius.sm,
            expand: false,
            onPressed: () => NavigationService().push(RouteNames.yogaDetail),
          )
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 4,
              right: reserveFabSpace ? _fabClearance : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Büyük yazıda başlık sarıyor; düğme yerinde kalıyor.
                Expanded(
                  child: Text(
                    context.tr('home_daily_suggestion_title'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 21,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                // Dokunma hedefi 10 piksellik bir yazıydı — parmakla
                // isabet ettirmek zordu. `TextButton` en az 44 piksellik bir
                // alan veriyor.
                TextButton.icon(
                  onPressed: () =>
                      NavigationService().push(RouteNames.healthLibrary),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                  label: Text(context.tr('home_see_all')),
                  style: TextButton.styleFrom(
                    foregroundColor: t.secondary,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.warm(context),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: t.accent.withAlpha(36)),
              boxShadow: AppShadows.soft(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Aktivitenin simgesi filigran olarak.
                Positioned(
                  right: -14,
                  bottom: -18,
                  child: ExcludeSemantics(
                    child: Icon(
                      activityIcon,
                      size: 100,
                      color: t.accent.withAlpha(14),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showPhaseTag || hasSession) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (showPhaseTag)
                              AppTag(
                                label: context.upper(
                                  context.tr('phase_title_${phase.name}'),
                                ),
                                icon: activityIcon,
                                background: t.phaseLuteal.withAlpha(30),
                                foreground: t.accent,
                              ),
                            // Süre seansın kendisinden: kart "10 dk" yazıp
                            // 17 dakikalık akışı açıyordu.
                            if (hasSession)
                              AppTag(
                                label: context.tr(
                                  'duration_minutes',
                                  params: {
                                    'n': '${SessionPlan.yoga.total.inMinutes}',
                                  },
                                ),
                                icon: Icons.schedule,
                                background: t.surface.withAlpha(150),
                                foreground: t.accent,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      // Büyük yazıda düğme metnin altına iniyor: yan yana
                      // durunca açıklama üç kelimelik bir sütuna sıkışıyordu.
                      if (start != null && !stacked)
                        Row(
                          children: [
                            Expanded(child: text),
                            const SizedBox(width: 12),
                            start,
                          ],
                        )
                      else ...[
                        text,
                        if (start != null) ...[
                          const SizedBox(height: 14),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: start,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aktivite türünü ikona çevirir.
  ///
  /// İkon seçimi sunum katmanının işi; [PhaseGuide] `material` içe aktarmadan
  /// saf kalsın diye eşleme burada.
  IconData _iconFor(PhaseActivity activity) => switch (activity) {
    PhaseActivity.yinYoga => Icons.self_improvement,
    PhaseActivity.strength => Icons.fitness_center,
    PhaseActivity.cardio => Icons.directions_run,
    PhaseActivity.meditation => Icons.spa,
    PhaseActivity.gentle => Icons.favorite_border,
  };
}
