import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tappable.dart';
import '../../../design_system/app_tokens.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/calendar_day.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../domain/view_models/user_view_model.dart';
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

    // Kart eskiden koşulsuzdu: partner hiç bağlı değilken bile
    // "Bilgilendirildi — hassas dönemde olduğunuzu biliyor" yazıyordu.
    // Kullanıcıya, kimsenin bilmediği bir şeyi birinin bildiğini söylemek
    // davranışını da değiştirebilir: "zaten biliyor" diye anlatmaktan
    // vazgeçebilir. Üstelik döngü verisi partnere hiç gitmiyor; giden tek
    // şey kullanıcının kendi seçip gönderdiği yakınlık durumu.
    final hasPartner = context.select<UserViewModel, bool>(
      (vm) => vm.hasPartner,
    );

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
        final diff = today.daysSince(logDate);
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

    final t = context.tokens;

    // İki kutu aynı boyda; büyük yazıda içerik uzarsa ikisi birlikte uzuyor
    // (sabit yükseklik taşma demekti).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AppTappable(
                onTap: () {
                  NavigationService().push(RouteNames.partner);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 142),
                  decoration: BoxDecoration(
                    gradient: AppGradients.blush(context),
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: t.flowTint.withAlpha(170)),
                    boxShadow: AppShadows.soft(context),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned(
                        right: -8,
                        bottom: -8,
                        child: ExcludeSemantics(
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 68,
                            color: t.secondary.withAlpha(24),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppIconTile(
                                  icon: hasPartner
                                      ? Icons.favorite_rounded
                                      : Icons.person_add_alt_1_rounded,
                                  size: 26,
                                  background: t.secondaryTint,
                                  color: t.secondary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    context.upper(
                                      context.tr('home_partner_title'),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      color: t.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr(
                                hasPartner
                                    ? 'home_partner_connected'
                                    : 'profile_partner_connect',
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: t.text,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                hasPartner
                                    ? 'home_partner_connected_desc'
                                    : 'home_partner_connect_desc',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                height: 1.4,
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTappable(
                onTap: () {
                  NavigationService().push(RouteNames.logEntry);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 142),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: AppCard.borderColor(t)),
                    boxShadow: AppShadows.soft(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.upper(context.tr('home_last_log_title')),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: t.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppIconTile(
                            icon: Icons.edit_rounded,
                            size: 26,
                            background: t.surfaceAlt,
                            color: t.textMuted,
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 10),
                      Text(
                        lastLogDate,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 19,
                          height: 1.2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastLogInfo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          height: 1.4,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const double _radius = 22;
}
