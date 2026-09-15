import 'package:flutter/material.dart';
import '../../design_system/app_scrim.dart';
import '../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/app_layout.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  /// Tanıtım sayfasının azami genişliği.
  ///
  /// Okuma sütunundan geniş: kahraman çizimin ekranı doldurması için yer
  /// gerekiyor. Metin ve düğmeler kendi içlerinde [_textMaxWidth] ile
  /// daraltılıyor, yoksa 760 pt'lik bir satır okunmuyor.
  static const double _pageMaxWidth = 760;

  /// Başlık, açıklama ve düğmelerin azami genişliği.
  static const double _textMaxWidth = 520;

  /// Kahraman çizimin kaplayacağı dikey oran (dar / geniş ekran).
  ///
  /// Sabit 300 pt'ydi. Sayfa alanı iPhone 16e'de ~477, iPad portrede ~1085,
  /// katlanabilir kapalıyken ~320 pt: tek bir sayı üçünde birden doğru
  /// durmuyor. Kısa ekranda çizim metnin yerini yiyip **açıklamayı
  /// kırpıyordu** (iPhone 16e'de ikinci satır yarısından kesiliyordu),
  /// geniş ekranda ise doğal boyutunda kalıp sayfayı boş bırakıyordu.
  static const double _heroRatio = 0.45;
  static const double _heroRatioWide = 0.55;
  static const double _heroMin = 120;
  static const double _heroMax = 620;

  /// Üstteki simge rozetinin görünmesi için gereken en az sayfa yüksekliği.
  ///
  /// Rozet kahraman çizimdeki simgenin aynısını gösteriyor — süs. Kısa
  /// ekranda 104 pt (rozet + boşluk) metne yer açmaktan daha değerli değil.
  static const double _badgeMinPageHeight = 420;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    context.goNamed(RouteNames.onboardingLastPeriod);
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = context.tokens.background;
    final textColor = context.tokens.text;

    final pages = [
      _buildPage(
        context,
        theme,
        textColor,
        Icons.spa,
        context.tr('onboarding_welcome_title'),
        context.tr('onboarding_welcome_desc'),
      ),
      _buildPage(
        context,
        theme,
        textColor,
        Icons.calendar_month,
        context.tr('onboarding_page2_title'),
        context.tr('onboarding_page2_desc'),
      ),
      _buildPage(
        context,
        theme,
        textColor,
        Icons.edit_note,
        context.tr('onboarding_page3_title'),
        context.tr('onboarding_page3_desc'),
      ),
      _buildPage(
        context,
        theme,
        textColor,
        Icons.favorite,
        context.tr('onboarding_page4_title'),
        context.tr('onboarding_page4_desc'),
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      // Sarmalayıcı `Stack`'in **içinde**: dekoratif degrade tam genişlikte
      // kalmalı. Dışarıda olduğunda 600 pt'de kesiliyor ve zeminle arasında
      // görünür bir dikey dikiş bırakıyordu.
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withAlpha(12),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),

          AppContentWidth(
            // Onboarding tam ekran bir tanıtım: 600 pt'lik okuma sütunu
            // 1032 pt'lik bir ekranda içeriği ortada küçük bir ada
            // bırakıyordu. Gövde geniş, **metin** kendi içinde dar.
            maxWidth: _pageMaxWidth,
            child: SafeArea(
              child: Column(
                children: [
                  // Top Action Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: textColor.withAlpha(153),
                          ),
                          child: Text(
                            context.tr('onboarding_skip'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: 4,
                      itemBuilder: (context, index) => pages[index],
                    ),
                  ),

                  // Bottom Area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: 24,
                    ),
                    decoration: BoxDecoration(color: bgColor.withAlpha(204)),
                    // Nokta göstergesi ve düğmeler metinle aynı genişlikte:
                    // sayfa 760 pt'ye açılınca tam genişlikte bir "Devam Et"
                    // düğmesi hem çirkin hem de dokunma hedefi olarak abartılı
                    // oluyordu.
                    child: AppContentWidth(
                      maxWidth: _textMaxWidth,
                      child: Column(
                        children: [
                          // Dots Indicator (6 dots)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isActive = index == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: isActive ? 24 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.primary.withAlpha(
                                          (isDark ? 0.4 : 0.2 * 255).toInt(),
                                        ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 32),

                          // CTA Button
                          ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: theme.colorScheme.primary.withAlpha(
                                76,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr('onboarding_continue'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              context.pushNamed(RouteNames.partnerScan);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            child: Text(
                              context.tr('onboarding_partner_login'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    ThemeData theme,
    Color textColor,
    IconData topIcon,
    String title,
    String description,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    // Sayfa kaydırılabilir: sığdığında ortalanıyor, sığmadığında kayıyor.
    // Önceden sabit bir sütundu ve çizim `Expanded` içindeydi — yazı boyutu
    // büyüdüğünde çizime kalan yer içeriğinden küçülüyor, ekran taşıyordu.
    // En büyük **normal** boyutta (erişilebilirlik bile değil) 49 piksel
    // taşıyordu; kullanıcının ilk gördüğü ekran bu.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppLayout.compactMax;

        final heroMaxHeight =
            (constraints.maxHeight * (wide ? _heroRatioWide : _heroRatio))
                .clamp(_heroMin, _heroMax);
        final showBadge = constraints.maxHeight >= _badgeMinPageHeight;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Icon — kısa ekranda gizli, bkz.
                  // [_badgeMinPageHeight].
                  if (showBadge) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.tokens.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(25),
                          width: 1,
                        ),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: AppScrim.veil(26),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                        topIcon,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Hero illustration area
                  //
                  // Yükseklik sınırlı, içerik `FittedBox` ile küçülüyor: yazı
                  // büyüdüğünde çizim ezilmek yerine orantılı olarak küçülüyor.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: heroMaxHeight,
                      minHeight: _heroMin,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withAlpha(20),
                            theme.colorScheme.primary.withAlpha(5),
                          ],
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(25),
                        ),
                      ),
                      child: FittedBox(
                        // Geniş ekranda `contain`: çizim yer varken büyüyüp
                        // kutuyu dolduruyor. Dar ekranda `scaleDown` kalıyor —
                        // `contain` orada da kutuyu doldurduğu için kahraman
                        // alanı 260'tan 300 pt'ye çıkıyor ve açıklama metnini
                        // ekranın dışına itiyordu.
                        fit: wide ? BoxFit.contain : BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Decorative circles
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary.withAlpha(
                                      12,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.primary.withAlpha(
                                      20,
                                    ),
                                  ),
                                ),
                                Icon(
                                  topIcon,
                                  size: 64,
                                  color: theme.colorScheme.primary.withAlpha(
                                    153,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Icon(
                              Icons.water_drop,
                              size: 32,
                              color: theme.colorScheme.primary.withAlpha(102),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_florist,
                                  size: 24,
                                  color: theme.colorScheme.primary.withAlpha(
                                    76,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.sunny,
                                  size: 24,
                                  color: theme.colorScheme.primary.withAlpha(
                                    76,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.nights_stay,
                                  size: 24,
                                  color: theme.colorScheme.primary.withAlpha(
                                    76,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Text Content
                  //
                  // Kahraman çizim sayfa kadar geniş olabiliyor ama metin
                  // okunur kalmalı: 760 pt'lik bir açıklama satırı gözün
                  // satır başını bulmasını zorlaştırıyor.
                  AppContentWidth(
                    maxWidth: _textMaxWidth,
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withAlpha(204),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
