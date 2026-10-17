import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:period_tracker/core/platform/app_settings_link.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/partner_match/widgets/scan_unavailable.dart';

import 'screen_harness.dart';

/// QR tarayıcı kamerayı açamadığında ne görünüyor?
///
/// Bu ekran hiçbir testte çizilmemişti: `PartnerScanScreen` taramasında
/// `MobileScanner` testte hata **üretmiyor**, bu yüzden `errorBuilder` dalına
/// hiç girilmiyordu. Oysa izin reddi gerçek ve sık bir durum — kullanıcı
/// "İzin Verme"ye bir kez bastıktan sonra gördüğü tek ekran bu.
///
/// Ayrım önemli: izin reddedildiyse kullanıcı ayarlardan düzeltebilir, o yüzden
/// düğme var. Cihazda kamera yoksa düzeltilecek bir şey yok, düğme olmamalı —
/// aksi hâlde kullanıcı ayarlarda boşuna arar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  // Testler macOS'ta koşuyor; uygulama yalnızca iOS'a çıkıyor. Platform
  // kararını sabitlemeden "düğme görünüyor" iddiası her zaman başarısız,
  // "görünmüyor" iddiası ise her zaman geçer — ikisi de bir şey sınamaz.
  setUp(() => AppSettingsLink.debugSupportedOverride = true);
  tearDown(AppSettingsLink.resetForTest);

  Future<BuildContext> pumpFor(
    WidgetTester tester,
    MobileScannerErrorCode code,
  ) async {
    final widget = ScanUnavailable(
      error: MobileScannerException(errorCode: code),
    );
    await pumpScreen(tester, widget, size: const Size(390, 844));
    expect(
      find.byWidget(widget),
      findsOneWidget,
      reason: '$code: ekran çizilmedi — iddia boşa gider',
    );
    return tester.element(find.byWidget(widget));
  }

  testWidgets('izin reddedildiğinde ayarlara götüren düğme var', (
    tester,
  ) async {
    final context = await pumpFor(
      tester,
      MobileScannerErrorCode.permissionDenied,
    );

    expect(
      find.text(context.tr('partner_scan_camera_denied')),
      findsOneWidget,
      reason: 'İzin reddi için ayrı bir metin olmalı',
    );
    expect(
      find.text(context.tr('open_settings')),
      findsOneWidget,
      reason:
          'İzin uygulamanın ayar sayfasında düzeltilebiliyor; düğme olmazsa '
          'kullanıcı tarayıcıyı bir daha hiç açamaz',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('kamera yoksa ayar düğmesi gösterilmiyor', (tester) async {
    final context = await pumpFor(tester, MobileScannerErrorCode.unsupported);

    expect(
      find.text(context.tr('partner_scan_camera_missing')),
      findsOneWidget,
      reason: 'Kamera yokluğu izin reddinden ayrı anlatılmalı',
    );
    expect(
      find.text(context.tr('open_settings')),
      findsNothing,
      reason:
          'Cihazda kamera yoksa ayarlarda düzeltilecek bir şey de yok; düğme '
          'kullanıcıyı boş bir arayışa gönderir',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ayar sayfası açılamayan platformda düğme yok', (tester) async {
    AppSettingsLink.debugSupportedOverride = false;

    final context = await pumpFor(
      tester,
      MobileScannerErrorCode.permissionDenied,
    );

    expect(
      find.text(context.tr('open_settings')),
      findsNothing,
      reason:
          'Dokunulduğunda hiçbir şey olmayan düğme kullanıcıya arıza gibi '
          'görünür',
    );
  });

  testWidgets('iki durum farklı metin gösteriyor', (tester) async {
    // Aynı metin iki dalda da kullanılsa yukarıdaki iki test yine geçerdi.
    final denied = await pumpFor(
      tester,
      MobileScannerErrorCode.permissionDenied,
    );
    expect(
      denied.tr('partner_scan_camera_denied'),
      isNot(denied.tr('partner_scan_camera_missing')),
      reason: 'İki sebep aynı cümleyle anlatılırsa ayrım kullanıcıya ulaşmaz',
    );
  });
}
