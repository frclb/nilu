import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/navigation/route_names.dart';
import '../../core/platform/app_platform.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/brand_lotus.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/services/subscription_pricing.dart';
import '../../domain/view_models/subscription_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

/// Premium tanıtım ve satın alma ekranı.
///
/// İki şey yeniden yazıldı:
///
/// 1. **Fiyatlar mağazadan geliyor.** Öncesinde üç sabit kart vardı ve
///    fiyatları lokalizasyon dosyalarından okunuyordu — Almanca ve Fransızca
///    kullanıcıya **dolar** gösteriliyordu, mağazadaki fiyat değişince ekran
///    eskisini göstermeye devam ediyordu, tanıtım teklifleri hiç
///    görünmüyordu. Bu tek başına inceleme reddi sebebi.
/// 2. **Abone durumu var.** Öncesinde abone olan kullanıcı da aynı satış
///    ekranını görüyordu.
///
/// Özellik listesi de gerçeğe uyduruldu: eskiden beş şey vaat ediyordu,
/// biri zaten ücretsizdi (uygulama kilidi), üçü hiç yoktu.
///
/// Ücretsiz deneme yazılmıyor: deneme ancak mağaza bir tanıtım teklifi
/// sunuyorsa, mağazanın kendi metniyle plan kartında görünüyor.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubscriptionViewModel>();
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            style: IconButton.styleFrom(backgroundColor: t.surfaceAlt),
            icon: Icon(Icons.close, color: t.text),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.soft(context),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 15, color: t.secondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.tr('premium_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 19,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: AmbientBackground(
        child: AppContentWidth(
          child: viewModel.isPremium
              ? const _ActiveState()
              : _OfferState(viewModel: viewModel),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Abone
// ══════════════════════════════════════════════════════════════

class _ActiveState extends StatelessWidget {
  const _ActiveState();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: AppIconTile(
            icon: Icons.workspace_premium,
            size: 88,
            circle: true,
            gradient: AppGradients.mark(context),
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.tr('premium_active_title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('premium_active_desc'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _FeatureList(),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () => _openManageSubscriptions(context),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(context.tr('premium_manage')),
        ),
      ],
    );
  }

  /// Aboneliği yönetme mağazanın işi.
  ///
  /// Apple, uygulama içinde iptal düğmesi koymayı değil sistem ayarlarına
  /// yönlendirmeyi istiyor; yol tarif ediliyor. Google Play'in abonelikler
  /// sayfası ise bir bağlantı: doğrudan açılıyor, açılamazsa yol tarif
  /// ediliyor.
  Future<void> _openManageSubscriptions(BuildContext context) async {
    final snack = AppSnack.of(context);
    final hint = context.tr(
      AppPlatform.isAndroid
          ? 'premium_manage_hint_android'
          : 'premium_manage_hint',
    );
    if (AppPlatform.isAndroid) {
      try {
        final opened = await launchUrl(
          Uri.parse(AppPlatform.playSubscriptionsUrl),
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      } catch (e) {
        debugPrint('Could not open Play subscriptions: $e');
      }
    }
    snack.show(hint);
  }
}

// ══════════════════════════════════════════════════════════════
// Abone değil
// ══════════════════════════════════════════════════════════════

class _OfferState extends StatefulWidget {
  final SubscriptionViewModel viewModel;

  const _OfferState({required this.viewModel});

  @override
  State<_OfferState> createState() => _OfferStateState();
}

class _OfferStateState extends State<_OfferState> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final plans = widget.viewModel.plans;
    final recommended = SubscriptionPricing.best(plans);

    // Varsayılan seçim en iyi teklif; kullanıcı değiştirebilir.
    final selectedId = _selectedId ?? recommended?.id;

    return Column(
      children: [
        Expanded(
          // Tembel liste değil: sayfa kısa, ve sonundaki otomatik yenileme
          // bildirimi ile şartlar katlamanın altında kalsa da ekranın
          // parçası olarak hep kurulu kalmalı. `ListView` görünür alanın
          // uzağındaki öğeleri kurmuyor.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Hero(),
                const SizedBox(height: AppSpacing.lg),
                const _FeatureList(),
                const SizedBox(height: AppSpacing.xl),

                if (widget.viewModel.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (plans.isEmpty)
                  _Unavailable(onRetry: widget.viewModel.fetchOfferings)
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: AppSectionLabel(context.tr('premium_choose_plan')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final plan in plans) ...[
                    _PlanCard(
                      plan: plan,
                      all: plans,
                      selected: plan.id == selectedId,
                      recommended: plan.id == recommended?.id,
                      onTap: () => setState(() => _selectedId = plan.id),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],

                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr(
                    AppPlatform.isAndroid
                        ? 'premium_disclaimer_android'
                        : 'premium_disclaimer',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.privacyPolicy),
                      child: Text(context.tr('premium_privacy')),
                    ),
                    Text('·', style: TextStyle(color: t.textFaint)),
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.termsOfService),
                      child: Text(context.tr('premium_terms')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Satın alma çubuğu ekranın altında sabit: kullanıcı listeyi
        // kaydırırken eylemi kaybetmesin.
        if (plans.isNotEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              AppSpacing.md,
              20,
              MediaQuery.of(context).padding.bottom + AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: t.background,
              boxShadow: AppShadows.soft(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppGradientButton(
                  label: context.tr('premium_subscribe_button'),
                  icon: Icons.spa,
                  height: 56,
                  radius: AppRadius.pill,
                  busy: widget.viewModel.isLoading,
                  onPressed: selectedId == null
                      ? null
                      : () => _purchase(selectedId),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: widget.viewModel.isLoading ? null : _restore,
                  child: Text(context.tr('premium_restore_purchases')),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _purchase(String planId) async {
    final snack = AppSnack.of(context);
    final success = context.tr('premium_purchase_success');
    final failed = context.tr('premium_purchase_failed');
    final unavailable = context.tr('premium_unavailable');

    final package = widget.viewModel.packageFor(planId);
    if (package == null) {
      snack.error(unavailable);
      return;
    }

    final purchased = await widget.viewModel.purchasePackage(package);
    // Başarısızlığın çoğu kullanıcının vazgeçmesi: hata titreşimi yok.
    purchased ? snack.success(success) : snack.show(failed);
  }

  Future<void> _restore() async {
    final snack = AppSnack.of(context);
    final checking = context.tr('premium_restore_checking');
    final restored = context.tr('premium_restore_success');
    final nothing = context.tr('premium_restore_none');

    snack.show(checking);
    final ok = await widget.viewModel.restorePurchases();
    ok ? snack.success(restored) : snack.show(nothing);
  }
}

// ══════════════════════════════════════════════════════════════

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final List<SubscriptionPlan> all;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.all,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final saving = SubscriptionPricing.savingPercent(plan, all);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: selected
              ? AppShadows.floating(context)
              : AppShadows.soft(context),
        ),
        child: Material(
          color: selected ? t.brandTint : t.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected ? primary : AppCard.borderColor(t),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recommended) ...[
                    _Badge(text: context.tr('premium_best_value')),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(plan.period.labelKey),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                color: t.text,
                              ),
                            ),
                            if (plan.introOffer != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                context.tr(
                                  'premium_intro_offer',
                                  params: {'price': plan.introOffer!},
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: t.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (saving != null) ...[
                              const SizedBox(height: 2),
                              // Ekrandaki en ikna edici sayı en soluk
                              // renkteydi.
                              Text(
                                context.tr(
                                  'premium_saving',
                                  params: {'percent': '$saving'},
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: t.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        plan.priceString,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: selected ? primary : t.text,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _Check(selected: selected),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seçim işareti: seçiliyken dolu erik daire içinde tik.
class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : t.surfaceAlt,
        border: selected ? null : Border.all(color: t.border),
      ),
      child: selected
          ? Icon(Icons.check, size: 16, color: scheme.onPrimary)
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: t.secondary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 14, color: scheme.onSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paywall'ın açılış bloğu.
///
/// Ekran düz bir başlıkla açılıyordu: uygulamanın rengi, markası, hiçbir şeyi
/// görünmüyordu. Satın alma ekranı ürünün en pahalı ekranı; ücretsiz sürümden
/// farklı hissettirmesi gerekiyor.
///
/// Renkler temadan türetiliyor, paletten değil. Sabit plum yazmak premium
/// tema çeşitlerini (ocean/forest/graphite) kırardı: kullanıcı ödediği temayı
/// seçer, bu blok marka pembesinde kalırdı.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final t = context.tokens;
    final dark = theme.brightness == Brightness.dark;

    // Degradenin koyu ucu birincil rengin kendisinden: hangi tema seçiliyse
    // o rengin koyusu. Koyu temada birincil renk açık bir pembe; blok onunla
    // dolunca ekranın en parlak yüzeyi oluyordu. Orada zemin birincil rengin
    // yüzeye karışmış koyu tonu, yazı gövde metni rengi.
    final hsl = HSLColor.fromColor(primary);
    final Color top;
    final Color deep;
    final Color onPrimary;
    if (dark) {
      top = Color.lerp(t.surface, primary, 0.34)!;
      deep = Color.lerp(t.surface, primary, 0.16)!;
      onPrimary = t.text;
    } else {
      top = primary;
      deep = hsl.withLightness((hsl.lightness * 0.6).clamp(0.0, 1.0)).toColor();
      onPrimary = theme.colorScheme.onPrimary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, deep],
        ),
        boxShadow: AppShadows.floating(context),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: onPrimary.withAlpha(30),
              borderRadius: BorderRadius.circular(AppRadius.md + 4),
            ),
            child: BrandLotus(color: onPrimary, sideOpacity: 0.55),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('premium_subtitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              height: 1.2,
              color: onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium'un gerçekten açtıkları.
///
/// Liste `PremiumGate` ile aynı gerçeği anlatır; paywall'da yazan ile
/// uygulamada olan ayrışmasın. Uygulama kilidi, yedek ve gebelik modu
/// ücretsiz; burada sayılmıyorlar.
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final features = [
      (
        Icons.stacked_line_chart,
        primary,
        'premium_feature_history_title',
        'premium_feature_history_desc',
      ),
      (
        Icons.insights,
        t.secondary,
        'premium_feature_phase_title',
        'premium_feature_phase_desc',
      ),
      (
        Icons.ios_share,
        t.accent,
        'premium_feature_export_title',
        'premium_feature_export_desc',
      ),
      (
        Icons.palette_outlined,
        t.ovulationText,
        'premium_feature_themes_title',
        'premium_feature_themes_desc',
      ),
      (
        Icons.block_outlined,
        primary,
        'premium_feature_noads_title',
        'premium_feature_noads_desc',
      ),
    ];

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _FeatureRow(
              icon: features[i].$1,
              color: features[i].$2,
              titleKey: features[i].$3,
              descKey: features[i].$4,
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titleKey;
  final String descKey;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.descKey,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconTile(
          icon: icon,
          size: 40,
          color: color,
          background: t.surfaceAlt,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(titleKey),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr(
                  descKey,
                  params: {'free': '${PremiumGate.freeCycleHistory}'},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.textMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _Unavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 32, color: t.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('premium_unavailable'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            child: Text(context.tr('premium_retry')),
          ),
        ],
      ),
    );
  }
}
