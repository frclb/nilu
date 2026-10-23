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
    final t = context.tokens;
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.query_stats, size: 18, color: t.textMuted),
                        const SizedBox(width: 6),
                        // Büyük harfe çevrilmiyor: kaç döngünün
                        // gösterildiği sayıyla okunmalı, etiket gibi değil.
                        Flexible(
                          child: Text(
                            points.isEmpty
                                ? context.tr('insights_trend_no_data_subtitle')
                                : context.tr(
                                    'insights_trend_cycles',
                                    params: {'count': '${points.length}'},
                                  ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: t.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Semantics(
                      header: true,
                      child: Text(
                        context.tr('insights_trend_title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 21,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (average != null) ...[
                const SizedBox(width: 12),
                _AverageBadge(average: average),
              ],
            ],
          ),

          const SizedBox(height: 20),

          if (points.isEmpty)
            const _EmptyState()
          else ...[
            CycleTrendChart(points: points, average: average),
            const SizedBox(height: 16),
            _InsightBox(
              text: _insightText(context, variation),
              emphasis: variation == null ? null : '$variation',
            ),
            // Belirgin sapmada kullanıcı bilgilendirilir. Teşhis değil:
            // uygulamanın söylediği tek şey kendi kayıtlarının ne kadar
            // oynadığı ve isterse hekimine danışabileceği.
            if (regularity?.shouldSuggestConsultation ?? false) ...[
              const SizedBox(height: 12),
              const _ConsultationNote(),
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

/// Sağ üstteki ortalama: büyük serif sayı, yanında birim, altında etiket.
class _AverageBadge extends StatelessWidget {
  const _AverageBadge({required this.average});

  final int average;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final full = context.tr(
      'insights_trend_average',
      params: {'days': '$average'},
    );

    // Sayı çeviri metninin içinden ayrılıyor: birim dile göre önde ya da
    // arkada olabilir, ayrı anahtar gerekmiyor.
    final number = '$average';
    final at = full.indexOf(number);
    final big = theme.textTheme.displaySmall?.copyWith(
      fontSize: 36,
      height: 1,
      color: theme.colorScheme.primary,
    );
    final unit = theme.textTheme.headlineSmall?.copyWith(
      fontSize: 18,
      color: t.secondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text.rich(
          at < 0
              ? TextSpan(text: full, style: big)
              : TextSpan(
                  children: [
                    if (at > 0)
                      TextSpan(text: full.substring(0, at), style: unit),
                    TextSpan(text: number, style: big),
                    TextSpan(
                      text: full.substring(at + number.length),
                      style: unit,
                    ),
                  ],
                ),
          maxLines: 1,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: t.brandTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            context.tr('insights_trend_average_label'),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Döngüler belirgin biçimde oynadığında çıkan bilgilendirme.
class _ConsultationNote extends StatelessWidget {
  const _ConsultationNote();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.accentTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_outlined, size: 20, color: t.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('insights_consult_title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: t.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('insights_consult_text'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: t.textMuted,
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
                  context.tr(
                    'insights_history_locked',
                    params: {'count': '$hidden'},
                  ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    // Beklemek yerine hatırlananları girmek: trend iki başlangıçla çıkıyor.
    final kayitTutuluyor = context.select<CalendarViewModel, bool>(
      (vm) => vm.lifeStage.recordsPeriods,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.insights_outlined, size: 20, color: t.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('insights_trend_empty'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.5,
                    color: t.textMuted,
                  ),
                ),
                if (kayitTutuluyor)
                  TextButton.icon(
                    key: const Key('insights_add_past_periods'),
                    onPressed: () => context.pushNamed(RouteNames.pastPeriods),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 44),
                      foregroundColor: t.secondary,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.tr('past_periods_entry')),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grafiğin altındaki yorum şeridi; değişim günü vurgulu.
class _InsightBox extends StatelessWidget {
  final String? text;
  final String? emphasis;

  const _InsightBox({required this.text, required this.emphasis});

  @override
  Widget build(BuildContext context) {
    final message = text;
    if (message == null) return const SizedBox.shrink();

    final t = context.tokens;
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 13.5,
      height: 1.45,
      color: t.text,
    );
    final strong = base?.copyWith(
      fontWeight: FontWeight.w700,
      color: t.secondary,
    );

    final needle = emphasis;
    final at = needle == null ? -1 : message.indexOf(needle);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [t.brandTint, t.surfaceAlt]),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: t.secondaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.sync_alt, size: 16, color: t.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              at < 0
                  ? TextSpan(text: message, style: base)
                  : TextSpan(
                      style: base,
                      children: [
                        TextSpan(text: message.substring(0, at)),
                        TextSpan(text: needle, style: strong),
                        TextSpan(text: message.substring(at + needle!.length)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
