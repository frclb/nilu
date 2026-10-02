import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/profile/privacy_security_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// "Hesabımı Sil" bellekteki kopyaları da silmeli.
///
/// Silme depoyu tamamen temizliyordu ama ardından yalnızca kullanıcı
/// durumu yeniden okunuyordu. Gebelik ve takvim ViewModel'leri eski
/// kayıtları bellekte tutmaya devam ediyordu: kullanıcı verisini silip
/// onboarding'den yeniden geçiyor, karşısına silinmiş doğumun lohusa
/// panosu çıkıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  testWidgets('silmeden sonra gebelik ve döngü verisi bellekte de yok', (
    tester,
  ) async {
    await seedPostpartum(daysSinceBirth: 10);
    await seedCycles(lastStartAgo: 320);

    await pumpRouter(
      tester,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PrivacySecurityScreen()),
        GoRoute(
          path: '/onboarding',
          name: RouteNames.onboarding,
          builder: (_, _) => const Scaffold(body: Text('onboarding')),
        ),
      ],
    );
    final ctx = tester.element(find.byType(PrivacySecurityScreen));
    final gebelik = ctx.read<PregnancyViewModel>();
    final takvim = ctx.read<CalendarViewModel>();
    expect(gebelik.stage, LifeStage.postpartum, reason: 'Ön koşul');
    expect(takvim.periodLogs, isNotEmpty, reason: 'Ön koşul');

    final sil = find.text(ctx.tr('privacy_delete_account'));
    await tester.scrollUntilVisible(sil, 300);
    await tester.tap(sil);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ctx.tr('privacy_delete_confirm')));
    await settleAsync(tester, rounds: 6);

    expect(find.text('onboarding'), findsOneWidget);
    expect(
      gebelik.pregnancies,
      isEmpty,
      reason:
          'Silinmiş gebelik bellekte duruyor: onboarding sonrası lohusa '
          'panosu açılır',
    );
    expect(gebelik.stage, LifeStage.cycle);
    expect(gebelik.currentEvents, isEmpty);
    expect(takvim.periodLogs, isEmpty, reason: 'Silinmiş regl kayıtları');
    expect(takvim.dailyLogs, isEmpty);
    expect(takvim.lifeStage, LifeStage.cycle);
  });
}
