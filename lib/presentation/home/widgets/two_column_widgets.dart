import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../calendar/view_models/calendar_view_model.dart';
import '../../../domain/models/log_vocabulary.dart';
import '../../../localization/relative_time.dart';

class TwoColumnWidgets extends StatelessWidget {
  const TwoColumnWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();
    final lastLog = viewModel.getLastDailyLog();

    // Son log bilgilerini belirle
    String lastLogDate = context.tr('home_today');
    String lastLogInfo = context.tr('home_no_symptoms_yet');

    if (lastLog != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final logDate = DateTime(
        lastLog.date.year,
        lastLog.date.month,
        lastLog.date.day,
      );

      if (logDate.isAtSameMomentAs(today)) {
        lastLogDate = context.tr('home_today');
      } else {
        final diff = today.difference(logDate).inDays;
        lastLogDate = context.relativeTime(Duration(days: diff));
      }

      final parts = <String>[];
      // Saklanan değerler kanonik koddur; etiketler lokalizasyondan çözülür.
      if (lastLog.flowIntensity != null) {
        parts.add(context.tr(LogVocabulary.flowKey(lastLog.flowIntensity!)));
      }
      parts.addAll(
        lastLog.symptoms
            .take(2)
            .map((code) => context.tr(LogVocabulary.symptomKey(code))),
      );
      parts.addAll(
        lastLog.moods
            .take(1)
            .map((code) => context.tr(LogVocabulary.moodKey(code))),
      );

      if (parts.isNotEmpty) {
        lastLogInfo = parts.join(', ');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                NavigationService().push(RouteNames.partner);
              },
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.tokens.border),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.favorite,
                        size: 80,
                        color: theme.colorScheme.primary.withAlpha(12),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_add_alt_1,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('home_partner_title').toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('home_partner_notified'),
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('home_partner_desc'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                NavigationService().push(RouteNames.logEntry);
              },
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('home_last_log_title').toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          Icons.edit_note,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastLogDate,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastLogInfo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
