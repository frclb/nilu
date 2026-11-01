import 'package:flutter/material.dart';

import '../../../design_system/app_decor.dart';
import '../../../design_system/app_layout.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../onboarding_progress.dart';

/// Kurulum adımlarının ortak iskelet parçaları.
///
/// Yedi soru ekranı aynı üst çubuğu, başlığı ve alt eylem şeridini ayrı
/// ayrı kuruyordu; her biri kendi puntosunu ve boşluğunu seçtiği için
/// adımlar arasında başlık zıplıyordu.

/// Ekran yüksekliğine göre kurulumun ölçüsü.
///
/// Kurulum ekranları kaydırılmıyor (`AppFitToScreen`); küçük telefonda
/// başlık, boşluk ve çark sıkılaşıyor ki içerik küçülmeden sığsın. Eşikler
/// ekranın tamamı: iPhone SE 667, mini ve 16e 812–844, iPad mini yatay 744.
FitDensity onboardingSize(BuildContext context) {
  final h = MediaQuery.sizeOf(context).height;
  if (h < 700) return FitDensity.compact;
  if (h < 860) return FitDensity.regular;
  return FitDensity.roomy;
}

/// Üst çubuk: solda geri, sağda isteğe bağlı eylem ("Atla").
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: t.text),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => onboardingBack(context),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// Sağ üstteki sessiz "Atla".
class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.tokens.textMuted,
        minimumSize: const Size(48, 44),
      ),
      child: Text(context.tr('onboarding_skip')),
    );
  }
}

/// Soru başlığı: isteğe bağlı bağlam etiketi, serif başlık, açıklama.
class OnboardingHeading extends StatelessWidget {
  const OnboardingHeading({
    super.key,
    required this.title,
    this.description,
    this.tag,
    this.tagIcon,
  });

  final String title;
  final String? description;

  /// Başlığın üstündeki küçük hap ("Döngü Ayarları", "Lohusalık").
  final String? tag;
  final IconData? tagIcon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final size = onboardingSize(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tag != null) ...[
          AppTag(
            label: context.upper(tag!),
            icon: tagIcon,
            background: t.brandTint,
            foreground: t.secondary,
          ),
          SizedBox(height: size.pick(8.0, 10.0, 12.0)),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: size.pick(25.0, 28.0, 30.0),
              height: 1.15,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            description!,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: size.pick(14.0, 15.0, 15.0),
              height: size.pick(1.4, 1.45, 1.5),
              color: t.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Alt eylem şeridi: zemin tam genişlikte, düğme okunur sütunda.
///
/// `Scaffold.bottomNavigationBar`'a konuyor: içerik sütununun içinde
/// kalınca zemini geniş ekranda 600 pt'de kesiliyordu.
class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.tokens.background,
      child: SafeArea(
        top: false,
        child: AppContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Kilitli simge ve "verilerin cihazında şifreli" notu.
///
/// Yalnızca gerçekten doğru olanı söylüyor: kayıtlar cihazda şifreli.
/// Tasarımdaki "uçtan uca şifreli" ibaresi alınmadı — bulut kopyası uçtan
/// uca şifreli değil.
class OnboardingPrivacyNote extends StatelessWidget {
  const OnboardingPrivacyNote({super.key, this.center = true});

  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 15, color: t.secondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            context.tr('onboarding_success_privacy'),
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: t.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Simgeli bilgi kutusu (ipucu, not).
/// Takvim gibi büyük bir öğenin altındaki kısa ipucu: kartsız, tek satır.
class OnboardingHint extends StatelessWidget {
  const OnboardingHint({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: t.secondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.35,
              color: t.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingNote extends StatelessWidget {
  const OnboardingNote({
    super.key,
    required this.text,
    this.icon = Icons.lightbulb_outline,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: icon,
            size: 32,
            circle: true,
            background: t.secondaryTint,
            color: t.secondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.text, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// İçeriği sırayla, yumuşakça açan sütun: başlık, açıklama, seçenekler
/// birbiri ardına hafifçe yukarı kayarak beliriyor.
///
/// Adımlar önce bir anda beliriyordu; kurulum bir form doldurma hissi
/// veriyordu. `Column` yerine konuyor, parametreleri aynı. Boşluklar
/// (`SizedBox`, `Spacer`) beklemiyor; `Expanded` gibi esnek çocukların içi
/// canlanıyor. "Hareketi azalt" açıksa hareket yok.
class OnboardingStagger extends StatefulWidget {
  const OnboardingStagger({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.padding,
  });

  final List<Widget> children;

  /// Sütunun çevresindeki boşluk (kaydırma görünümünün `padding`'i
  /// yerine: ekranlar artık kaydırılmıyor).
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;

  /// İki öğe arasındaki gecikme.
  static const Duration step = Duration(milliseconds: 70);

  /// Bir öğenin belirme süresi.
  static const Duration reveal = Duration(milliseconds: 420);

  @override
  State<OnboardingStagger> createState() => _OnboardingStaggerState();
}

class _OnboardingStaggerState extends State<OnboardingStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  /// Yalnızca ilk birkaç öğe sırayla geliyor; uzun listede sonuncular
  /// beklemesin.
  static const int _maxStaggered = 8;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          OnboardingStagger.reveal + OnboardingStagger.step * _maxStaggered,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _animationFor(int order) {
    final total = _controller.duration!.inMilliseconds;
    final start =
        (OnboardingStagger.step.inMilliseconds *
            order.clamp(0, _maxStaggered)) /
        total;
    final end = (start + OnboardingStagger.reveal.inMilliseconds / total).clamp(
      0.0,
      1.0,
    );
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _reveal(Widget child, int order) {
    final animation = _animationFor(order);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var order = 0;
    final children = <Widget>[
      for (final child in widget.children)
        if (child is SizedBox && child.child == null || child is Spacer)
          child
        else if (child is Flexible)
          Flexible(
            flex: child.flex,
            fit: child.fit,
            child: _reveal(child.child, order++),
          )
        else
          _reveal(child, order++),
    ];
    final column = Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisAlignment: widget.mainAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      children: children,
    );
    final padding = widget.padding;
    return padding == null ? column : Padding(padding: padding, child: column);
  }
}
