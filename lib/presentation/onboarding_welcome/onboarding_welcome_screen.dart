import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/app_layout.dart';
import 'onboarding_progress.dart';
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
  static const double _heroRatio = 0.52;
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

    final bgColor = context.tokens.background;
    final textColor = context.tokens.text;

    final pages = [
      _buildPage(
        context,
        theme,
        textColor,
        OnboardingIllustration.brand,
        context.tr('onboarding_welcome_title'),
        context.tr('onboarding_welcome_desc'),
      ),
      _buildPage(
        context,
        theme,
        textColor,
        OnboardingIllustration.calendar,
        context.tr('onboarding_page2_title'),
        context.tr('onboarding_page2_desc'),
      ),
      _buildPage(
        context,
        theme,
        textColor,
        OnboardingIllustration.log,
        context.tr('onboarding_page3_title'),
        context.tr('onboarding_page3_desc'),
      ),
      _buildPage(
        context,
        theme,
        textColor,
        OnboardingIllustration.partner,
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
                      bottom: 8,
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
                                          onboardingIdleDotAlpha(isDark),
                                        ),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 24),

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
                          const SizedBox(height: 12),
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
                          // Yeni cihaz: buluttaki kayıtları geri al. Hesap
                          // isteğe bağlı olduğu için ikincil bir bağlantı.
                          TextButton(
                            key: const Key('onboarding_restore'),
                            onPressed: () {
                              context.pushNamed(RouteNames.accountRestore);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: textColor.withAlpha(178),
                              minimumSize: const Size(double.infinity, 44),
                            ),
                            child: Text(
                              context.tr('onboarding_restore'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
    OnboardingIllustration illustration,
    String title,
    String description,
  ) {
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

        // `Flexible` sınırlı bir dikey alan istiyor; kaydırma görünümü
        // sınırsız veriyor. Sayfa alanı kadar sabit bir kutu veriliyor ve
        // taşma ihtimaline karşı dışı yine kaydırılabilir kalıyor.
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero illustration area
                    //
                    // Yükseklik sınırlı, içerik `FittedBox` ile küçülüyor: yazı
                    // büyüdüğünde çizim ezilmek yerine orantılı olarak küçülüyor.
                    // `Flexible`: çizim metinden **artan** yeri alıyor.
                    //
                    // Sabit bir yükseklik dile göre çöküyordu. Almanca 4.
                    // slaytın başlığı ("Lade deine Partnerin oder deinen
                    // Partner ein") 32 puntoda üç satıra, 144 pt'ye çıkıyor;
                    // sabit bir çizim ona yer bırakmayıp açıklamayı sayfanın
                    // dışına itiyordu. Fransızca 4. ve Portekizce 3. slaytta
                    // da aynısı oluyordu.
                    //
                    // `Flexible` + `FittedBox` birlikte: yer daralınca önce
                    // kutu küçülüyor, sonra içindeki çizim orantılı olarak.
                    // Metin hiçbir zaman sıkıştırılmıyor.
                    Flexible(
                      child: ConstrainedBox(
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
                            // `contain`: çizim kutuyu dolduruyor. Dar ekranda
                            // eskiden `scaleDown` kullanılıyordu çünkü rozetle
                            // birlikte kahraman alanı 300 pt'ye çıkıp açıklamayı
                            // ekran dışına itiyordu. Rozet kalktı, o yer boşaldı;
                            // `scaleDown` ise çizimi doğal boyutundan büyütmediği
                            // için kart yarı boş kalıyordu.
                            fit: BoxFit.contain,
                            child: illustration.build(context),
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
                              fontSize: short ? _titleSizeShort : _titleSize,
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
          ),
        );
      },
    );
  }
}
