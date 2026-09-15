import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/design_system/app_card.dart';
import 'package:period_tracker/design_system/app_layout.dart';
import 'package:period_tracker/presentation/health_library/widgets/health_library_article_list.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/core/navigation/tab_navigation_shell.dart';
import 'package:period_tracker/main.dart';
import 'package:period_tracker/presentation/home/widgets/custom_bottom_nav.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_masthead.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
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
    // Şifreli depo da sahteleniyor: gerçek kanal testte yanıt vermiyor,
    // takvim sonsuza kadar "yükleniyor" kalıyor ve ızgarası hiç ölçülmüyordu.
    // Takvim hücrelerinin dar telefonlarda taştığı bu yüzden görülmemişti.
    FlutterSecureStorage.setMockInitialValues({});
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

  group('her sekme her boyutta taşmadan çizilir', () {
    // Ana ekranı açmak yetmiyor: kütüphane ve analiz geniş ekranda iki sütuna
    // açılıyor ve o düzen yalnızca o sekmelere girilince kuruluyor.
    for (final device in [
      phones.first, // en dar telefon
      phones[3], // katlanabilir kapalı — geniş ama kısa
      tablets.first, // katlanabilir açık — iki sütun eşiğinin hemen altı
      tablets[1], // iPad mini — iki sütun eşiğinin hemen üstü
      tablets[4], // iPad 13" portre
      tablets.last, // iPad 13" yatay — yan menülü
    ]) {
      testWidgets('$device bütün sekmeler', (tester) async {
        await openAt(tester, device);

        final destinations = navDestinations(isPartner: false);
        for (final destination in destinations.skip(1)) {
          // Seçili hedef dolu simgeyi gösterir; henüz girmediklerimiz boş
          // varyantla duruyor.
          final tab = find.byIcon(destination.icon);
          expect(
            tab,
            findsWidgets,
            reason: '$device: ${destination.labelKey} sekmesi bulunamadı',
          );

          await tester.tap(tab.first);
          // `pumpAndSettle` değil: takvim verisi yüklenirken dönen
          // `CircularProgressIndicator` hiç durmuyor ve settle sonsuza
          // kadar bekliyor. Taşma yerleşim sırasında bildiriliyor, iki kare
          // yetiyor.
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            tester.takeException(),
            isNull,
            reason:
                '$device: ${destination.labelKey} sekmesinde düzen hatası var',
          );
        }
      });
    }
  });

  group('profil alt ekranları taşmadan açılır', () {
    // Bunlar ayrı rotalar ve sekme taramasına girmiyorlar; hiçbiri otomatik
    // olarak çizilmiyordu. Takvimdeki gibi cihaza göre değişen bir düzen
    // hatası buralarda da fark edilmeden kalabilir.
    //
    // Her ekran kendi testinde ve uygulama baştan açılıyor: geri gitmek
    // güvenilir değil. Uygulamanın geri oku özel bir `IconButton`, yani
    // `pageBack()` bulamıyor; `Navigator.pop` ise bazı ekranlar sekmenin
    // içinde açıldığı için yanlış yığından çıkarıp kabuğu kaldırıyor.
    //
    // Cihaz en dar telefon: sığmama sorunu önce orada çıkar.
    const settingsKeys = [
      'profile_personal_info',
      'profile_cycle_settings',
      'profile_bleeding_check',
      'profile_notifications',
      'health_sync_title',
      'appearance_title',
      'profile_privacy_security',
      'privacy_policy_title',
      'terms_of_service_title',
    ];

    for (final key in settingsKeys) {
      testWidgets('iPhone 16e — $key', (tester) async {
        await openAt(tester, phones.first);

        final profile = navDestinations(
          isPartner: false,
        ).firstWhere((d) => d.labelKey == 'nav_profile');
        await tester.tap(find.byIcon(profile.icon).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Profil listesi tek bir `Column`: bütün maddeler çiziliyor, yani
        // `find.text` ekran dışındakileri de buluyor ama dokunma başarısız
        // oluyor. `scrollUntilVisible` burada kaydırmıyor bile — aradığı
        // widget zaten bulunmuş durumda.
        final item = find.text(_dictionary[key] as String);
        await tester.ensureVisible(item);
        await tester.pump();
        await tester.tap(item);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          tester.takeException(),
          isNull,
          reason: '$key ekranında düzen hatası var',
        );
      });
    }
  });

  group('kütüphane geniş ekranda iki sütuna açılır', () {
    /// Kütüphane sekmesine geçip makale kartlarının konumlarını döndürür.
    ///
    /// `AppColumns`'un kendi geometrisi ayrı sınanıyor
    /// (`test/design_system/app_columns_test.dart`); burada **ekranın onu
    /// gerçekten kullandığı** doğrulanıyor.
    Future<List<Rect>> articleRects(
      WidgetTester tester,
      DeviceSize device,
    ) async {
      await openAt(tester, device);

      final library = navDestinations(
        isPartner: false,
      ).firstWhere((d) => d.labelKey == 'nav_library');
      await tester.tap(find.byIcon(library.icon).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final cards = find.descendant(
        of: find.byType(HealthLibraryArticleList),
        matching: find.byType(AppCard),
      );
      expect(
        cards,
        findsAtLeast(2),
        reason: '$device: karşılaştırmak için en az iki makale gerekiyor',
      );
      return [tester.getRect(cards.at(0)), tester.getRect(cards.at(1))];
    }

    testWidgets('iPad 13" portrede kartlar yan yana', (tester) async {
      final rects = await articleRects(tester, tablets[4]);

      expect(rects[0].top, rects[1].top, reason: 'aynı satırda olmalı');
      expect(rects[1].left, greaterThan(rects[0].right));
    });

    testWidgets('telefonda kartlar alt alta', (tester) async {
      final rects = await articleRects(tester, phones[1]);

      expect(rects[0].left, rects[1].left, reason: 'tek sütun korunmalı');
      expect(rects[1].top, greaterThan(rects[0].bottom));
    });
  });

  group('kayan düğme içerik sütununa hizalanır', () {
    /// Ana ekrandaki "+" düğmesinin ve içerik sütununun sağ kenarları.
    Future<(double fabRight, double contentRight)> edges(
      WidgetTester tester,
      DeviceSize device,
    ) async {
      await openAt(tester, device);

      final fab = tester.getRect(find.byType(FloatingActionButton));
      final content = tester.getRect(find.byType(CycleMasthead));
      return (fab.right, content.right);
    }

    testWidgets('iPad 13" portrede düğme sütunun yanında durur', (
      tester,
    ) async {
      final (fabRight, contentRight) = await edges(tester, tablets[4]);

      // Ekranın sağ kenarına yapışsaydı aradaki fark 200 pt'yi geçerdi.
      expect(
        (fabRight - contentRight).abs(),
        lessThan(40),
        reason: 'düğme içerik sütunundan kopmamalı',
      );
    });

    testWidgets('telefonda konum değişmez', (tester) async {
      final (fabRight, contentRight) = await edges(tester, phones[1]);

      expect((fabRight - contentRight).abs(), lessThan(40));
    });
  });

  group('alt eylem çubuğu ekranın dibinde durur', () {
    // `Scaffold` gövdeye gevşek kısıt veriyor; `Stack` içeriğine göre
    // büzülünce `Positioned(bottom: 0)` ekranın değil içeriğin dibine
    // yapışıyordu. Telefonda içerik ekranı doldurduğu için görünmüyordu,
    // iPad'de çubuk sayfanın ortasında havada kalıyordu.
    testWidgets('kayıt ekranında iPad boyutunda', (tester) async {
      final device = tablets[4];
      await openAt(tester, device);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byType(LogEntryScreen),
        findsOneWidget,
        reason: 'kayıt ekranı açılmadan iddia sınanamaz',
      );
      // `ElevatedButton.icon` alt sınıf üretiyor; `find.byType` tam tip
      // eşlediği için onu bulamıyor.
      final save = find.descendant(
        of: find.byType(LogEntryScreen),
        matching: find.byWidgetPredicate((w) => w is ElevatedButton),
      );
      expect(save, findsOneWidget, reason: 'kaydet düğmesi bulunamadı');

      final bar = tester.getRect(save);
      expect(
        bar.bottom,
        greaterThan(device.points.height - 140),
        reason: 'eylem çubuğu ekranın dibine yakın olmalı',
      );
    });
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

  group('partner modu', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        'isPartner': true,
        'hasPartner': true,
        'partnerId': 'test-partner-uid',
      });
    });

    testWidgets('partner sekmeleri gösterilir', (tester) async {
      await openAt(tester, tablets.last);

      // Partner listesi İçgörüler dalını atlar: dört sekme.
      expect(find.byType(SideNavRail), findsOneWidget);
      expect(navDestinations(isPartner: true).length, 4);
    });

    testWidgets('partner panosu çarkta asılı kalmaz', (tester) async {
      // Firebase yapılandırılmamışken akış hiç veri vermeden kapanıyor.
      // `onDone` ele alınmasaydı pano sonsuza kadar dönerdi.
      await openAt(tester, tablets[4]);

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'pano yükleme durumunda takılı kalmamalı',
      );
    });

    testWidgets('partnere kendi regl hatırlatıcısı sorulmaz', (tester) async {
      await openAt(tester, tablets[4]);

      // Sahibin metniyle izin kutusu partnere hiç açılmamalı.
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('profilde cihazın kendi verisine dayanan ayarlar yok', (
      tester,
    ) async {
      await openAt(tester, tablets[4]);

      final profile = navDestinations(
        isPartner: true,
      ).firstWhere((d) => d.labelKey == 'nav_profile');
      await tester.tap(find.byIcon(profile.icon).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Beklenen metinler sözlükten okunuyor: sabit yazılsalardı bir çeviri
      // düzeltmesi testi sessizce yalancı geçirirdi.
      String label(String key) => _dictionary[key] as String;

      // Genel bildirim anahtarları yalnızca `ReminderSync`'i besliyor ve o
      // partner modunda çalışmıyor — açıp kapattığı hâlde hiçbir şeyin
      // değişmediği anahtarlar gösterilmemeli. Sağlık içe aktarmanın da
      // partnerde aktaracağı veri yok.
      expect(find.text(label('profile_notifications')), findsNothing);
      expect(find.text(label('health_sync_title')), findsNothing);

      // Partnerin kendi bildirim ayarları duruyor.
      expect(find.text(label('profile_notification_settings')), findsOneWidget);
      // Herkese açık olanlar da duruyor.
      expect(find.text(label('appearance_title')), findsOneWidget);
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

/// Testin çizdiği yerelin sözlüğü.
///
/// `flutter test` yerel ayar vermiyor; uygulama desteklenen diller içinden
/// İngilizceye düşüyor.
final Map<String, dynamic> _dictionary =
    jsonDecode(File('lib/localization/en.json').readAsStringSync())
        as Map<String, dynamic>;
