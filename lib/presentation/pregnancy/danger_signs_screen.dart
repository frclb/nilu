import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
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
///
/// Görünüm: acil arama belirgin ama sakin — kırmızı alarm değil, markanın
/// erik düğmesi. Telaşlı bir ekran, okunması gereken listeyi gölgeliyor.
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
        centerTitle: false,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          context.tr(
            period == DangerPeriod.pregnancy
                ? 'danger_title_pregnancy'
                : 'danger_title_postpartum',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _AcilKart(numara: numara),
              const SizedBox(height: 24),

              for (final anahtar in isaretler)
                _Isaret(metin: context.tr(anahtar)),

              if (period == DangerPeriod.pregnancy) ...[
                const SizedBox(height: 12),
                _Not(
                  icon: Icons.favorite_border_rounded,
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

              const SizedBox(height: 24),
              Text(
                context.tr('article_disclaimer'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.55,
                  color: t.textMuted,
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
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  height: 1.5,
                  letterSpacing: 0.3,
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

/// Giriş cümlesi ve acil arama.
class _AcilKart extends StatelessWidget {
  const _AcilKart({required this.numara});

  final String? numara;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final n = numara;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.flowTint, t.brandTint, t.surface],
          stops: const [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppCard.borderColor(t)),
        boxShadow: AppCard.shadow(t),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppIconTile(
              icon: Icons.medical_services_outlined,
              size: 44,
              circle: true,
              background: t.surface,
              color: t.flowText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('danger_intro'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              height: 1.25,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          if (n != null)
            _AramaDugmesi(
              label: context.tr('danger_call_emergency', params: {'n': n}),
              onTap: () =>
                  DangerSignsScreen.launcher(Uri(scheme: 'tel', path: n)),
            )
          else
            // Bölge bilinmiyorsa numara uydurulmuyor.
            Text(
              context.tr('danger_call_local'),
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: t.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Acil arama: erik hap, solda telefon dairesi, sağda ok.
class _AramaDugmesi extends StatelessWidget {
  const _AramaDugmesi({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;

    return Semantics(
      button: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primary(context),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadows.floating(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 18, 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: on.withAlpha(40),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.phone, size: 20, color: on),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: on,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20, color: on),
                ],
              ),
            ),
          ),
        ),
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
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppCard.borderColor(t)),
          boxShadow: AppCard.shadow(t),
        ),
        child: Row(
          children: [
            AppIconTile(
              icon: Icons.error_outline,
              size: 40,
              background: t.flowTint,
              color: t.flowText,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                metin,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppCard.borderColor(t)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: icon,
            size: 40,
            circle: true,
            background: t.surface,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  govde,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: t.text,
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
