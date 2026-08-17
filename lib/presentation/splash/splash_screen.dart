import 'package:flutter/material.dart';

/// Yerel durum (onboarding tamamlandı mı, partner modu vb.) depodan okunurken
/// gösterilen ara ekran.
///
/// Bu okuma asenkron olduğu için router başlangıçta kullanıcının gerçekten
/// nereye gitmesi gerektiğini bilemez. Splash, karar verilene kadar bekleyerek
/// dönen kullanıcının bir an onboarding görüp sonra ana ekrana sıçramasını
/// engeller.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      ),
    );
  }
}
