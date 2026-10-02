import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/emergency_number.dart';
import '../../localization/app_localizations.dart';

/// Hangi dönemin tehlike işaretleri.
enum DangerPeriod { pregnancy, postpartum }

/// Hemen başvurmayı gerektiren işaretler.
///
/// Teşhis koymuyor, yönlendiriyor (kanama değerlendirmesinin duruşu).
/// Listeler kendim yazdığım değil, T.C. Sağlık Bakanlığı'nın: Doğum Öncesi
/// ve Doğum Sonu Bakım Yönetim Rehberleri (Ankara 2018). Doğum sonu ruh
/// sağlığı maddesi o listede yok; NHS ve Royal College of Psychiatrists'e
/// göre doğum sonu psikoz psikiyatrik acil durum olduğu için ayrı bölümde.
///
/// Gebelikte bebek hareketleri için **sayaç yok**: RCOG Green-top 57 ve
/// Bakanlık listesi ikisi de sayım değil, azalmayı bildirmeyi söylüyor.
class DangerSignsScreen extends StatelessWidget {
  const DangerSignsScreen({
    super.key,
    required this.period,
    @visibleForTesting this.regionOverride,
  });

  final DangerPeriod period;

  /// Testte cihaz bölgesinin yerine.
  final String? regionOverride;

  /// Test edilebilirlik için arama çağrısı ayrık.
  @visibleForTesting
  static Future<bool> Function(Uri uri) launcher = launchUrl;

  static const List<String> pregnancySigns = [
    'danger_preg_bleeding',
    'danger_preg_movements',
    'danger_preg_fluid',
    'danger_preg_abdominal_pain',
    'danger_preg_headache',
    'danger_preg_vision',
    'danger_preg_swelling',
    'danger_preg_convulsion',
    'danger_preg_breathing',
    'danger_preg_fever',
    'danger_preg_vomiting',
    'danger_preg_itching',
    'danger_preg_daily_activities',
  ];

  static const List<String> postpartumSigns = [
    'danger_pp_bleeding',
    'danger_pp_breathing',
    'danger_pp_fever',
    'danger_pp_discharge',
    'danger_pp_headache',
    'danger_pp_convulsion',
    'danger_pp_consciousness',
    'danger_pp_urination',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final bolge =
        regionOverride ??
        View.of(context).platformDispatcher.locale.countryCode;
    final numara = EmergencyNumber.forRegion(bolge);
    final isaretler = period == DangerPeriod.pregnancy
        ? pregnancySigns
        : postpartumSigns;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(
          context.tr(
            period == DangerPeriod.pregnancy
                ? 'danger_title_pregnancy'
                : 'danger_title_postpartum',
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _AcilKart(numara: numara),
              const SizedBox(height: 20),

              for (final anahtar in isaretler)
                _Isaret(metin: context.tr(anahtar)),

              if (period == DangerPeriod.pregnancy) ...[
                const SizedBox(height: 12),
                _Not(
                  icon: Icons.favorite_border,
                  baslik: context.tr('danger_movements_note_title'),
                  govde: context.tr('danger_movements_note_body'),
                ),
              ],

              if (period == DangerPeriod.postpartum) ...[
                const SizedBox(height: 12),
                _Not(
                  icon: Icons.psychology_outlined,
                  baslik: context.tr('danger_pp_mental_title'),
                  govde: context.tr('danger_pp_mental_body'),
                ),
              ],

              const SizedBox(height: 20),
              Text(
                context.tr('article_disclaimer'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  height: 1.55,
                  color: t.textFaint,
                ),
              ),
              const SizedBox(height: 8),
              // Kaynak adları özel ad: çevrilmiyor.
              Text(
                period == DangerPeriod.pregnancy
                    ? 'T.C. Sağlık Bakanlığı — Doğum Öncesi Bakım Yönetim '
                          'Rehberi (2018) · RCOG Green-top Guideline No. 57'
                    : 'T.C. Sağlık Bakanlığı — Doğum Sonu Bakım Yönetim '
                          'Rehberi (2018) · NHS inform — Postpartum psychosis',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: t.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcilKart extends StatelessWidget {
  const _AcilKart({required this.numara});

  final String? numara;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final n = numara;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.brandTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('danger_intro'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          const SizedBox(height: 12),
          if (n != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    DangerSignsScreen.launcher(Uri(scheme: 'tel', path: n)),
                icon: const Icon(Icons.phone, size: 20),
                label: Text(
                  context.tr('danger_call_emergency', params: {'n': n}),
                ),
              ),
            )
          else
            // Bölge bilinmiyorsa numara uydurulmuyor.
            Text(
              context.tr('danger_call_local'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: t.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _Isaret extends StatelessWidget {
  const _Isaret({required this.metin});

  final String metin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 22, color: t.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                metin,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 1.5,
                  color: t.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Not extends StatelessWidget {
  const _Not({required this.icon, required this.baslik, required this.govde});

  final IconData icon;
  final String baslik;
  final String govde;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  govde,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 14,
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
