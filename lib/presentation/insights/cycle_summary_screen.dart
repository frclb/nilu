import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
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

    void paylas() {
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
    }

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          context.tr('cycle_summary_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 21,
            color: t.text,
          ),
        ),
      ),
      // Paylaşım ekranın altında sabit: muayenede liste kaydırılırken
      // eylem kaybolmasın. Ücretsiz kullanıcıda kilit simgesi — dosya
      // Premium'da, ekrandaki özet herkese açık.
      bottomNavigationBar: _ShareBar(premium: premium, onShare: paylas),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${now.day} ${context.monthName(now.month)} ${now.year}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconTile(
                    icon: Icons.assignment_outlined,
                    circle: true,
                    background: t.surfaceAlt,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.tr('cycle_summary_intro'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: t.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final section in sections) ...[
              for (final alert in section.alerts) ...[
                _AlertCallout(text: alert),
                const SizedBox(height: 12),
              ],
              _SectionCard(
                section: section,
                icon: section == sections.first && sections.length > 1
                    ? Icons.analytics_outlined
                    : Icons.history,
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 4),
            Icon(
              Icons.medical_information_outlined,
              size: 18,
              color: t.textFaint,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('export_footer'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.5,
                color: t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir özet bölümü: başlık ve satırlar.
///
/// Satırlar dosyadaki satırların aynısı; yalnızca "etiket: değer"
/// biçimindekilerde değer kalın yazılıyor. Metin bölünmüyor — ekranda
/// görünen cümle dosyadaki cümleyle birebir aynı kalmalı.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.icon});

  final SummarySection section;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    section.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final line in section.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: t.brandTint.withAlpha(170),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: _Line(line),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Etiket: değer" ya da "tarih — süre" satırında değer kalın.
class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium?.copyWith(
      color: t.text,
      height: 1.4,
    );
    final strong = base?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.primary,
    );

    var at = text.indexOf(': ');
    var sepLength = 2;
    if (at < 0) {
      at = text.lastIndexOf(' — ');
      sepLength = 3;
    }
    if (at <= 0 || at + sepLength >= text.length) {
      return Text(text, style: base);
    }
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, at + sepLength)),
          TextSpan(text: text.substring(at + sepLength), style: strong),
        ],
      ),
    );
  }
}

/// Özet bölümündeki uyarı (ör. regl dışında kanama).
class _AlertCallout extends StatelessWidget {
  const _AlertCallout({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.secondaryTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 22, color: t.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alttaki sabit paylaşım çubuğu.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.premium, required this.onShare});

  final bool premium;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: t.background,
        boxShadow: AppShadows.soft(context),
      ),
      child: AppContentWidth(
        child: AppGradientButton(
          key: const Key('cycle_summary_share'),
          label: context.tr('cycle_summary_share'),
          icon: premium ? Icons.ios_share : Icons.lock_outline,
          radius: AppRadius.pill,
          onPressed: onShare,
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
    final theme = Theme.of(context);
    final (top, bottom, onPrimary) = _plumCard(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        boxShadow: AppShadows.floating(context),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('cycle_summary_link'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.pushNamed(RouteNames.cycleSummary),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: onPrimary.withAlpha(38),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    size: 26,
                    color: onPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cycle_summary_title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 21,
                          color: onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('cycle_summary_entry_desc'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          height: 1.4,
                          color: onPrimary.withAlpha(215),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: onPrimary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward, size: 20, color: onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Koyu erik kartın degradesi ve üstündeki yazı rengi.
///
/// Açık temada birincil renk ve onun koyusu, yazı `onPrimary`. Koyu temada
/// birincil renk açık bir pembe; kartı onunla doldurmak ekranın en parlak
/// yüzeyini yapıyordu. Orada zemin, birincil rengin yüzeye karışmış koyu
/// tonu, yazı gövde metni rengi.
(Color, Color, Color) _plumCard(BuildContext context) {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;
  final t = context.tokens;
  if (theme.brightness == Brightness.dark) {
    return (
      Color.lerp(t.surface, primary, 0.34)!,
      Color.lerp(t.surface, primary, 0.16)!,
      t.text,
    );
  }
  final hsl = HSLColor.fromColor(primary);
  final deep = hsl
      .withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0))
      .toColor();
  return (primary, deep, theme.colorScheme.onPrimary);
}
