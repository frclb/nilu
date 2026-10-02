import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';

/// Takvim hücresinin içeriği hücreye sığar mı?
///
/// Hücre içeriği sabit: 36 pt daire + 3 pt boşluk + 8 pt gösterge = 47 pt.
/// Hücre **yüksekliği** ise genişlikten türetiliyordu (`childAspectRatio:
/// 1.0`), yani dar ekranda 47'nin altına düşüyordu. iPhone 16e'de takvimin
/// her hafta satırında sarı taşma şeridi çıkıyordu.
///
/// Uygulamayı açıp takvim sekmesine geçen test bunu görmüyordu: takvim
/// verisini asenkron okuyor ve o sırada ızgara yerine dönen bir çark
/// çiziliyor — ızgara hiç ölçülmeden test bitiyordu. Izgara burada doğrudan,
/// yüklenmesi beklenerek çiziliyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpGridAt(WidgetTester tester, double width) async {
    // Şifreli depo da sahtelenmeli: gerçek kanal testte yanıt vermiyor,
    // `isLoading` hiç kapanmıyor ve ızgara hiç çizilmiyordu.
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr')],
          locale: const Locale('tr'),
          home: Scaffold(
            body: MultiProvider(
              // Uygulamadaki gibi: ızgara gebelik izini de okuyor.
              providers: [
                ChangeNotifierProvider(create: (_) => PregnancyViewModel()),
                ChangeNotifierProvider(create: (_) => CalendarViewModel()),
              ],
              child: Center(
                child: SizedBox(width: width, child: const CalendarGrid()),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    // `pumpAndSettle` değil: veri yüklenemezse dönen çark hiç durmuyor ve
    // settle zaman aşımına uğruyor. Taşma yerleşim sırasında bildiriliyor,
    // birkaç kare yetiyor.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ızgara her genişlikte taşmadan çizilir', () {
    // Takvim kartının iç genişliği. En dar uç, dar bir telefonda kartın
    // kenar boşlukları düşüldükten sonra kalan yer.
    for (final width in [300.0, 320.0, 340.0, 360.0, 390.0, 480.0, 600.0]) {
      testWidgets('${width.round()} pt', (tester) async {
        await pumpGridAt(tester, width);

        // Izgaranın gerçekten çizildiğinden emin ol: yükleme çarkı
        // duruyorsa iddia hiçbir şey kanıtlamaz.
        expect(
          find.byType(GridView),
          findsOneWidget,
          reason: '${width.round()} pt: ızgara çizilmemiş (hâlâ yükleniyor?)',
        );

        expect(
          tester.takeException(),
          isNull,
          reason: '${width.round()} pt: takvim hücresi taşıyor',
        );
      });
    }
  });
}
