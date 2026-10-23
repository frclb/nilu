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
          const SizedBox(height: AppSpacing.md),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 30,
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
              fontSize: 15,
              height: 1.5,
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
