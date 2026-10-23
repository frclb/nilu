/// Onboarding akışının ortak parçaları: ilerleme göstergesi ve geri gidiş.
///
/// Adım sayısı üç ekranda ayrı ayrı yazılıydı (`List.generate(6, ...)`).
/// Araya bir ekran eklendiğinde üçünü birden güncellemek gerekiyordu;
/// biri unutulsaydı kullanıcı adım sayısı değişen bir gösterge görürdü.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';

/// Onboarding adımlarının geri düğmesi.
///
/// Adımlar arası geçiş `context.goNamed` ile yapılıyordu; `go` yığına
/// eklemek yerine konumu **değiştiriyor**, dolayısıyla geri alınacak bir şey
/// kalmıyor ve `context.pop()` hiçbir şey yapmıyordu. Üç ekranın geri
/// düğmesi de sessizce ölüydü. Geçişler `push`'a alındı.
///
/// Yine de yığın boş olabilir: derin bağlantı doğrudan bir adıma düşürürse
/// `pop()` hata fırlatır. O durumda akışın başına dönülüyor.
void onboardingBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.goNamed(RouteNames.onboarding);
  }
}

/// Karşılama sayfalarından sonra gelen soru ekranları dahil, toplam adım.
const int onboardingStepCount = 8;

/// Her soru ekranının göstergedeki yeri (karşılama sayfaları 0–3).
///
/// İndeksler ekranlara tek tek yazılıydı; araya hedef adımı girince üçünün
/// birden kayması gerekti. Sayıyla aynı yerde durmaları bu yüzden.
///
/// Gebelik yolu hedef adımından sonra tek bir ekran (gebelik kurulumu);
/// o ekran göstergeyi göstermiyor, sekiz noktalı bir dizide yanlış yerde
/// durmasın diye.
abstract final class OnboardingStep {
  static const int goal = 4;
  static const int lastPeriod = 5;
  static const int periodLength = 6;
  static const int cycleLength = 7;
}

/// Soru ekranlarının ilerleme göstergesi.
///
/// Sekiz parçalı şerit: geçilen adımlar dolu erik, bulunulan adım parlayan
/// böğürtlen gülü, kalanlar soluk. Sağında "5 / 8. ADIM" yazıyor; ekran
/// okuyucu da aynı cümleyi duyuyor, şeridin kendisi süs.
class OnboardingStepDots extends StatelessWidget {
  const OnboardingStepDots({super.key, required this.step});

  /// Etkin parça (bkz. [OnboardingStep]).
  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final label = context.tr(
      'session_step_of',
      params: {'n': '${step + 1}', 'total': '$onboardingStepCount'},
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < onboardingStepCount; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: i == step ? 7 : 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == step
                            ? t.secondary
                            : i < step
                            ? primary
                            : primary.withAlpha(onboardingIdleDotAlpha(isDark)),
                        boxShadow: i == step
                            ? [
                                BoxShadow(
                                  color: t.secondary.withAlpha(110),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Geçilmemiş noktanın saydamlığı.
///
/// Eskiden her ekranda `(isDark ? 0.4 : 0.2 * 255).toInt()` yazıyordu.
/// Çarpma ternary'den önce bağlandığı için koyu temada değer `0.4.toInt()`
/// yani **0** oluyordu: geçilmemiş noktalar tamamen görünmezdi, kullanıcı
/// tek bir nokta görüp kaç adım kaldığını bilemiyordu. Parantez düzeltildi.
int onboardingIdleDotAlpha(bool isDark) => ((isDark ? 0.4 : 0.2) * 255).round();

/// Çarktaki seçim şeridinin saydamlığı — aynı hata oradaydı, seçili değerin
/// arkasındaki vurgu koyu temada hiç çizilmiyordu.
int onboardingHighlightAlpha(bool isDark) =>
    ((isDark ? 0.2 : 0.1) * 255).round();
