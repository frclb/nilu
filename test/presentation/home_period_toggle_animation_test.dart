import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_ring.dart';

import 'screen_harness.dart';

/// "Reglim bitti" → "Geri al" → "Reglim bitti" sırasında çelenk her seferinde
/// yeniden kuruluyor mu?
///
/// Canlandırma yalnızca çizilen şey değiştiğinde çalışıyor (`didUpdateWidget`
/// veriyi karşılaştırıyor). Kayıtlı regl planlanandan kısayken bitirmek
/// çelengi gerçekten değiştiriyor: süren dönemde halka planlanan uzunluk
/// kadar regl günü gösteriyor, bitince kayıtlı uzunluğa iniyor.
///
/// Üçüncü adım ayrıca sınanıyor: ikinci "bitti" ilkiyle aynı veriye dönüyor
/// ve daha önce görülmüş bir değere dönerken canlandırmanın atlanması kolay
/// bir hata.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  /// Çelengin o anki canlandırma ilerlemesi. 1.0 ise duruyor.
  double progress(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byType(CycleRing),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    return (paint.painter! as dynamic).progress as double;
  }

  testWidgets('bitir → geri al → bitir: üçünde de çelenk yenileniyor', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    // Döngü ayarları **şifreli** depoda; `SharedPreferences`'a yazmak
    // bu iki anahtar için hiçbir şey yapmıyor.
    await CycleSettingsRepository().saveCycleSettings(
      cycleLength: 28,
      periodLength: 6,
    );

    // Üç gündür süren dönem: kayıtlı (3) planlanandan (6) kısa.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await const PeriodRepository().savePeriodLogs([
      PeriodLog(id: 'p', startDate: today.subtract(const Duration(days: 2))),
    ]);

    const screen = HomeScreen();
    await pumpScreen(tester, screen, size: const Size(390, 844));

    final context = tester.element(find.byWidget(screen));
    final bitir = context.tr('home_period_end');
    final geriAl = context.tr('home_period_undo');

    // Açılışta veri asenkron geldiği için çelenk bir kez yenileniyor;
    // sıraya başlamadan önce onun bitmesi gerekiyor.
    await tester.pump(const Duration(milliseconds: 2000));
    expect(progress(tester), 1.0, reason: 'Başlangıçta çelenk durmuş olmalı');

    Future<void> bas(String etiket, String adim) async {
      expect(
        find.text(etiket),
        findsOneWidget,
        reason: '$adim: "$etiket" düğmesi yok — sıra buraya hiç gelmemiş',
      );
      // Bildirimi önce kaldır: düğmeyi örtüyor (ayrı hata, aşağıya bak).
      ScaffoldMessenger.of(
        tester.element(find.byType(CycleRing)),
      ).removeCurrentSnackBar();
      await tester.pump();
      await tester.tap(find.text(etiket));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        progress(tester),
        lessThan(1.0),
        reason:
            '$adim: çelenk yenilenmedi. Halka içeriği değiştiği hâlde '
            'canlandırma çalışmıyorsa kullanıcı değişikliği bir sıçrama '
            'olarak görür.',
      );

      // Canlandırmanın **ve bildirimin** bitmesini bekle.
      await tester.pump(const Duration(milliseconds: 5000));
      expect(progress(tester), 1.0, reason: '$adim: canlandırma bitmedi');
    }

    await bas(bitir, '1. bitir');
    await bas(geriAl, 'geri al');
    await bas(bitir, '2. bitir');
  });

  testWidgets('eylemden hemen sonra geri alma çalışıyor', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await CycleSettingsRepository().saveCycleSettings(
      cycleLength: 28,
      periodLength: 6,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await const PeriodRepository().savePeriodLogs([
      PeriodLog(id: 'p', startDate: today.subtract(const Duration(days: 2))),
    ]);

    const screen = HomeScreen();
    await pumpScreen(tester, screen, size: const Size(390, 844));
    await tester.pump(const Duration(milliseconds: 2000));

    final context = tester.element(find.byWidget(screen));
    await tester.tap(find.text(context.tr('home_period_end')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final undo = find.text(context.tr('home_period_undo'));
    expect(undo, findsOneWidget, reason: 'Geri alma düğmesi belirmeli');

    // Hiçbir geçici katman düğmenin üstünde olmamalı. Onay bildirimi tam
    // buraya denk geliyordu: 390×844 ekranda düğme 706–726, bildirim
    // 708–772. Bildirim dört saniye durduğu için kullanıcının yanlış
    // dokunduğunu fark edip geri alacağı aralıkta dokunuş yutuluyordu.
    final undoRect = tester.getRect(undo);
    for (final katman in tester.widgetList<SnackBar>(find.byType(SnackBar))) {
      final rect = tester.getRect(find.byWidget(katman));
      expect(
        rect.overlaps(undoRect),
        isFalse,
        reason:
            'Bir bildirim ($rect) geri alma düğmesinin ($undoRect) üstünde. '
            'Dokunuş ona gider ve hiçbir şey olmaz.',
      );
    }

    // Asıl sınama: dokunuş gerçekten ulaşıyor mu? Dikdörtgen karşılaştırması
    // geometriyi, bu ise sonucu sınıyor.
    await tester.tap(undo);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(context.tr('home_period_end')),
      findsOneWidget,
      reason:
          'Geri almadan sonra düğme yeniden "reglim bitti" olmalı. Dokunuş '
          'ulaşmadıysa ekran "bugün bitti" durumunda kalır ve kullanıcı '
          'bastığı düğmenin neden çalışmadığını anlayamaz.',
    );
  });
}
