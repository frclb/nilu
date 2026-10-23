import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../design_system/phase_colors.dart';
import '../../../../design_system/app_tokens.dart';
import '../../../../domain/models/cycle_info.dart';
import '../../../../domain/services/phase_guide.dart';
import '../view_models/calendar_view_model.dart';
import 'day_detail_bottom_sheet.dart';

/// Seçili günün kayıt özeti.
///
/// Tarih ve döngü günü başlığı burada değil [CalendarDayHeader]'da; bu bölüm
/// yalnızca o güne girilmiş veriyi (akış, ruh hâli, semptom, not) gösterir.
class CalendarSummarySection extends StatelessWidget {
  const CalendarSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.tokens;
    final primary = theme.colorScheme.primary;
    final viewModel = context.watch<CalendarViewModel>();
    final selectedDate = viewModel.selectedDate;
    final dailyLog = viewModel.getDailyLogForDate(selectedDate);

    // Başlık seçili güne göre değişir: başka bir gün seçiliyken "Bugünün
    // özeti" demek yanıltıcı oluyordu.
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    // Gerçek veri kontrolü
    final hasFlow = dailyLog.flowIntensity != null;
    final hasMoods = dailyLog.moods.isNotEmpty;
    final hasSymptoms = dailyLog.symptoms.isNotEmpty;
    final hasNotes = dailyLog.notes != null && dailyLog.notes!.isNotEmpty;
    final hasAnyData = hasFlow || hasMoods || hasSymptoms || hasNotes;

    final phase = viewModel.phaseForDate(selectedDate);
    // Gebelik ve lohusalıkta döngü evresi yok: blok "regl günlerini
    // işaretledikçe tahminler netleşir" diyordu, oysa o evrede tahmin yok.
    final evreVar = viewModel.lifeStage.showsCyclePredictions;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Başlığın solundaki küçük vurgu çizgisi.
                Container(
                  width: 5,
                  height: 16,
                  decoration: BoxDecoration(
                    color: t.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.tr(
                        isToday
                            ? 'calendar_today_summary'
                            : 'calendar_day_summary',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => showDayDetailSheet(context, selectedDate),
                  tooltip: context.tr('calendar_add_note'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: t.brandTint,
                    foregroundColor: primary,
                    fixedSize: const Size(36, 36),
                    minimumSize: const Size(36, 36),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Kayıt çipleri — gerçek veriye göre
            if (hasFlow || hasMoods || hasSymptoms)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasFlow)
                    _SummaryChip(
                      icon: Icons.water_drop,
                      iconColor: t.flow,
                      label: context.tr(
                        LogVocabulary.flowKey(dailyLog.flowIntensity!),
                      ),
                    ),
                  if (hasMoods)
                    ...dailyLog.moods.map(
                      (mood) => _SummaryChip(
                        icon: Icons.sentiment_satisfied_alt,
                        iconColor: t.accent,
                        label: context.tr(LogVocabulary.moodKey(mood)),
                      ),
                    ),
                  if (hasSymptoms)
                    ...dailyLog.symptoms
                        .take(3)
                        .map(
                          (symptom) => _SummaryChip(
                            icon: Icons.healing,
                            iconColor: t.ovulation,
                            label: context.tr(
                              LogVocabulary.symptomKey(symptom),
                            ),
                          ),
                        ),
                ],
              )
            else if (!hasAnyData)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  context.tr('calendar_no_log_yet'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: t.textMuted,
                  ),
                ),
              ),

            // Notlar (gerçek veriden)
            if (hasNotes) ...[
              if (hasFlow || hasMoods || hasSymptoms)
                const SizedBox(height: 14),
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
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 20,
                      color: t.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('log_notes'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dailyLog.notes!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Seçili günün evresine göre içerik.
            //
            // Burada eskiden her gün için aynı sabit öneri yazıyordu;
            // hangi güne dokunulursa dokunulsun metin değişmiyordu.
            if (evreVar) ...[
              const SizedBox(height: 16),
              _PhaseGuidanceBlock(phase: phase, isDark: isDark),
            ],
          ],
        ),
      ),
    );
  }
}

/// Özet çipi: renkli simge + etiket, gül tülü zeminde.
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seçili günün evresine göre "vücudunda ne oluyor" ve kısa öneri.
///
/// Renk evreden geliyor; takvimde o günün boyandığı renkle aynı olsun diye.
class _PhaseGuidanceBlock extends StatelessWidget {
  const _PhaseGuidanceBlock({required this.phase, required this.isDark});

  final CyclePhase phase;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final guidance = PhaseGuide.forPhase(phase);
    final phaseColor = phase.color(t);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            phaseColor.withAlpha(isDark ? 40 : 26),
            phaseColor.withAlpha(isDark ? 16 : 8),
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: phaseColor.withAlpha(isDark ? 56 : 36),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.autorenew, size: 20, color: phaseColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.tr(guidance.titleKey),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: phaseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(guidance.bodyKey),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.accentTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: t.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr(guidance.tipKey),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12.5,
                            height: 1.45,
                            color: t.text,
                          ),
                        ),
                      ),
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
}
