import 'package:flutter/material.dart';
import '../../core/app_info.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/app_layout.dart';
import 'onboarding_progress.dart';
import 'widgets/onboarding_chrome.dart';
import 'widgets/onboarding_illustration.dart';

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
  // Rozet kaldırıldıktan sonra sayfada ~90 pt boşaldı; çizim o yeri
  // kullanıyor. Üst sınır: metin yine de `Flexible` sayesinde önceliği
  // koruyor, uzun başlıklarda (Almanca 4. slayt üç satır) kutu küçülüyor.
  static const double _heroRatio = 0.58;
  static const double _heroRatioWide = 0.60;
  static const double _heroRatioShort = 0.42;
  static const double _heroMin = 100;
  static const double _heroMax = 620;

  /// Bu yüksekliğin altındaki sayfa "kısa" sayılır.
  ///
  /// Katlanabilir telefon kapalıyken sayfa alanı ~311 pt kalıyor; normal bir
  /// telefonda ~477. Kısa sayfada üç şey birden değişiyor: süs rozet
  /// gizleniyor (kahraman çizimdeki simgenin aynısını gösteriyordu), çizim
  /// daha az yer kaplıyor ve başlık küçülüyor.
  ///
  /// Üçü birden gerekti: Almanca 4. slaytın başlığı ("Lade deine Partnerin
  /// oder deinen Partner ein") 32 punto ile üç satıra çıkıp 96 pt yiyor ve
  /// açıklamayı sayfanın dışına itiyordu.
  static const double _shortPageHeight = 420;

  /// Başlık punto (normal / kısa sayfa).
  static const double _titleSize = 32;
  static const double _titleSizeShort = 26;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // `go` değil `push`: `go` yığını değiştiriyor ve sonraki adımların
    // geri düğmesi boşa düşüyordu.
    //
    // "Atla" da buraya geliyor: tanıtımı atlamak yol seçimini atlamak değil.
    context.pushNamed(RouteNames.onboardingGoal);
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
    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    final pages = [
      (
        OnboardingIllustration.brand,
        'onboarding_welcome_title',
        'onboarding_welcome_desc',
      ),
      (
        OnboardingIllustration.calendar,
        'onboarding_page2_title',
        'onboarding_page2_desc',
      ),
      (
        OnboardingIllustration.log,
        'onboarding_page3_title',
        'onboarding_page3_desc',
      ),
      (
        OnboardingIllustration.partner,
        'onboarding_page4_title',
        'onboarding_page4_desc',
      ),
    ];

    return Scaffold(
      backgroundColor: t.background,
      // Işıma `AppContentWidth`'in **dışında**: dekoratif katman tam
      // genişlikte kalmalı. İçeride olduğunda 600 pt'de kesiliyor ve zeminle
      // arasında görünür bir dikey dikiş bırakıyordu.
      body: AmbientBackground(
        child: AppContentWidth(
          // Onboarding tam ekran bir tanıtım: 600 pt'lik okuma sütunu
          // 1032 pt'lik bir ekranda içeriği ortada küçük bir ada
          // bırakıyordu. Gövde geniş, **metin** kendi içinde dar.
          maxWidth: _pageMaxWidth,
          child: SafeArea(
            child: Column(
              children: [
                // Üst çubuk: ortada yazı markası, sağda "Atla".
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        AppInfo.displayName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        child: TextButton(
                          onPressed: _completeOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: t.textMuted,
                            minimumSize: const Size(48, 44),
                          ),
                          child: Text(context.tr('onboarding_skip')),
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
                    itemCount: pages.length,
                    itemBuilder: (context, index) {
                      final (illustration, title, description) = pages[index];
                      return _buildPage(
                        context,
                        illustration,
                        context.tr(title),
                        context.tr(description),
                      );
                    },
                  ),
                ),

                // Alt alan: nokta göstergesi ve düğmeler metinle aynı
                // genişlikte. Sayfa 760 pt'ye açılınca tam genişlikte bir
                // "Devam Et" düğmesi hem çirkin hem de dokunma hedefi olarak
                // abartılı oluyordu.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: AppContentWidth(
                    maxWidth: _textMaxWidth,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(pages.length, (index) {
                            final isActive = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isActive
                                    ? primary
                                    : primary.withAlpha(
                                        onboardingIdleDotAlpha(isDark),
                                      ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 18),
                        AppGradientButton(
                          label: context.tr('onboarding_continue'),
                          onPressed: _nextPage,
                          radius: AppRadius.pill,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () {
                            context.pushNamed(RouteNames.partnerScan);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide.none,
                            backgroundColor: t.brandTint,
                          ),
                          child: Text(context.tr('onboarding_partner_login')),
                        ),
                        // Yeni cihaz: buluttaki kayıtları geri al. Hesap
                        // isteğe bağlı olduğu için ikincil bir bağlantı.
                        TextButton(
                          key: const Key('onboarding_restore'),
                          onPressed: () {
                            context.pushNamed(RouteNames.accountRestore);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: t.textMuted,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: Text(context.tr('onboarding_restore')),
                        ),
                        const OnboardingPrivacyNote(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    OnboardingIllustration illustration,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);
    final t = context.tokens;

    // Sayfa kaydırılabilir: sığdığında ortalanıyor, sığmadığında kayıyor.
    // Önceden sabit bir sütundu ve çizim `Expanded` içindeydi — yazı boyutu
    // büyüdüğünde çizime kalan yer içeriğinden küçülüyor, ekran taşıyordu.
    // En büyük **normal** boyutta (erişilebilirlik bile değil) 49 piksel
    // taşıyordu; kullanıcının ilk gördüğü ekran bu.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppLayout.compactMax;

        final short = constraints.maxHeight < _shortPageHeight;
        final ratio = wide
            ? _heroRatioWide
            : (short ? _heroRatioShort : _heroRatio);
        final heroMaxHeight = (constraints.maxHeight * ratio).clamp(
          _heroMin,
          _heroMax,
        );
        // Kısa sayfada kartın iç payı da daralıyor: metin önce.
        final inset = short ? 14.0 : 24.0;

        // `Flexible` sınırlı bir dikey alan istiyor; kaydırma görünümü
        // sınırsız veriyor. Sayfa alanı kadar sabit bir kutu veriliyor ve
        // taşma ihtimaline karşı dışı yine kaydırılabilir kalıyor.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                // Alt pay kartın gölgesine yer: sayfa görünümü kenarda
                // kırpıyor, gölge sert bir çizgiyle kesiliyordu.
                padding: EdgeInsets.fromLTRB(20, 4, 20, short ? 10 : 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Kahraman kart: çizim, başlık ve açıklama aynı tül
                    // zeminde. İçeriği kadar uzuyor, sayfadan büyükse
                    // çizim küçülüyor.
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [t.brandTint, t.surface],
                          ),
                          border: Border.all(color: AppCard.borderColor(t)),
                          boxShadow: AppCard.shadow(t),
                        ),
                        padding: EdgeInsets.all(inset),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Kahraman çizim
                            //
                            // Yükseklik sınırlı, içerik `FittedBox` ile
                            // küçülüyor: yazı büyüdüğünde çizim ezilmek yerine
                            // orantılı olarak küçülüyor. `Flexible`: çizim
                            // metinden **artan** yeri alıyor.
                            //
                            // Sabit bir yükseklik dile göre çöküyordu. Almanca
                            // 4. slaytın başlığı ("Lade deine Partnerin oder
                            // deinen Partner ein") üç satıra çıkıyor; sabit
                            // bir çizim ona yer bırakmayıp açıklamayı sayfanın
                            // dışına itiyordu. Fransızca 4. ve Portekizce 3.
                            // slaytta da aynısı oluyordu.
                            //
                            // `Flexible` + `FittedBox` birlikte: yer daralınca
                            // önce kutu küçülüyor, sonra içindeki çizim
                            // orantılı olarak. Metin hiçbir zaman
                            // sıkıştırılmıyor.
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: heroMaxHeight,
                                  minHeight: _heroMin,
                                ),
                                // Tam genişlik şart: gevşek kısıtta
                                // `FittedBox` çizimi doğal boyutunda
                                // bırakıyor ve geniş ekranda kart boş
                                // kalıyor.
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: illustration.build(context),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: short ? 12 : 20),

                            // Kahraman çizim sayfa kadar geniş olabiliyor ama
                            // metin okunur kalmalı: 760 pt'lik bir açıklama
                            // satırı gözün satır başını bulmasını
                            // zorlaştırıyor.
                            AppContentWidth(
                              maxWidth: _textMaxWidth,
                              child: Column(
                                children: [
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontSize: short
                                              ? _titleSizeShort
                                              : _titleSize,
                                          height: 1.12,
                                          color: theme.colorScheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    description,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: t.textMuted,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }
}
