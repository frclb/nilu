import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import 'cycle_trend_chart.dart';
import '../../../presentation/calendar/view_models/calendar_view_model.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/services/insights_service.dart';
import '../../../domain/services/premium_gate.dart';
import '../../../domain/view_models/subscription_view_model.dart';

/// Kullanıcının gözlenmiş döngü uzunlukları.
///
/// Kart eskiden her zaman dolu görünüyordu: grafik sabit bir eğri, alttaki
/// yorum ise "Döngünüz bu ay normalden 2 gün daha uzun sürdü" diye sabit bir
/// cümleydi — kullanıcı hiç kayıt girmemiş olsa bile. Artık hem sayılar hem
/// yorum gerçek kayıtlardan geliyor, yetecek veri yoksa kart bunu söylüyor.
class CycleTrendCard extends StatelessWidget {
  const CycleTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<CalendarViewModel>();

    final isPremium = context.watch<SubscriptionViewModel>().isPremium;

    // Tüm gözlenmiş döngüler hesaplanır, ekranda gösterilen kırpılır:
    // "daha fazlası var" derken elimizde olmayan veriyi ima etmeyelim.
    final allPoints = InsightsService.cycleLengths(
      viewModel.periodLogs,
      breaks: viewModel.cycleBreaks,
      limit: null,
    );
    final points = PremiumGate.visibleCycles(allPoints, isPremium: isPremium);
    final trimmed = PremiumGate.historyIsTrimmed(
      isPremium: isPremium,
      observedCycles: allPoints.length,
    );
    final average = InsightsService.averageLength(points);
    final variation = InsightsService.variation(points);
    final regularity = InsightsService.regularity(points);

    final textColor = context.tokens.text;
    final subtitleColor = context.tokens.textMuted;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('insights_trend_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      points.isEmpty
                          ? context.tr('insights_trend_no_data_subtitle')
                          : context.tr(
                              'insights_trend_cycles',
                              params: {'count': '${points.length}'},
                            ),
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              if (average != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.tr(
                        'insights_trend_average',
                        params: {'days': '$average'},
                      ),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.tokens.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        context.tr('insights_trend_average_label'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          if (points.isEmpty)
            _EmptyState(subtitleColor: subtitleColor)
          else ...[
            CycleTrendChart(points: points),
            const SizedBox(height: 20),
            _InsightBox(
              text: _insightText(context, variation),
              isDark: isDark,
              textColor: textColor,
            ),
            // Belirgin sapmada kullanıcı bilgilendirilir. Teşhis değil:
            // uygulamanın söylediği tek şey kendi kayıtlarının ne kadar
            // oynadığı ve isterse hekimine danışabileceği.
            if (regularity?.shouldSuggestConsultation ?? false) ...[
              const SizedBox(height: 12),
              _ConsultationNote(isDark: isDark),
            ],
            if (trimmed) ...[
              const SizedBox(height: 12),
              _UnlockHistoryNote(hidden: allPoints.length - points.length),
            ],
          ],
        ],
      ),
    );
  }

  /// Grafiğin altındaki cümle.
  ///
  /// Tek döngü varken yorum yapılmaz: iki ölçüm olmadan "düzenli" ya da
  /// "değişken" demek veriye dayanmaz.
  String? _insightText(BuildContext context, int? variation) {
    if (variation == null) return null;
    return context.tr(
      variation <= 3 ? 'insights_trend_steady' : 'insights_trend_variable',
      params: {'days': '$variation'},
    );
  }
}

/// Döngüler belirgin biçimde oynadığında çıkan bilgilendirme.
class _ConsultationNote extends StatelessWidget {
  final bool isDark;

  const _ConsultationNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final amber = context.tokens.accent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? context.tokens.accent.withAlpha(38)
            : context.tokens.accentTint,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: amber.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined, size: 20, color: amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('insights_consult_title'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('insights_consult_text'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: context.tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ücretsiz sürümde gizlenen döngüleri bildirir.
class _UnlockHistoryNote extends StatelessWidget {
  final int hidden;

  const _UnlockHistoryNote({required this.hidden});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Material(
      color: t.brandTint,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () => context.pushNamed(RouteNames.premium),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.tr(
                    'insights_history_locked',
                    params: {'count': '$hidden'},
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: t.text, height: 1.4),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color subtitleColor;

  const _EmptyState({required this.subtitleColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.insights_outlined, size: 20, color: subtitleColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.tr('insights_trend_empty'),
            style: TextStyle(fontSize: 13, height: 1.5, color: subtitleColor),
          ),
        ),
      ],
    );
  }
}

class _InsightBox extends StatelessWidget {
  final String? text;
  final bool isDark;
  final Color textColor;

  const _InsightBox({
    required this.text,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final message = text;
    if (message == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? context.tokens.surface.withAlpha(127)
            : context.tokens.brandTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
