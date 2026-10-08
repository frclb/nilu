import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/partner_match/partner_qr_gen_screen.dart';

import '../support/fake_partner_remote.dart';
import 'screen_harness.dart';

/// Bir eylemin ardından çıkan bildirim, sıradaki eylemi engelliyor mu?
///
/// Bildirim ekranın altında duruyor ve dört saniye kalıyor. O aralıkta altına
/// denk gelen her düğme dokunuşu yutuyor — hata vermeden, hiçbir iz
/// bırakmadan. Kullanıcı açısından düğme bozuk görünüyor.
///
/// Ölçtüğüm çakışmalar (bildirim / düğme, genel koordinat):
///   ana ekran 390×844 — "Geri al" 706–726, bildirim 708–772
///   takvim    466×678 — gün eylemleri 645, bildirim 614–678
///   QR        390×844 — "Kodu Kopyala" 789, bildirim 780–844
///
/// Bu testler geometriyi değil **sonucu** sınıyor: eylemden hemen sonra
/// sıradaki düğmeye basılıyor ve gerçekten çalıştığı doğrulanıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  });

  testWidgets('takvim: işaretledikten hemen sonra geri alınabiliyor', (
    tester,
  ) async {
    const screen = CalendarScreen();
    // Katlanabilir kapalıyken en kısa ekran: gün eylemleri bildirim
    // bölgesine tam burada giriyor.
    await pumpScreen(tester, screen, size: const Size(466, 678));

    final context = tester.element(find.byWidget(screen));
    final isaretle = context.tr('calendar_mark_period');
    final kaldir = context.tr('calendar_unmark_period');

    expect(
      find.text(isaretle),
      findsOneWidget,
      reason: 'Bugün regl değilken "işaretle" düğmesi olmalı',
    );
    await tester.tap(find.text(isaretle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(kaldir),
      findsOneWidget,
      reason: 'İşaretleme sonrası düğme "kaldır"a dönmeli',
    );

    // Yanlış güne dokunduğunu fark eden kullanıcı tam burada düzeltmek
    // istiyor. Bildirim düğmenin üstündeyse bu dokunuş hiçbir şey yapmaz.
    await tester.tap(find.text(kaldir));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(isaretle),
      findsOneWidget,
      reason:
          'Geri alma dokunuşu ulaşmadı: ekran hâlâ "regl günü" durumunda. '
          'Eylemin ardından çıkan bildirim düğmeyi örtüyor olabilir.',
    );
  });

  testWidgets('QR: kodu yeniledikten hemen sonra kopyalanabiliyor', (
    tester,
  ) async {
    final screen = PartnerQrGenScreen(remote: FakePartnerRemote());
    await pumpScreen(tester, screen, size: const Size(390, 844));

    final context = tester.element(find.byWidget(screen));
    final yenile = context.tr('partner_qr_gen_rotate');
    final kopyala = context.tr('partner_qr_gen_copy_code');

    await tester.tap(find.text(yenile));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Yeni kod üretildi; kullanıcının sıradaki işi onu kopyalamak.
    final kopyalaDugmesi = find.text(kopyala);
    expect(kopyalaDugmesi, findsOneWidget);

    for (final snack in tester.widgetList<SnackBar>(find.byType(SnackBar))) {
      final rect = tester.getRect(find.byWidget(snack));
      expect(
        rect.overlaps(tester.getRect(kopyalaDugmesi)),
        isFalse,
        reason:
            'Yenileme bildirimi ($rect) kopyalama düğmesinin '
            '(${tester.getRect(kopyalaDugmesi)}) üstünde — yeni kodu '
            'kopyalamak dört saniye engelleniyor.',
      );
    }

    expect(tester.takeException(), isNull);
  });
}
