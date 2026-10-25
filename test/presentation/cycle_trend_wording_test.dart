import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/insights/widgets/cycle_trend_card.dart';

/// İçgörülerdeki döngü kartı sayı 1 olduğunda tekil yazıyor.
///
/// Türkçede tekil/çoğul ayrımı yok, tek anahtar yetiyordu. Diğer beş dilde
/// var: en kısa ile en uzun döngü arasında 1 gün fark olunca İngilizce
/// "only 1 days", İspanyolca "solo 1 días" yazıyordu.
class _Abone extends SubscriptionViewModel {
  _Abone({required this.premium});
  final bool premium;

  @override
  bool get isPremium => premium;

  @override
  bool get isLoading => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// [araliklar] uzunluğunda tamamlanmış döngüler üreten regl kayıtları.
  List<PeriodLog> regller(List<int> araliklar) {
    var bas = DateTime(2025, 1, 1);
    final sonuc = <PeriodLog>[];
    for (var i = 0; i <= araliklar.length; i++) {
      sonuc.add(
        PeriodLog(
          id: 'p$i',
          startDate: bas,
          endDate: DateTime(bas.year, bas.month, bas.day + 4),
        ),
      );
      if (i < araliklar.length) {
        bas = DateTime(bas.year, bas.month, bas.day + araliklar[i]);
      }
    }
    return sonuc;
  }

  Future<void> kartiAc(
    WidgetTester tester,
    String dil,
    List<int> araliklar, {
    bool premium = true,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await const PeriodRepository().savePeriodLogs(regller(araliklar));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale(dil)],
          locale: Locale(dil),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider(create: (_) => CalendarViewModel()),
                  ChangeNotifierProvider<SubscriptionViewModel>(
                    create: (_) => _Abone(premium: premium),
                  ),
                ],
                child: const CycleTrendCard(),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  const beklenen = {
    'en': (
      fark1:
          'Your cycles are steady: only 1 day between the shortest and '
          'the longest.',
      fark2:
          'Your cycles are steady: only 2 days between the shortest and '
          'the longest.',
      baslik1: 'Last cycle',
      baslik2: 'Last 2 cycles',
      kilit1: 'See 1 more cycle with Premium.',
      kilit2: 'See 2 more cycles with Premium.',
    ),
    'es': (
      fark1:
          'Tus ciclos son regulares: solo 1 día entre el más corto y el '
          'más largo.',
      fark2:
          'Tus ciclos son regulares: solo 2 días entre el más corto y el '
          'más largo.',
      baslik1: 'Último ciclo',
      baslik2: 'Últimos 2 ciclos',
      kilit1: 'Con Premium puedes ver 1 ciclo más.',
      kilit2: 'Con Premium puedes ver 2 ciclos más.',
    ),
  };

  for (final MapEntry(key: dil, value: metin) in beklenen.entries) {
    group(dil, () {
      testWidgets('1 günlük fark tekil yazılıyor', (tester) async {
        await kartiAc(tester, dil, [28, 29]);
        expect(find.text(metin.fark1), findsOneWidget);
        expect(find.text(metin.baslik2), findsOneWidget);
      });

      testWidgets('2 günlük fark çoğul yazılıyor', (tester) async {
        await kartiAc(tester, dil, [28, 30]);
        expect(find.text(metin.fark2), findsOneWidget);
      });

      testWidgets('tek döngüde başlık tekil', (tester) async {
        await kartiAc(tester, dil, [28]);
        expect(find.text(metin.baslik1), findsOneWidget);
      });

      // Ücretsiz sürüm son 3 döngüyü gösteriyor: 4 döngüde 1, 5 döngüde 2
      // döngü gizli.
      testWidgets('gizlenen tek döngü tekil yazılıyor', (tester) async {
        await kartiAc(tester, dil, [28, 28, 28, 28], premium: false);
        expect(find.text(metin.kilit1), findsOneWidget);
      });

      testWidgets('gizlenen iki döngü çoğul yazılıyor', (tester) async {
        await kartiAc(tester, dil, [28, 28, 28, 28, 28], premium: false);
        expect(find.text(metin.kilit2), findsOneWidget);
      });
    });
  }
}
