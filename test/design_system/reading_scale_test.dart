import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';

/// Uzun metin ekranlarının ölçüsü.
///
/// Gizlilik politikası, kullanım şartları ve sağlık kütüphanesi makaleleri
/// aynı okuma ölçeğini paylaşıyor. Üçü de ayrı ayrı yazdığı sürece
/// ayrışmaya açıktı: hukuki ekranlar başlıkları `TextStyle` ile sıfırdan
/// yazdığı için serif yerine gövde yazı tipinde kalıyordu.
///
/// Satır aralığı da ölçülerek seçildi: 1.7'de 15 pt harfe 25 pt satır
/// kutusu düşüyordu. iOS'un kendi gövde metni 17 pt harfe ~22 pt kutu
/// veriyor — bizimki, harfleri daha küçük olmasına rağmen daha seyrekti.
void main() {
  testWidgets('okuma ölçüsü tek kaynaktan geliyor', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppFlavor.plum),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );

    final body = AppTheme.readingBody(ctx)!;
    final heading = AppTheme.readingHeading(ctx)!;

    expect(body.fontSize, 15);
    expect(body.height, 1.5, reason: 'satır kutusu 23 pt olmalı');
    expect(heading.fontSize, 18);

    // Başlık serif, gövde değil: makale başlıklarıyla aynı aile.
    expect(
      heading.fontFamily,
      isNot(body.fontFamily),
      reason: 'başlık ile gövde aynı yazı ailesinde',
    );
  });

  test('ekranlar kendi ölçüsünü yazmıyor', () {
    // Bu üç ekran uzun metin gösteriyor; ölçüyü elle yazan bir dördüncüsü
    // eklenirse yine iki ayrı ölçek olur.
    const screens = [
      'lib/presentation/legal/privacy_policy_screen.dart',
      'lib/presentation/legal/terms_of_service_screen.dart',
      'lib/presentation/health_library/article_screen.dart',
    ];

    for (final path in screens) {
      final source = File(path).readAsStringSync();
      expect(
        source.contains('AppTheme.readingBody'),
        isTrue,
        reason: '$path ortak gövde stilini kullanmıyor',
      );
      expect(
        source.contains('height: 1.7'),
        isFalse,
        reason: '$path hâlâ kendi satır aralığını yazıyor',
      );
    }
  });
}
