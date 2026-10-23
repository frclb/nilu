import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';

/// Yerel durum (onboarding tamamlandı mı, partner modu vb.) depodan okunurken
/// gösterilen ara ekran.
///
/// Bu okuma asenkron olduğu için router başlangıçta kullanıcının gerçekten
/// nereye gitmesi gerektiğini bilemez. Splash, karar verilene kadar bekleyerek
/// dönen kullanıcının bir an onboarding görüp sonra ana ekrana sıçramasını
/// engeller.
///
/// Çoğu açılışta bir an görünüyor: dönen bir çark yerine sakin bir marka
/// anı — sistemin açılış ekranındaki lotusun devamı.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
      body: AmbientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogoMark(size: 88),
              const SizedBox(height: 20),
              Text(
                AppInfo.displayName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 34,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
