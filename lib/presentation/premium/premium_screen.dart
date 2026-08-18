import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/services/subscription_pricing.dart';
import '../../domain/view_models/subscription_view_model.dart';
import '../../localization/app_localizations.dart';

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
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubscriptionViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.tr('premium_title')),
      ),
      body: viewModel.isPremium
          ? const _ActiveState()
          : _OfferState(viewModel: viewModel),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: t.brandTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 44,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          context.tr('premium_active_title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr('premium_active_desc'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
        ),
        const SizedBox(height: AppSpacing.xxl),
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
  /// yönlendirmeyi istiyor.
  void _openManageSubscriptions(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.tr('premium_manage_hint'))),
      );
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              Text(
                context.tr('premium_subtitle'),
                style: theme.textTheme.displaySmall?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _FeatureList(),
              const SizedBox(height: AppSpacing.xxl),

              if (widget.viewModel.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (plans.isEmpty)
                _Unavailable(onRetry: widget.viewModel.fetchOfferings)
              else ...[
                Text(
                  context.tr('premium_choose_plan'),
                  style: theme.textTheme.titleMedium,
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

              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('premium_disclaimer'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.textFaint,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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

        // Satın alma çubuğu ekranın altında sabit: kullanıcı listeyi
        // kaydırırken eylemi kaybetmesin.
        if (plans.isNotEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border(top: BorderSide(color: t.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: widget.viewModel.isLoading || selectedId == null
                      ? null
                      : () => _purchase(selectedId),
                  child: Text(context.tr('premium_subscribe_button')),
                ),
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
    final messenger = ScaffoldMessenger.of(context);
    final success = context.tr('premium_purchase_success');
    final failed = context.tr('premium_purchase_failed');
    final unavailable = context.tr('premium_unavailable');

    final package = widget.viewModel.packageFor(planId);
    if (package == null) {
      _show(messenger, unavailable);
      return;
    }

    final purchased = await widget.viewModel.purchasePackage(package);
    _show(messenger, purchased ? success : failed);
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    final checking = context.tr('premium_restore_checking');
    final restored = context.tr('premium_restore_success');
    final nothing = context.tr('premium_restore_none');

    _show(messenger, checking);
    final ok = await widget.viewModel.restorePurchases();
    _show(messenger, ok ? restored : nothing);
  }

  void _show(ScaffoldMessengerState messenger, String text) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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

    return Material(
      color: selected ? t.brandTint : t.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? primary : t.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? primary : t.textFaint,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.tr(plan.period.labelKey),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _Badge(
                            text: context.tr('premium_best_value'),
                            color: primary,
                          ),
                        ],
                      ],
                    ),
                    if (plan.introOffer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          'premium_intro_offer',
                          params: {'price': plan.introOffer!},
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (saving != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          'premium_saving',
                          params: {'percent': '$saving'},
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                plan.priceString,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Premium'un gerçekten açtıkları.
///
/// Liste `PremiumGate` ile aynı gerçeği anlatır; paywall'da yazan ile
/// uygulamada olan ayrışmasın.
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.timeline,
        'premium_feature_history_title',
        'premium_feature_history_desc',
      ),
      (
        Icons.insights,
        'premium_feature_phase_title',
        'premium_feature_phase_desc',
      ),
      (
        Icons.ios_share,
        'premium_feature_export_title',
        'premium_feature_export_desc',
      ),
      (
        Icons.palette_outlined,
        'premium_feature_themes_title',
        'premium_feature_themes_desc',
      ),
    ];

    return Column(
      children: [
        for (final (icon, title, desc) in features) ...[
          _FeatureRow(icon: icon, titleKey: title, descKey: desc),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String descKey;

  const _FeatureRow({
    required this.icon,
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: t.brandTint,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr(titleKey), style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                context.tr(
                  descKey,
                  params: {'free': '${PremiumGate.freeCycleHistory}'},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.textMuted,
                  height: 1.4,
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

    return Column(
      children: [
        Icon(Icons.cloud_off, size: 32, color: t.textFaint),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr('premium_unavailable'),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: onRetry,
          child: Text(context.tr('premium_retry')),
        ),
      ],
    );
  }
}
