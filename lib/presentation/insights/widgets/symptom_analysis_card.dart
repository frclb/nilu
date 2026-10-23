import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/models/log_vocabulary.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/services/insights_service.dart';
import '../../../domain/services/premium_gate.dart';
import '../../../domain/view_models/subscription_view_model.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// Kullanıcının en sık kaydettiği belirtiler.
///
/// Bu kart eskiden dört sabit çubuk gösteriyordu: Kramp %85, Baş Ağrısı %62,
/// Yorgunluk %45, Şişkinlik %20. Sayılar koda gömülüydü; kullanıcı hiç kayıt
/// girmemiş olsa bile aynı grafiği görüyordu. Sağlık verisi sunan bir ekranda
/// "makul görünen" bir sayı, yanlış sayıdan daha tehlikeli.
///
/// Artık her yüzde, kullanıcının kayıt girdiği gün sayısına oranla o belirtiyi
/// kaç günde işaretlediğini gösterir; kayıt yoksa kart bunu söyler.
class SymptomAnalysisCard extends StatelessWidget {
  const SymptomAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();

    final frequencies = InsightsService.symptomFrequencies(viewModel.dailyLogs);
    final loggedDays = InsightsService.loggedDayCount(viewModel.dailyLogs);

    final isPremium = context.watch<SubscriptionViewModel>().isPremium;
    final canSeePhase = PremiumGate.canSeePhaseBreakdown(isPremium: isPremium);

    // En sık görülen belirtinin hangi evrede toplandığı. Yeterli gözlem ya da
    // net bir çoğunluk yoksa null döner ve hiçbir şey söylenmez.
    final dominant = (frequencies.isEmpty || !canSeePhase)
        ? null
        : InsightsService.dominantPhase(
            frequencies.first.code,
            dailyLogs: viewModel.dailyLogs,
            periodLogs: viewModel.periodLogs,
            periodLength: viewModel.cycleInfo.averagePeriodLength,
            breaks: viewModel.cycleBreaks,
          );

    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    // Sıraya göre renk: en sık görülen böğürtlen, sonra erik, açık erik ve
    // mercan. Aynı rengin soluklaşan tonları yan yana ayırt edilmiyordu.
    final rankColors = [
      t.secondary,
      primary,
      Color.lerp(primary, t.surface, 0.35)!,
      t.accent,
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        context.tr('insights_symptoms_title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 21,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      frequencies.isEmpty
                          ? context.tr('insights_symptoms_subtitle')
                          : context.tr(
                              'insights_symptoms_basis',
                              params: {'days': '$loggedDays'},
                            ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppIconTile(
                icon: Icons.bubble_chart_outlined,
                size: 34,
                circle: true,
                background: t.surfaceAlt,
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (frequencies.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.edit_note_outlined, size: 20, color: t.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('insights_symptoms_empty'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.5,
                        color: t.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < frequencies.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _SymptomBar(
                label: context.tr(
                  LogVocabulary.symptomKey(frequencies[i].code),
                ),
                percentage: frequencies[i].percentage,
                dayCount: frequencies[i].dayCount,
                color: rankColors[i.clamp(0, rankColors.length - 1)],
              ),
            ],

          // Kilitli ve gösterilecek veri varsa kapıyı göster; veri yoksa
          // olmayan bir şeyi satmayalım.
          if (!canSeePhase && frequencies.isNotEmpty) ...[
            const SizedBox(height: 18),
            _PhaseLocked(),
          ],

          if (dominant != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.brandTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.calendar_view_week, size: 19, color: t.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        'insights_symptom_phase',
                        params: {
                          'symptom': context.tr(
                            LogVocabulary.symptomKey(frequencies.first.code),
                          ),
                          'phase': context.tr(_phaseKey(dominant.phase)),
                          'count': '${dominant.count}',
                          'total': '${dominant.total}',
                        },
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: t.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _phaseKey(CyclePhase phase) => switch (phase) {
    CyclePhase.menstruation => 'phase_menstruation',
    CyclePhase.follicular => 'phase_follicular',
    CyclePhase.ovulation => 'phase_ovulation',
    CyclePhase.luteal => 'phase_luteal',
    CyclePhase.suppressed => 'phase_suppressed',
    CyclePhase.unknown => 'phase_unknown',
  };
}

/// Evre kırılımının premium olduğunu bildirir.
class _PhaseLocked extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: t.brandTint,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => context.pushNamed(RouteNames.premium),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.tr('insights_phase_locked'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: t.text, height: 1.4),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomBar extends StatelessWidget {
  final String label;
  final int percentage;
  final int dayCount;
  final Color color;

  const _SymptomBar({
    required this.label,
    required this.percentage,
    required this.dayCount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    // Ham gün sayısı da gösteriliyor: tek kayıtlı günde "%100" tek başına
    // yanıltıcı, "%100 · 1 gün" değil. Yüzde kısmı vurgulu, gün sayısı
    // sönük; ayraç yoksa (başka bir dilde) metin tek parça kalıyor.
    final count = context.tr(
      'insights_symptoms_count',
      params: {'percent': '$percentage', 'days': '$dayCount'},
    );
    final split = count.indexOf('·');
    final countStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: t.textMuted,
    );
    final strongStyle = theme.textTheme.labelMedium?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: color,
    );

    return Semantics(
      label: context.tr(
        'insights_symptoms_semantics',
        params: {
          'symptom': label,
          'percent': '$percentage',
          'days': '$dayCount',
        },
      ),
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text.rich(
                split <= 0
                    ? TextSpan(text: count, style: strongStyle)
                    : TextSpan(
                        children: [
                          TextSpan(
                            text: count.substring(0, split).trimRight(),
                            style: strongStyle,
                          ),
                          TextSpan(
                            text: ' ${count.substring(split)}',
                            style: countStyle,
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            height: 12,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0.0, 1.0),
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    gradient: LinearGradient(
                      colors: [color.withAlpha(120), color],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
