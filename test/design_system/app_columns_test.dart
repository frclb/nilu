import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_layout.dart';

/// [AppColumns] geometrisi.
///
/// "Taşma yok" testi iki sütunun kurulduğunu kanıtlamaz: tek sütunda da taşma
/// olmuyor. Burada kartların gerçekten yan yana geldiği konumlarından
/// doğrulanıyor.
void main() {
  /// [width] genişliğinde bir yerde [count] kutu çizer.
  ///
  /// Genişlik test yüzeyinden veriliyor, `SizedBox` ile değil: varsayılan
  /// yüzey 800 pt ve içine konan daha geniş bir kutu sessizce kırpılıyor —
  /// 1000 pt istenen test aslında 800 pt'de koşuyordu.
  Future<void> pumpAt(
    WidgetTester tester, {
    required double width,
    required int count,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppColumns(
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(key: ValueKey('kart$i'), height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Rect boxAt(WidgetTester tester, int index) =>
      tester.getRect(find.byKey(ValueKey('kart$index')));

  group('dar ekranda tek sütun', () {
    testWidgets('kartlar alt alta ve tam genişlikte', (tester) async {
      const width = 390.0; // iPhone 16e
      await pumpAt(tester, width: width, count: 4);

      final first = boxAt(tester, 0);
      final second = boxAt(tester, 1);

      expect(first.left, second.left, reason: 'aynı sütunda olmalı');
      expect(first.width, width, reason: 'tam genişlik kullanılmalı');
      expect(
        second.top,
        greaterThan(first.bottom),
        reason: 'ikincisi birincinin altında olmalı',
      );
    });

    testWidgets('eşiğin bir altı hâlâ tek sütun', (tester) async {
      await pumpAt(tester, width: AppLayout.twoColumnMin - 1, count: 2);

      expect(boxAt(tester, 0).left, boxAt(tester, 1).left);
    });

    testWidgets('katlanabilir açıkken tek sütun kalır', (tester) async {
      // 626 pt: iki sütun kartları 280 pt'ye düşürürdü.
      await pumpAt(tester, width: 626, count: 2);

      expect(boxAt(tester, 0).left, boxAt(tester, 1).left);
    });
  });

  group('geniş ekranda iki sütun', () {
    testWidgets('ilk iki kart yan yana ve eşit genişlikte', (tester) async {
      const width = 1000.0;
      await pumpAt(tester, width: width, count: 4);

      final left = boxAt(tester, 0);
      final right = boxAt(tester, 1);

      expect(left.top, right.top, reason: 'aynı satırda olmalı');
      expect(right.left, greaterThan(left.right), reason: 'yan yana olmalı');
      expect(left.width, right.width, reason: 'eşit bölünmeli');
      expect(
        left.width + right.width,
        closeTo(width - 16, 0.01),
        reason: 'aradaki boşluk dışında tüm genişlik kullanılmalı',
      );
    });

    testWidgets('üçüncü kart alt satıra geçer', (tester) async {
      await pumpAt(tester, width: 1000, count: 4);

      expect(boxAt(tester, 2).top, greaterThan(boxAt(tester, 0).bottom));
      expect(
        boxAt(tester, 2).left,
        boxAt(tester, 0).left,
        reason: 'ızgara hizası korunmalı',
      );
    });

    testWidgets('eşiğin tam üstü iki sütuna geçer', (tester) async {
      await pumpAt(tester, width: AppLayout.twoColumnMin, count: 2);

      expect(boxAt(tester, 0).top, boxAt(tester, 1).top);
    });

    testWidgets('tek sayıda kartta son kart yarım genişlikte kalır', (
      tester,
    ) async {
      const width = 1000.0;
      await pumpAt(tester, width: width, count: 3);

      final last = boxAt(tester, 2);

      expect(
        last.width,
        closeTo((width - 16) / 2, 0.01),
        reason: 'son kart satırı tek başına doldurmamalı',
      );
      expect(last.left, boxAt(tester, 0).left);
    });

    testWidgets('iPad mini iki sütuna geçer', (tester) async {
      await pumpAt(tester, width: 744, count: 2);

      expect(boxAt(tester, 0).top, boxAt(tester, 1).top);
    });
  });

  testWidgets('boş listede hiçbir şey çizilmez', (tester) async {
    await pumpAt(tester, width: 1000, count: 0);

    expect(tester.takeException(), isNull);
  });
}
