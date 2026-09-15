import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/design_system/app_layout.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/core/navigation/tab_navigation_shell.dart';
import 'package:period_tracker/main.dart';
import 'package:period_tracker/presentation/home/widgets/custom_bottom_nav.dart';
import 'package:period_tracker/presentation/home/widgets/side_nav_rail.dart';

/// Uygulamayı sattığımız her cihaz boyutunda açar.
///
/// Uygulama tek bir telefon genişliği varsayılarak yazılmıştı. Taşma
/// (`RenderFlex overflowed`) hata olarak sayılmaz — çalışırken yalnızca sarı
/// şerit çizilir, testte ise `takeException()` ile yakalanır. Bu dosya o
/// şeridin hiçbir boyutta çıkmadığını garanti eder.
///
/// Boyutlar simülatör profillerinden (`mainScreenWidth/Height/Scale`)
/// okunmuştur; iPhone Duo'nunkiler Apple'ın teknik özellik sayfasından.
class DeviceSize {
  const DeviceSize(this.name, this.pixels, this.ratio);

  final String name;
  final Size pixels;
  final double ratio;

  Size get points => pixels / ratio;

  @override
  String toString() =>
      '$name (${points.width.round()}x${points.height.round()} pt)';
}

const phones = <DeviceSize>[
  DeviceSize('iPhone 16e', Size(1170, 2532), 3), // 390x844
  DeviceSize('iPhone 17', Size(1179, 2556), 3), // 393x852
  DeviceSize('iPhone 17 Pro Max', Size(1320, 2868), 3), // 440x956
  // Katlanabilir kapalıyken: Pro Max'ten geniş ama belirgin biçimde kısa.
  // Dikey alan varsayan her düzen önce burada patlar.
  DeviceSize('iPhone Duo (kapalı)', Size(1398, 2034), 3), // 466x678
];

const tablets = <DeviceSize>[
  // Katlanabilir açıkken telefonla tablet arasında bir yerde.
  DeviceSize('iPhone Duo (açık)', Size(1878, 2670), 3), // 626x890
  DeviceSize('iPad mini', Size(1488, 2266), 2), // 744x1133
  DeviceSize('iPad (A16)', Size(1640, 2360), 2), // 820x1180
  DeviceSize('iPad Pro 11"', Size(1668, 2420), 2), // 834x1210
  DeviceSize('iPad Pro 13"', Size(2064, 2752), 2), // 1032x1376
  DeviceSize('iPad Pro 13" yatay', Size(2752, 2064), 2), // 1376x1032
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  });

  /// Uygulamayı açıp **gerçekten** ilk ekranı çizdirir.
  ///
  /// `pumpAndSettle` tek başına yetmiyor: `Localizations` sözlüğü varlıklardan
  /// asenkron okuyor ve o çözülene kadar altına `SizedBox` koyuyor. Yalnızca
  /// pump edilen bir testte ağaçta hiçbir ekran olmuyor — taşma iddiası da
  /// boş ağaçta sınanıp sessizce geçiyor. `runAsync` gerçek zamanlı
  /// beklemeye izin verip sözlüğün yüklenmesini sağlıyor.
  Future<void> openAt(WidgetTester tester, DeviceSize device) async {
    tester.view.physicalSize = device.pixels;
    tester.view.devicePixelRatio = device.ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await tester.pumpWidget(PeriodTrackerApp(userViewModel: UserViewModel()));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // Boş ağaçta yapılan iddia hiçbir şey kanıtlamaz.
    expect(
      find.byType(TabNavigationShell),
      findsOneWidget,
      reason: '$device: ana ekran çizilmeden iddia sınanamaz',
    );
  }

  group('her cihaz boyutunda açılır', () {
    for (final device in [...phones, ...tablets]) {
      testWidgets('$device taşmadan çizilir', (tester) async {
        await openAt(tester, device);

        expect(
          tester.takeException(),
          isNull,
          reason: '$device boyutunda düzen hatası var',
        );
      });
    }
  });

  group('gezinme menüsü genişliğe göre yer değiştirir', () {
    for (final device in phones) {
      testWidgets('$device alt menü kullanır', (tester) async {
        await openAt(tester, device);

        expect(find.byType(CustomBottomNav), findsOneWidget);
        expect(find.byType(SideNavRail), findsNothing);
      });
    }

    testWidgets('iPad Pro 13" yatayda yan menüye geçer', (tester) async {
      await openAt(tester, tablets.last);

      expect(find.byType(SideNavRail), findsOneWidget);
      expect(find.byType(CustomBottomNav), findsNothing);
    });

    testWidgets('iPad mini alt menüde kalır', (tester) async {
      // 744 pt: yan menü + okunur içerik sütunu ikisi birden sığmıyor.
      await openAt(tester, tablets[1]);

      expect(find.byType(CustomBottomNav), findsOneWidget);
      expect(find.byType(SideNavRail), findsNothing);
    });
  });

  group('içerik okunur genişlikte kalır', () {
    testWidgets('telefonda tam genişlik kullanılır', (tester) async {
      final phone = phones[1];
      await openAt(tester, phone);

      final inset = AppLayout.centeringInsets(phone.points.width);

      expect(
        inset,
        EdgeInsets.zero,
        reason: 'telefon görünümü birebir korunmalı',
      );
    });

    testWidgets('iPad 13" portrede içerik ortalanır', (tester) async {
      final tablet = tablets[4];
      await openAt(tester, tablet);

      final inset = AppLayout.centeringInsets(tablet.points.width);

      expect(inset.left, inset.right, reason: 'ortalanmalı');
      expect(
        tablet.points.width - inset.horizontal,
        AppLayout.contentMaxWidth,
        reason: 'sütun okunur genişlikte kalmalı',
      );
    });
  });

  group('düzen sınıfı eşikleri', () {
    test('bütün telefonlar compact', () {
      for (final device in phones) {
        expect(
          AppLayout.classOf(device.points.width),
          LayoutClass.compact,
          reason: '$device telefon gibi davranmalı',
        );
      }
    });

    test('katlanabilir açılınca sınıf değişir', () {
      // Aynı cihaz, çalışma anında iki farklı genişlik. Karar cihaz adına
      // göre verilseydi bu geçiş yakalanamazdı.
      expect(AppLayout.classOf(466), LayoutClass.compact);
      expect(AppLayout.classOf(626), LayoutClass.medium);
    });

    test('yan menü yalnızca geniş ekranda açılır', () {
      expect(AppLayout.classOf(744), LayoutClass.medium); // iPad mini
      expect(AppLayout.classOf(1032), LayoutClass.expanded); // iPad 13" portre
      expect(AppLayout.classOf(1376), LayoutClass.expanded); // iPad 13" yatay
    });

    test('eşikte sıçrama yok', () {
      // 600 pt'de içerik tam genişlikte, 601 pt'de hâlâ 600 pt.
      expect(AppLayout.centeringInsets(600).horizontal, 0);
      expect(600 - AppLayout.centeringInsets(601).horizontal, 599);
    });
  });
}
