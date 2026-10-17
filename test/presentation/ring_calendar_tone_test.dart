import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_ring_data.dart';

import 'screen_harness.dart';

/// Halkadaki tahmin tonu ile takvimin tahmin lejantı aynı mı?
///
/// Üç yerde "tahmin" anlatılıyor: takvimin **bandı** (gün sayısının arkasına
/// serilen tül), takvimin **lejant noktası** ve halkadaki **çiçek**. Üçü aynı
/// renk olamıyor, çünkü işleri farklı:
///
///   bant    zemine serili, üstünde gün sayısı okunacak → soluk kalmak
///           zorunda (ölçülen kontrast 1.21:1 açık, 1.11:1 koyu)
///   nokta   8 puntoluk işaret → bant tonunda seçilmiyor
///   çiçek   işaretin kendisi → bant tonunda zemine gömülüyor (ölçüldü:
///           açık temada #eed1d9 beyaza, koyuda #582b3b zemine karışıyor)
///
/// Bu yüzden kural şu: **küçük işaretler ham `flowSoft`, zemin bandı onun
/// tülü.** Lejant noktası ile halkadaki çiçek aynı sınıfta, dolayısıyla aynı
/// renkte olmalı — kullanıcı iki ekranda aynı şeyi aynı tonda görsün.
///
/// Test lejantın **gerçekte boyadığı** rengi okuyor. İkisini de `t.flowSoft`
/// yazıp karşılaştırmak hiçbir şey sınamazdı: bu oturumda lejant ile hücrenin
/// ayrıştığı bir hata zaten çıkmıştı (doğurganlık noktası).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  /// Takvimdeki lejant noktasının boyandığı renk.
  Color lejantTonu(String etiket) {
    final satir = find.ancestor(
      of: find.text(etiket),
      matching: find.byType(Row),
    );
    final nokta = find.descendant(
      of: satir.first,
      matching: find.byType(Container),
    );
    final box = nokta.first.evaluate().first.widget as Container;
    final dec = box.decoration! as BoxDecoration;
    return dec.color!;
  }

  testWidgets('tahmin tonu takvim lejantı ile halkada aynı', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await CycleSettingsRepository().saveCycleSettings(
      cycleLength: 28,
      periodLength: 7,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await const PeriodRepository().savePeriodLogs([
      PeriodLog(id: 'p', startDate: today.subtract(const Duration(days: 2))),
    ]);

    const screen = CalendarScreen();
    await pumpScreen(tester, screen, size: const Size(390, 844));

    final context = tester.element(find.byWidget(screen));
    final tokens = Theme.of(context).extension<AppTokens>()!;

    final lejantRegl = lejantTonu(context.tr('calendar_legend_period'));
    final lejantTahmin = lejantTonu(context.tr('calendar_legend_predicted'));

    // Halkanın aynı veriden ürettiği renkler.
    final info = PredictionService().getCycleInfo(
      [PeriodLog(id: 'p', startDate: today.subtract(const Duration(days: 2)))],
      userCycleLength: 28,
      userPeriodLength: 7,
      today: today,
    );
    final halka = CycleRingData.from(info: info, currentDay: 3, tokens: tokens);

    expect(
      halka.colors[2].toARGB32(),
      lejantRegl.toARGB32(),
      reason:
          'Yaşanmış regl günü: halka ile takvim lejantı farklı renkte. '
          'Kullanıcı aynı şeyi iki ekranda iki renkte görür.',
    );
    expect(
      halka.colors[3].toARGB32(),
      lejantTahmin.toARGB32(),
      reason:
          'Tahmin edilen gün: halka ile takvim lejantı farklı renkte. '
          'Lejant "bu renk tahmin demek" diye öğretiyor; halka başka bir '
          'ton kullanırsa o öğretim karşılığını bulmuyor.',
    );
    expect(
      lejantRegl.toARGB32(),
      isNot(lejantTahmin.toARGB32()),
      reason: 'İki lejant aynı renkse karşılaştırma hiçbir şey sınamaz',
    );
  });
}
