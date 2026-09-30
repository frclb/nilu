import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/domain/services/pairing_token.dart';
import 'package:period_tracker/presentation/partner_match/partner_qr_gen_screen.dart';

import 'screen_harness.dart';

/// Davet ekranı kodu gerçekten gösteriyor mu?
///
/// Ekran taramasında bu ekran yalnızca "çizildi ve hata atmadı" diye
/// sınanıyordu. Oysa buradaki tek iş kodu göstermek: kod boş kalsa ya da
/// okunamaz bir biçimde yazılsa ekran yine hatasız çizilir, eşleşme ise hiç
/// kurulamaz. `ensureMyId` Firebase yoksa yerel bir UUID döndürüyor — yani bu
/// ekranın Firebase yapılandırılmadan da çalışması gerekiyor, ki şu anki
/// durum tam olarak bu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  testWidgets('geçerli bir eşleştirme kodu gösteriliyor', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    const screen = PartnerQrGenScreen();
    await pumpScreen(tester, screen, size: const Size(390, 844));

    expect(find.byWidget(screen), findsOneWidget);

    // Ekranda kod dörtlü gruplara ayrılmış olarak duruyor
    // (`PairingToken.forDisplay`), o yüzden önce kanonikleştiriliyor.
    final metinler = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .where((s) => PairingToken.isWellFormed(PairingToken.normalize(s)))
        .toList();

    expect(
      metinler,
      isNotEmpty,
      reason:
          'Ekranda geçerli bir kod yok. Kod olmadan partner eşleşemez; ekran '
          'yine de hatasız çizildiği için tarama bunu yakalamaz.',
    );

    // QR görüntüsü de çizilmiş olmalı: elle yazmak yalnızca yedek yol.
    // `QrImageView` taşıdığı değeri dışarı vermiyor, ama ekran onu metinle
    // aynı `_token` değişkeninden kuruyor (`data: _token!`) ve token yoksa
    // widget'ı hiç çizmiyor — yani varlığı geçerli bir token demek.
    expect(
      find.byType(QrImageView),
      findsOneWidget,
      reason: 'QR görüntüsü çizilmemiş — okutarak eşleşme yolu kapanır',
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ekran yeniden çizildiğinde kod değişmiyor', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    const screen = PartnerQrGenScreen();
    await pumpScreen(tester, screen, size: const Size(390, 844));

    String? oku() => tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? '')
        .where((s) => PairingToken.isWellFormed(PairingToken.normalize(s)))
        .firstOrNull;

    final ilk = oku();
    expect(ilk, isNotNull);

    // Birkaç kare daha: `_load` yeniden koşarsa kod değişirdi.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(
      oku(),
      ilk,
      reason:
          'Kod ekranda dururken değişirse kullanıcı okuttuğu kodun artık '
          'geçersiz olduğunu göremez',
    );
  });
}
