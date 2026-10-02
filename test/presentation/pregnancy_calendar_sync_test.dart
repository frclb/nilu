import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';

import 'screen_harness.dart';

/// Gebelik değişince takvim koruması **kendiliğinden** güncelleniyor mu?
///
/// Koruma (`CalendarViewModel._canRecordPeriods`) evreyi gebelik
/// ViewModel'inden alıyor. Bağlantı kopsaydı her şey derlenir, birim
/// testler geçer, ama gebeliğini bitiren kullanıcı takvimde regl
/// işaretleyemezdi — ya da gebeliğini yeni işaretleyen kullanıcı hâlâ
/// işaretleyebilirdi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  testWidgets('işaretleme ve sonlandırma takvime anında ulaşıyor', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    const ekran = SizedBox(key: Key('kok'));
    await pumpScreen(tester, ekran, size: const Size(390, 844));

    final ctx = tester.element(find.byKey(const Key('kok')));
    final gebelik = ctx.read<PregnancyViewModel>();
    final takvim = ctx.read<CalendarViewModel>();
    expect(takvim.lifeStage, LifeStage.cycle);

    final bugun = DateTime.now();
    await tester.runAsync(
      () => gebelik.startFromLmp(
        lmp: bugun.subtract(const Duration(days: 50)),
        cycleLength: 28,
      ),
    );
    await tester.pump();

    expect(
      takvim.lifeStage,
      LifeStage.pregnancy,
      reason: 'Gebelik işaretlendi ama takvim hâlâ döngü evresinde',
    );
    expect(
      await tester.runAsync(() => takvim.togglePeriodDay(bugun)),
      isFalse,
      reason: 'Gebe kullanıcı takvimde regl işaretleyebiliyor',
    );

    await tester.runAsync(
      () => gebelik.end(PregnancyOutcome.miscarriage, at: bugun),
    );
    await tester.pump();

    expect(takvim.lifeStage, LifeStage.cycle);
    expect(
      await tester.runAsync(() => takvim.togglePeriodDay(bugun)),
      isTrue,
      reason: 'Gebeliği biten kullanıcı regl işaretleyemiyor',
    );
  });
}
