import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/datasources/remote/firebase_auth_datasource.dart';
import 'package:period_tracker/domain/services/pairing_token.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/partner_match/partner_qr_gen_screen.dart';

import '../support/fake_partner_remote.dart';
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

    final screen = PartnerQrGenScreen(remote: FakePartnerRemote());
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

    final screen = PartnerQrGenScreen(remote: FakePartnerRemote());
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

  testWidgets('sunucu yokken QR gösterilmiyor, nedeni yazıyor', (tester) async {
    // Önceden sunucu yokken de geçerli görünen bir QR üretiliyordu;
    // okutan kişi "geçersiz kod" görüyordu.
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    final screen = PartnerQrGenScreen(
      remote: FakePartnerRemote(available: false),
    );
    await pumpScreen(tester, screen, size: const Size(390, 844));

    expect(find.byType(QrImageView), findsNothing);
    expect(find.byKey(const Key('partner_qr_failed')), findsOneWidget);
    final ctx = tester.element(find.byWidget(screen));
    expect(find.text(ctx.tr('partner_unavailable')), findsOneWidget);
  });

  testWidgets('kod yayımlanamazsa QR yok, yeniden denenebiliyor', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    final remote = FakePartnerRemote(writesSucceed: false);
    final screen = PartnerQrGenScreen(remote: remote);
    await pumpScreen(tester, screen, size: const Size(390, 844));
    final ctx = tester.element(find.byWidget(screen));

    expect(find.byType(QrImageView), findsNothing);
    expect(find.text(ctx.tr('partner_qr_gen_failed')), findsOneWidget);

    remote.writesSucceed = true;
    await tester.tap(find.text(ctx.tr('retry')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('hesap yoksa kod yerine giriş isteniyor', (tester) async {
    // Partner eşleşmesi hesap istiyor. Önceden hesap yoksa anonim bir
    // kimlik açılıyordu.
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    final remote = FakePartnerRemote();
    final screen = PartnerQrGenScreen(remote: remote);
    await pumpScreen(
      tester,
      screen,
      size: const Size(390, 844),
      userViewModel: UserViewModel(auth: _HesapYok(), firestore: remote),
    );

    expect(find.byType(QrImageView), findsNothing);
    expect(find.byKey(const Key('partner_sign_in_required')), findsOneWidget);
    expect(find.byKey(const Key('partner_sign_in_apple')), findsOneWidget);
    expect(find.byKey(const Key('partner_sign_in_google')), findsOneWidget);
    expect(remote.tokens, isEmpty, reason: 'girişsiz kod yayımlanmamalı');
  });
}

class _HesapYok extends FirebaseAuthDataSource {
  @override
  String? get accountUid => null;
}
