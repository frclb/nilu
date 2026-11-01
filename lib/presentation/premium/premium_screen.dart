import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
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

  /// Sütunun en geniş hâli. iPad'de plan kartları ve satırlar ekranın
  /// yarısına yayılınca satın alma ekranı bir form gibi duruyordu.
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubscriptionViewModel>();
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.background,
      body: AmbientBackground(
        child: SafeArea(
          child: AppContentWidth(
            maxWidth: maxWidth,
            child: viewModel.isPremium
                ? const _ActiveState()
                : _OfferState(viewModel: viewModel),
          ),
        ),
      ),
    );
  }
}

/// Solda kapatma, ortada "Nilu Premium", sağda isteğe bağlı bir eylem.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.markInPill, this.trailing});

  static const double height = 52;

  /// Logo büyük hâliyle sayfada yoksa etiketin içinde küçük hâli.
  final bool markInPill;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: SizedBox(
        height: height - 4,
        // Orta parça ortalanıyor; iki yan eşit olmasa da (Almanca "geri
        // yükle" uzun) çakışmadan kayıyor.
        child: NavigationToolbar(
          middleSpacing: 8,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            style: IconButton.styleFrom(backgroundColor: t.surfaceAlt),
            icon: Icon(Icons.close, color: t.text),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // Büyük yazıda iki yandaki düğmelerle sığmazsa kesilmek yerine
          // küçülüyor.
          middle: FittedBox(
            fit: BoxFit.scaleDown,
            child: _PremiumPill(withMark: markInPill),
          ),
          trailing: trailing,
        ),
      ),
    );
  }
}

/// "Nilu Premium" etiketi.
class _PremiumPill extends StatelessWidget {
  const _PremiumPill({required this.withMark});

