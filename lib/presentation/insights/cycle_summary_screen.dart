import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/data_export_service.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/view_models/subscription_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../calendar/view_models/calendar_view_model.dart';

/// Hekime gösterilecek döngü özeti — ekranda ücretsiz.
///
/// Önceden bu özet yalnızca Premium dışa aktarmanın içindeydi: muayenede
/// "son reglin ne zamandı, döngün kaç gün" sorusunun cevabı ödeme
/// duvarının arkasındaydı. Gebelikteki randevu özetiyle aynı kural:
/// ekranda göstermek herkese açık, dosya olarak paylaşmak Premium.
///
/// Ekran ve dosya aynı bölüm listesinden (`DataExportService.summarySections`).
class CycleSummaryScreen extends StatelessWidget {
  const CycleSummaryScreen({super.key});

  /// Paylaşım. Testte sistem paylaşım sayfası yerine konuyor.
  static Future<void> Function(String metin, String dosyaAdi) share = _paylas;

  static Future<void> _paylas(String metin, String dosyaAdi) async {
    final dizin = await getTemporaryDirectory();
    final dosya = File('${dizin.path}/$dosyaAdi');
    await dosya.writeAsString(metin);
    await SharePlus.instance.share(ShareParams(files: [XFile(dosya.path)]));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final vm = context.watch<CalendarViewModel>();
    final premium = context.watch<SubscriptionViewModel>().isPremium;
    final now = DateTime.now();

    String tr(String key, {Map<String, String>? params}) =>
        context.tr(key, params: params);

    final sections = DataExportService.summarySections(
      periodLogs: vm.periodLogs,
      dailyLogs: vm.dailyLogs,
      translate: tr,
      breaks: vm.cycleBreaks,
    );

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(context.tr('cycle_summary_title')),
        actions: [
          IconButton(
            key: const Key('cycle_summary_share'),
            tooltip: context.tr('cycle_summary_share'),
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              if (!PremiumGate.canExportReports(isPremium: premium)) {
                context.pushNamed(RouteNames.premium);
                return;
              }
              final stamp =
                  '${now.year}${now.month.toString().padLeft(2, '0')}'
                  '${now.day.toString().padLeft(2, '0')}';
              share(
                DataExportService.buildSummary(
                  periodLogs: vm.periodLogs,
                  dailyLogs: vm.dailyLogs,
                  generatedAt: now,
                  translate: tr,
                  breaks: vm.cycleBreaks,
                ),
                'dongu-ozeti-$stamp.txt',
              );
            },
          ),
        ],
      ),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              context.tr('cycle_summary_intro'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${now.day} ${context.monthName(now.month)} ${now.year}',
              style: theme.textTheme.bodySmall?.copyWith(color: t.textFaint),
            ),
            const SizedBox(height: 16),
            for (final section in sections) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppCard.decoration(t),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final line in section.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          line,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: t.text,
                            height: 1.4,
                          ),
                        ),
                      ),
                    for (final alert in section.alerts)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 18,
                              color: t.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                alert,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: t.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              context.tr('export_footer'),
              style: theme.textTheme.bodySmall?.copyWith(color: t.textFaint),
            ),
          ],
        ),
      ),
    );
  }
}

/// Analiz ekranından özete giriş.
class CycleSummaryLink extends StatelessWidget {
  const CycleSummaryLink({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('cycle_summary_link'),
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.pushNamed(RouteNames.cycleSummary),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: AppCard.decoration(t),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('cycle_summary_title'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('cycle_summary_entry_desc'),
                      style: TextStyle(fontSize: 13, color: t.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
