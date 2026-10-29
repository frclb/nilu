import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/route_names.dart';
import '../../core/platform/app_icon.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_flavor.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/view_models/theme_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';
import '../profile/widgets/settings_surface.dart';

/// Tema çeşidi seçimi.
///
/// Paywall "Özel Temalar" vaat ediyordu ama böyle bir ekran hiç yoktu.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({
    super.key,
    this.iconService = const AppIconService(),
  });

  /// Testte kanal taklidi için.
  final AppIconService iconService;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ThemeViewModel>();

    Widget tile(AppFlavor flavor) => _FlavorTile(
      flavor: flavor,
      selected: viewModel.flavor == flavor,
      locked: !viewModel.canUse(flavor),
      onTap: () async {
        final ok = await viewModel.select(flavor);
        if (!ok && context.mounted) {
          // Kilitli temaya dokunmak paywall'a götürür; sessizce
          // hiçbir şey yapmamak kullanıcıyı şaşırtırdı.
          context.pushNamed(RouteNames.premium);
        }
      },
    );

    const flavors = AppFlavor.values;

    return Scaffold(
      appBar: SettingsAppBar(title: context.tr('appearance_title')),
      body: AmbientBackground(
        child: AppContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              SettingsNote(
                text: context.tr('appearance_desc'),
                icon: Icons.auto_awesome_outlined,
              ),
              const SizedBox(height: AppSpacing.xl),
              // İki sütunlu ızgara. `GridView` değil: kartların yüksekliği
              // büyük yazıda metne göre uzayabilmeli, sabit en-boy oranı
              // adı kesiyordu.
              for (var i = 0; i < flavors.length; i += 2) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tile(flavors[i])),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: i + 1 < flavors.length
                            ? tile(flavors[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              // Sade simge bir gizlilik özelliği: ücretsiz (uygulama kilidi
              // gibi), tema seçimine bağlı değil.
              _AppIconSection(service: iconService),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ana ekran simgesi seçimi. Platform desteklemiyorsa hiç çizilmiyor.
class _AppIconSection extends StatefulWidget {
  const _AppIconSection({required this.service});

  final AppIconService service;

  @override
  State<_AppIconSection> createState() => _AppIconSectionState();
}

class _AppIconSectionState extends State<_AppIconSection> {
  bool _supported = false;
  AppIconChoice _current = AppIconChoice.standard;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supported = await widget.service.isSupported();
    final current = supported
        ? await widget.service.current()
        : AppIconChoice.standard;
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _current = current;
    });
  }

  Future<void> _select(AppIconChoice choice) async {
    if (_busy || choice == _current) return;
    setState(() => _busy = true);
    final sonuc = await widget.service.set(choice);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (sonuc == AppIconResult.changed) _current = choice;
    });
    switch (sonuc) {
      case AppIconResult.changed:
        break;
      // iOS'un hız sınırı: arıza gibi kırmızı değil, nötr bir not.
      case AppIconResult.throttled:
        AppSnack.show(context, context.tr('appearance_icon_try_later'));
      case AppIconResult.failed:
        AppSnack.error(context, context.tr('appearance_icon_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) return const SizedBox.shrink();
    final t = context.tokens;
    final theme = Theme.of(context);
    return Padding(
      key: const Key('appearance_icon_section'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: SettingsCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.app_shortcut_outlined,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.tr('appearance_icon_title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('appearance_icon_desc'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: t.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final choice in AppIconChoice.values) ...[
                  Expanded(
                    child: _IconOption(
                      choice: choice,
                      selected: _current == choice,
                      onTap: () => _select(choice),
                    ),
                  ),
                  if (choice != AppIconChoice.values.last)
                    const SizedBox(width: AppSpacing.md),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final AppIconChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final label = context.tr(switch (choice) {
      AppIconChoice.standard => 'appearance_icon_standard',
      AppIconChoice.neutral => 'appearance_icon_neutral',
    });
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        key: Key('appearance_icon_${choice.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(4),
                    // Kalınlık iki durumda da aynı: seçili kutu 2 pt
                    // büyüyünce altındaki ad komşusundan aşağıda kalıyordu.
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected ? primary : AppCard.borderColor(t),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.asset(
                        'assets/icon/previews/${choice.name}.png',
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: _CheckBadge(color: primary),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: t.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seçili öğenin köşesindeki onay rozeti.
class _CheckBadge extends StatelessWidget {
  const _CheckBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: context.tokens.surface, width: 2),
      ),
      child: Icon(
        Icons.check_rounded,
        size: 15,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _FlavorTile extends StatelessWidget {
  final AppFlavor flavor;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _FlavorTile({
    required this.flavor,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = isDark ? flavor.brandDark : flavor.brand;
    final radius = BorderRadius.circular(AppCard.radius);

    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? brand : AppCard.borderColor(t),
            width: selected ? 2 : 1,
          ),
          boxShadow: AppCard.shadow(t),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(flavor.labelKey),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: t.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (locked)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: t.accentTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: t.accent,
                          ),
                        )
                      else if (selected)
                        _CheckBadge(color: brand),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Önizleme: marka rengi, açık tonu ve sabit kalan akış
                  // rengi. Kullanıcı temanın takvimi nasıl etkilemediğini
                  // görsün.
                  _Swatch(colors: [brand, flavor.tint, t.flow]),
                  const Spacer(),
                  if (locked) ...[
                    const SizedBox(height: AppSpacing.lg),
                    // Kilidin sebebi: tema Premium'la açılıyor.
                    AppTag(
                      label: context.tr('premium_title'),
                      icon: Icons.auto_awesome,
                      background: t.accentTint,
                      foreground: t.accent,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final List<Color> colors;

  const _Swatch({required this.colors});

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    const step = 22.0;
    return SizedBox(
      width: size + step * (colors.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: context.tokens.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