  final bool withMark;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: EdgeInsets.fromLTRB(withMark ? 5 : 12, 5, 12, 5),
      decoration: BoxDecoration(
        color: t.secondaryTint.withAlpha(160),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withMark)
            const _GlowMark(size: 22, glow: false)
          else
            Icon(Icons.auto_awesome, size: 14, color: t.secondary),
          const SizedBox(width: 6),
          Text(
            '${AppInfo.displayName} ${context.tr('premium_title')}',
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: t.secondary,
            ),
          ),
        ],
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

    return Column(
      children: [
        const _TopBar(markInPill: false),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const SizedBox(height: AppSpacing.lg),
              const Center(child: _GlowMark(size: 80)),
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
              const AppCard(child: _Features(gap: 16)),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => _openManageSubscriptions(context),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(context.tr('premium_manage')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Aboneliği yönetme mağazanın işi: mağazanın abonelikler sayfası
  /// doğrudan açılıyor, açılamazsa yol tarif ediliyor.
  ///
  /// iOS'ta önceden yalnızca yol tarif ediliyordu ("Ayarlar → Apple
  /// Kimliği → Abonelikler"); TestFlight'ta "direkt ayarlara gönderebilir
  /// miyiz" diye soruldu. App Store'un abonelikler bağlantısı hesabın
  /// Abonelikler ekranını açıyor.
  Future<void> _openManageSubscriptions(BuildContext context) async {
    final snack = AppSnack.of(context);
    final hint = context.tr(
      AppPlatform.isAndroid
          ? 'premium_manage_hint_android'
          : 'premium_manage_hint',
    );
    try {
      final opened = await launchUrl(
        Uri.parse(AppPlatform.subscriptionsUrl),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (e) {
      debugPrint('Could not open store subscriptions: $e');
    }
    snack.show(hint);
  }
}

// ══════════════════════════════════════════════════════════════
// Abone değil
// ══════════════════════════════════════════════════════════════

/// Satış ekranı **kaydırılmıyor**: başlık, özellikler, planlar, yenileme
/// koşulları, düğme ve yasal bağlantılar her telefonda tek ekranda.
///
/// Önceden bir liste vardı ve satın alma çubuğu altta sabitti. Küçük
/// telefonda özellikler ve şartlar katlamanın altında kalıyordu; büyük
/// telefonda ise ekranın yarısı boşken kullanıcı yine kaydırmak zorundaydı.
///
/// Sığdırma iki kademeli (bkz. [_Density] ve `AppFitToScreen`): önce yükseklik
/// sınıfına göre süs küçülüyor — bilgi değil; o da yetmezse (en küçük
/// telefon ve büyük yazı ayarı) içerik orantılı olarak küçülüyor.
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
    final vm = widget.viewModel;
    final plans = vm.plans;
    final recommended = SubscriptionPricing.best(plans);

    // Varsayılan seçim en iyi teklif; kullanıcı değiştirebilir.
    final selectedId = _selectedId ?? recommended?.id;
    final selected = plans.where((p) => p.id == selectedId).firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final d = _Density.of(constraints.maxHeight - _TopBar.height);
        return Column(
          children: [
            _TopBar(
              markInPill: d.mark == 0,
              trailing: TextButton(
                onPressed: vm.isLoading ? null : _restore,
                child: Text(
                  context.tr('premium_restore_short'),
                  semanticsLabel: context.tr('premium_restore_purchases'),
                ),
              ),
            ),
            Expanded(
              child: AppFitToScreen(
                fitKey: const Key('premium_fit'),
                maxHeight: _Density.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      _Hero(density: d),
                      SizedBox(height: d.gap),
                      const Spacer(),
                      _Features(gap: d.featureGap),
                      SizedBox(height: d.gap),
                      const Spacer(),

                      // Planlar yüklenirken de yer tutuluyor: geldiklerinde
                      // ekran zıplamasın. Satın alma sürerken de liste
                      // yerinde kalıyor; yalnızca düğme meşgul.
                      if (plans.isNotEmpty)
                        _PlanPicker(
                          plans: plans,
                          selectedId: selectedId,
                          recommendedId: recommended?.id,
                          onSelect: (id) => setState(() => _selectedId = id),
                        )
                      else if (vm.isLoading)
                        const SizedBox(
                          height: 96,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        _Unavailable(onRetry: vm.fetchOfferings),

                      if (selected != null) ...[
                        const SizedBox(height: 10),
                        _RenewalSummary(plan: selected),
                      ],
                      if (plans.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        AppGradientButton(
                          label: context.tr('premium_subscribe_button'),
                          icon: Icons.spa,
                          height: 52,
                          radius: AppRadius.pill,
                          busy: vm.isLoading,
                          onPressed: selectedId == null
                              ? null
                              : () => _purchase(selectedId),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        context.tr(
                          AppPlatform.isAndroid
                              ? 'premium_disclaimer_android'
                              : 'premium_disclaimer',
                        ),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: t.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const _LegalLinks(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

/// Ekran yüksekliğine göre süsün ölçüsü. Bilgi hiçbir sınıfta düşmüyor.
///
/// Sınırlar telefonlardan: satış alanı iPhone SE'de ~595 pt, mini'de ~675,
/// 16e ve 17'de ~710–730, Pro Max'te ~810; iPad mini yatayda ~650.
class _Density {
  const _Density({
    required this.mark,
    required this.title,
    required this.gap,
    required this.featureGap,
  });

  /// Büyük işaretin çapı; 0 ise işaret başlığın yanında küçük.
  final double mark;
  final double title;

  /// Bölümler arası en az boşluk; fazlası [Spacer]'larda.
  final double gap;
  final double featureGap;

  /// Bundan uzun ekranda (iPad dikey) içerik ortada toplu duruyor; satırlar
  /// ekranın boyuna dağılınca birbirinden kopuk görünüyordu.
  static const double maxHeight = 860;

  static _Density of(double height) {
    if (height < 680) {
      return const _Density(mark: 0, title: 23, gap: 10, featureGap: 6);
    }
    if (height < 780) {
      return const _Density(mark: 48, title: 24, gap: 14, featureGap: 10);
    }
    return const _Density(mark: 64, title: 28, gap: 20, featureGap: 13);
  }
}

/// Paywall'ın açılış bloğu: ışıyan logo ve başlık.
///
/// Ekran düz bir başlıkla açılıyordu: uygulamanın rengi, markası, hiçbir şeyi
/// görünmüyordu. Satın alma ekranı ürünün en pahalı ekranı; ücretsiz sürümden
/// farklı hissettirmesi gerekiyor. Küçük telefonda logo üst çubuktaki
/// etikete iniyor.
///
/// Renkler temadan türetiliyor, paletten değil: premium tema çeşitlerinde
/// (okyanus, orman, grafit) blok kullanıcının seçtiği renkte.
class _Hero extends StatelessWidget {
  const _Hero({required this.density});

  final _Density density;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (density.mark > 0) ...[
          _GlowMark(size: density.mark),
          SizedBox(height: density.mark * 0.3),
        ],
        Text(
          context.tr('premium_subtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: density.title,
            height: 1.15,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

/// Logo dairesi; satış ekranında arkasında kendi renginde bir ışıma.
class _GlowMark extends StatelessWidget {
  const _GlowMark({required this.size, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.mark(context),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: t.markStart.withAlpha(dark ? 120 : 70),
                  blurRadius: size * 0.55,
                  spreadRadius: size * 0.04,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: const BrandLotus(color: AppGradients.onMark, sideOpacity: 0.8),
    );
  }
}

/// Premium'un gerçekten açtıkları.
///
/// Liste `PremiumGate` ile aynı gerçeği anlatır; paywall'da yazan ile
/// uygulamada olan ayrışmasın. Uygulama kilidi, yedek ve gebelik modu
/// ücretsiz; burada sayılmıyorlar.
///
/// Açıklamalar tek satırlık: önceki iki-üç satırlık açıklamalarla liste
/// tek başına küçük bir telefonun yarısını kaplıyordu.
class _Features extends StatelessWidget {
  const _Features({required this.gap});

  final double gap;

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

    return Column(
      children: [
        for (var i = 0; i < features.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _FeatureRow(
            icon: features[i].$1,
            color: features[i].$2,
            titleKey: features[i].$3,
            descKey: features[i].$4,
          ),
        ],
      ],
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
    final dark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        AppIconTile(
          icon: icon,
          size: 34,
          color: color,
          background: color.withAlpha(dark ? 38 : 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(titleKey),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14.5,
                  height: 1.2,
                  color: t.text,
                ),
              ),
              Text(
                context.tr(
                  descKey,
                  params: {'free': '${PremiumGate.freeCycleHistory}'},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  color: t.textMuted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Planlar yan yana; dörtten fazlaysa alt alta.
class _PlanPicker extends StatelessWidget {
  const _PlanPicker({
    required this.plans,
    required this.selectedId,
    required this.recommendedId,
    required this.onSelect,
  });

  final List<SubscriptionPlan> plans;
  final String? selectedId;
  final String? recommendedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget card(SubscriptionPlan plan, {required bool wide}) => _PlanCard(
      plan: plan,
      all: plans,
      wide: wide,
      selected: plan.id == selectedId,
      recommended: plan.id == recommendedId,
      onTap: () => onSelect(plan.id),
    );

    // Rozet kartın üst kenarına taşıyor; ona yer.
    const badgeRoom = 10.0;

    if (plans.length > 3) {
      return Padding(
        padding: const EdgeInsets.only(top: badgeRoom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < plans.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              card(plans[i], wide: true),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: badgeRoom),
      // Kartlar aynı boyda: biri tasarruf satırı taşıyınca diğeri kısa
      // kalmasın.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < plans.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: card(plans[i], wide: false)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final List<SubscriptionPlan> all;
  final bool wide;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.all,
    required this.wide,
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
    final radius = BorderRadius.circular(AppRadius.lg - 4);

    final period = Text(
      context.tr(plan.period.labelKey),
      textAlign: wide ? TextAlign.start : TextAlign.center,
      style: theme.textTheme.titleSmall?.copyWith(
        fontSize: 14,
        color: selected ? t.text : t.textMuted,
      ),
    );
    final price = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        plan.priceString,
        maxLines: 1,
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: selected ? primary : t.text,
        ),
      ),
    );
    final notes = [
      if (plan.introOffer != null)
        context.tr('premium_intro_offer', params: {'price': plan.introOffer!}),
      // Ekrandaki en ikna edici sayı en soluk renkteydi.
      if (saving != null)
        context.tr('premium_saving', params: {'percent': '$saving'}),
    ];
    final noteStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11.5,
      height: 1.25,
      color: t.secondary,
      fontWeight: FontWeight.w600,
    );

    final Widget body;
    if (wide) {
      body = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                period,
                for (final note in notes) Text(note, style: noteStyle),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          price,
          const SizedBox(width: AppSpacing.md),
          _Check(selected: selected),
        ],
      );
    } else {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          period,
          const SizedBox(height: 2),
          price,
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(note, textAlign: TextAlign.center, style: noteStyle),
            ),
        ],
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      // Kart, yerinin tamamını kaplıyor: işaret ve rozet onun köşelerine
      // göre konumlanıyor.
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.passthrough,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.fromLTRB(
                    wide ? 16 : 10,
                    recommended && !wide ? 16 : 12,
                    wide ? 16 : 10,
                    12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: selected ? primary : AppCard.borderColor(t),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: body,
                ),
              ),
            ),
          ),
          if (!wide)
            Positioned(
              top: 8,
              right: 8,
              child: _Check(selected: selected, size: 18),
            ),
          if (recommended)
            Positioned(
              top: -10,
              left: wide ? 16 : 0,
              right: wide ? null : 0,
              child: Center(
                widthFactor: wide ? 1 : null,
                child: _Badge(text: context.tr('premium_best_value')),
              ),
            ),
        ],
      ),
    );
  }
}

/// Seçili planın fiyatı, yenileme sıklığı, kimden çekileceği ve nasıl
/// iptal edileceği — abone ol düğmesinin hemen üstünde.
///
/// Uyum denetimi (6502, Mesafeli Sözleşmeler Yönetmeliği): bu bilgiler
/// yalnızca listenin altındaki küçük ve soluk notta duruyordu; düğme ekranın
/// altına sabit olduğu için kullanıcı notu görmeden satın alabiliyordu.
/// Başlangıç teklifi varsa ilk dönemden sonra ne çekileceği de yazıyor.
///
/// Otomatik yenileme bildirimi de bu: altındaki yasal not yalnızca burada
/// yazmayanları (dijital hizmet, cayma ve iade yolu) taşıyor.
class _RenewalSummary extends StatelessWidget {
  const _RenewalSummary({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final android = AppPlatform.isAndroid;
    final intro = plan.introOffer;
    final key = intro != null
        ? (android
              ? 'premium_renewal_summary_intro_android'
              : 'premium_renewal_summary_intro')
        : (android
              ? 'premium_renewal_summary_android'
              : 'premium_renewal_summary');
    return Text(
      context.tr(
        key,
        params: {
          'price': plan.priceString,
          'every': context.tr(plan.period.renewKey),
          'intro': ?intro,
        },
      ),
      key: const Key('premium_renewal_summary'),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 12.5,
        height: 1.35,
        color: context.tokens.text,
      ),
    );
  }
}

/// Gizlilik politikası ve kullanım şartları; ekranın dibinde, sığdırılmış.
class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final style = TextButton.styleFrom(
      // iOS'un 44 pt'lik dokunma hedefi; yazı küçük olsa da.
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
    );
    // Kelime ortasından bölünmesin: büyük yazıda ikinci bağlantı bütün
    // hâlinde alt satıra iniyor.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          style: style,
          onPressed: () => context.pushNamed(RouteNames.privacyPolicy),
          child: Text(context.tr('premium_privacy')),
        ),
        Text('·', style: TextStyle(color: t.textFaint)),
        TextButton(
          style: style,
          onPressed: () => context.pushNamed(RouteNames.termsOfService),
          child: Text(context.tr('premium_terms')),
        ),
      ],
    );
  }
}

/// Seçim işareti: seçiliyken dolu marka dairesi içinde tik.
class _Check extends StatelessWidget {
  const _Check({required this.selected, this.size = 24});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : t.surfaceAlt,
        border: selected ? null : Border.all(color: t.border),
      ),
      child: selected
          ? Icon(Icons.check, size: size * 0.66, color: scheme.onPrimary)
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: t.secondary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 13, color: scheme.onSecondary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                color: scheme.onSecondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off, size: 24, color: t.textMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.tr('premium_unavailable'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.tr('premium_retry')),
          ),
        ],
      ),
    );
  }
}
