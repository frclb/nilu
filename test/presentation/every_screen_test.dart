import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'all_screens.dart';
import 'screen_harness.dart';

/// Her ekran çiziliyor mu?
///
/// Yayın öncesi en geniş ağ: cihaz taraması sekme gezinmesiyle ilerlediği
/// için ulaşamadığı ekranlar vardı — makale okuyucusu, premium ekranı,
/// asistan, hukuki metinler, widget önizlemesi. Bir ekranın hiç
/// çizilmemesi, oradaki bir taşmanın ya da eksik sağlayıcının yalnızca
/// kullanıcıda ortaya çıkması demek.
///
/// İddia sade: ekran çiziliyor ve hiçbir boyutta düzen hatası atmıyor.
/// Bu, içeriğin doğruluğunu sınamaz; her ekranın kendi testi ayrıca var.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  final screens = allScreens();

  for (final entry in screens.entries) {
    for (final size in screenSizes.entries) {
      testWidgets('${entry.key} — ${size.key}', (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});

        await pumpScreen(tester, entry.value, size: size.value);

        // Önce ekranın gerçekten çizildiği: `takeException` boş bir
        // ağaçta da null döner, yani bu doğrulama olmadan test hiçbir şey
        // sınamamış olurdu.
        expect(
          find.byWidget(entry.value),
          findsOneWidget,
          reason: '${entry.key}: ekran çizilmedi — iddia boşa gider',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} · ${size.key}: düzen hatası',
        );
      });
    }
  }
}
