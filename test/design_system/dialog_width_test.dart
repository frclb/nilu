import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_layout.dart';
import 'package:period_tracker/design_system/app_theme.dart';

/// Diyalog genişliği.
///
/// Flutter `AlertDialog`'a azami genişlik vermiyor: 40 pt kenar boşluğu
/// dışında ekranı dolduruyor. Telefonda fark edilmiyor ama iPad'de iki
/// satırlık bir soru 950 pt'ye yayılıyor, düğmeler metinden yüzlerce piksel
/// uzağa düşüyordu. Sınır temada, yani uygulamadaki bütün diyaloglarda.
void main() {
  Future<Rect> showAt(WidgetTester tester, Size pixels, double ratio) async {
    tester.view.physicalSize = pixels;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppFlavor.plum),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              // Uzun metin şart: diyalog içeriğine göre büyüyor. Kısa bir
              // cümlede Flutter'ın 280 pt asgarisi zaten dar tutuyor ve
              // eksik azami sınır hiç fark edilmiyor — gerçek hatırlatıcı
              // metni bu uzunlukta.
              builder: (_) => const AlertDialog(
                title: Text('Hatırlatıcılar'),
                content: Text(
                  'Reglinin yaklaştığını ve doğurgan dönemini zamanında '
                  'haber verebilmemiz için bildirim izni gerekiyor. '
                  'Bildirimler cihazında hazırlanır, içerikleri hiçbir yere '
                  'gönderilmez.',
                ),
              ),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    // `AlertDialog`'ın dış render kutusu ekranın tamamı (ortalayan
    // `Align`'ı da kapsıyor); görünen yüzey içindeki `Material`.
    // `AlertDialog`'ın dış render kutusu ekranın tamamı (ortalayan `Align`'ı
    // da kapsıyor); görünen yüzey içindeki `Material`.
    return tester.getRect(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  testWidgets('iPad 13" portrede sütun genişliğini aşmaz', (tester) async {
    final rect = await showAt(tester, const Size(2064, 2752), 2);

    expect(
      rect.width,
      lessThanOrEqualTo(AppLayout.contentMaxWidth),
      reason: 'sınırsız bırakılırsa 950 pt olur',
    );
    expect(
      rect.width,
      greaterThanOrEqualTo(280),
      reason: 'azami sınır koyarken asgari sınır düşmemeli',
    );
  });

  testWidgets('iPad yatayda da aşmaz', (tester) async {
    final rect = await showAt(tester, const Size(2752, 2064), 2);

    expect(rect.width, lessThanOrEqualTo(AppLayout.contentMaxWidth));
  });

  testWidgets('telefonda daralmaz', (tester) async {
    // iPhone 17: 393 pt. Diyalog 40 pt kenar boşluğuyla 313 pt olmalı.
    final rect = await showAt(tester, const Size(1179, 2556), 3);

    expect(
      rect.width,
      greaterThanOrEqualTo(280),
      reason: 'Flutter\'ın 280 pt asgarisi korunmalı',
    );
    expect(rect.width, lessThanOrEqualTo(393 - 80));
  });
}
