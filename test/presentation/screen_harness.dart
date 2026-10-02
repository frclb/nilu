import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/navigation/navigation_service.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/view_models/intimacy_view_model.dart';
import 'package:period_tracker/domain/view_models/partner_view_model.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/domain/view_models/theme_view_model.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';

/// Ekranları tek başına çizen ortak düzenek.
///
/// İki tarama bunu paylaşıyor: boş depoyla (`every_screen_test`) ve gerçek
/// döngü verisiyle (`every_screen_with_data_test`). Düzeneği kopyalamak yerine
/// buraya aldım; bu oturumda bulunan hataların çoğu aynı kuralın iki yerde
/// yazılıp zamanla ayrışmasıydı — sağlayıcı listesi ya da boyut kümesi iki
/// dosyada ayrı dursa biri güncellenip öteki eskirdi.

/// Telefon, katlanabilir ve tablet.
const Map<String, Size> screenSizes = <String, Size>{
  'iPhone 16e': Size(390, 844),
  'iPhone Duo (kapalı)': Size(466, 678),
  'iPad Pro 13"': Size(1032, 1376),
};

/// `local_auth` platform kanalı testte yok; ona dokunan ekranlar yükleme
/// durumunda takılı kalıyordu.
void mockMissingPlatformChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/local_auth'),
        (call) async =>
            call.method == 'getAvailableBiometrics' ? <String>[] : false,
      );
}

/// Uygulamadaki sağlayıcı kümesinin aynısı — `main.dart` ile birebir.
///
/// Burada başta düz `ChangeNotifierProvider` kullanıyordum. Uygulama ise üç
/// ViewModel'i `ChangeNotifierProxyProvider` ile kuruyor ve **kurulum anında**
/// `init`/`setPremium` çağırıyor. Düz sağlayıcıda o çağrı hiç olmadığı için
/// `PartnerViewModel.isLoaded` sonsuza dek `false` kalıyordu: partner panosu
/// testte yalnızca dönen bir çarkı çiziyor, ekranın geri kalan bin satırı hiç
/// çalışmıyordu. Test geçiyordu ama hiçbir şey sınamıyordu.
Widget wrapWithProviders(
  Widget screen, {
  UserViewModel? userViewModel,
  PartnerViewModel? partnerViewModel,
}) => MultiProvider(
  providers: [
    if (userViewModel != null)
      ChangeNotifierProvider.value(value: userViewModel)
    else
      ChangeNotifierProvider(create: (_) => UserViewModel()),
    ChangeNotifierProvider(create: (_) => PregnancyViewModel()..load()),

    // Takvim koruması evreyi gebelik ViewModel'inden alıyor. Gebelik
    // bittiği an takvim de biliyor; bir ekranın "takvimi yenilemeyi"
    // hatırlaması gerekmiyor — unutulsaydı gebeliği biten kullanıcı regl
    // işaretleyemezdi.
    ChangeNotifierProxyProvider<PregnancyViewModel, CalendarViewModel>(
      create: (_) => CalendarViewModel(),
      update: (_, gebelik, takvim) {
        final vm = takvim ?? CalendarViewModel();
        if (gebelik.loaded) {
          vm.applyPregnancies(gebelik.pregnancies, revision: gebelik.revision);
        }
        return vm;
      },
    ),
    ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),
    ChangeNotifierProxyProvider<SubscriptionViewModel, ThemeViewModel>(
      create: (_) => ThemeViewModel(),
      update: (_, subscription, theme) {
        final vm = theme ?? ThemeViewModel();
        vm.setPremium(subscription.isPremium);
        return vm;
      },
    ),
    ChangeNotifierProxyProvider<UserViewModel, IntimacyViewModel>(
      create: (_) => IntimacyViewModel(),
      update: (_, userVM, intimacyVM) {
        final vm = intimacyVM ?? IntimacyViewModel();
        vm.init(userVM.myId);
        return vm;
      },
    ),
    ChangeNotifierProxyProvider<UserViewModel, PartnerViewModel>(
      create: (_) => partnerViewModel ?? PartnerViewModel(),
      update: (_, userVM, partnerVM) {
        final vm = partnerVM ?? partnerViewModel ?? PartnerViewModel();
        vm.init(userVM.partnerId);
        return vm;
      },
    ),
  ],
  child: screen,
);

/// Ekranı verilen boyutta çizer.
///
/// `runAsync` şart: `Localizations` sözlüğü varlıklardan asenkron okunuyor ve
/// çözülene kadar ağaca `SizedBox` konuyor. Yalnızca `pump` edilen bir testte
/// ekran hiç oluşmuyor, iddia da boş ağaçta sınanıp sessizce geçiyor.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  required Size size,
  Locale locale = const Locale('tr'),
  UserViewModel? userViewModel,
  PartnerViewModel? partnerViewModel,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        // Diyaloğunu `NavigationService` anahtarından açan ekranlar için
        // (bkz. `ReminderSync`). Verilmezse o diyaloglar testte hiç açılmaz.
        navigatorKey: navigatorKey,
        theme: AppTheme.light(AppFlavor.plum),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: locale,
        supportedLocales: [locale],
        home: wrapWithProviders(
          screen,
          userViewModel: userViewModel,
          partnerViewModel: partnerViewModel,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  // Birkaç kare daha. Asenkron yükleme zincirleri tek karede bitmiyor:
  // `UserViewModel` tercihleri okuyor, bildiriyor; `ProxyProvider` bunun
  // üzerine `PartnerViewModel.init` çağırıyor; o da akışa abone oluyor ve
  // akıştan gelen ilk kayıt bir sonraki kareye düşüyor. Sabit sayıda kare
  // kullanıyorum: `pumpAndSettle` bu ekranlardaki süreğen animasyonlarda
  // zaman aşımına düşüyor. Gerçek uygulama zaten saniyede 60 kare çiziyor,
  // yani buradaki tek kare test düzeneğine özgü bir darlıktı — panonun
  // içeriği o yüzden hiç çizilmiyordu.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Ekranı **gerçek bir yönlendiriciyle** ve sağlayıcılar `MaterialApp`'in
/// üstündeyken çizer — uygulamadaki (`main.dart`) dizilişle aynı.
///
/// [pumpScreen] iki yerde yetmiyor:
///
/// - `goNamed`/`pushNamed` çağıran ekranlar düz `MaterialApp(home:)`
///   altında hata fırlatıyor; gezinme hiç sınanamıyor.
/// - Orada sağlayıcılar ilk rotanın **içinde**. Alt sayfa ve diyaloglar
///   navigator'a ayrı rota olarak ekleniyor, yani sağlayıcıları görmüyor:
///   sayfanın içinden `context.read` hata verirdi. Uygulamada öyle değil.
///
/// Kök navigator `NavigationService` anahtarını kullanıyor: o servisle
/// kapanan ekranlar (kayıt ekranı) testte de kapanabilsin.
Future<GoRouter> pumpRouter(
  WidgetTester tester, {
  required List<RouteBase> routes,
  String initialLocation = '/',
  Size size = const Size(390, 844),
  Locale locale = const Locale('tr'),
  GoRouter? router,
  UserViewModel? userViewModel,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final yonlendirici =
      router ??
      GoRouter(
        navigatorKey: NavigationService().navigatorKey,
        initialLocation: initialLocation,
        routes: routes,
      );
  addTearDown(yonlendirici.dispose);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      wrapWithProviders(
        userViewModel: userViewModel,
        MaterialApp.router(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: locale,
          supportedLocales: [locale],
          routerConfig: yonlendirici,
        ),
      ),
    );
    // Sağlayıcılar tembel: ilk okunduklarında kuruluyorlar. Uygulamada
    // takvim açılışta okunuyor (`ReminderSync` onu izliyor) ve gebelik
    // kaydı onunla birlikte yükleniyor. İlk ekran ikisini de okumuyorsa
    // testte yükleme ancak sonraki bir ekranda başlıyordu ve iddialar
    // evre henüz "döngü"yken sınanıyordu.
    final kok = tester.element(find.byType(MaterialApp));
    kok.read<PregnancyViewModel>();
    kok.read<CalendarViewModel>();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  });
  await settleAsync(tester);
  return yonlendirici;
}

/// Depoya yazan bir işlemden sonra: gerçek zamanlı bekleme ve birkaç kare.
///
/// Depo işlemleri sahte zamanda ilerlemiyor; yalnızca `pump` etmek, kaydın
/// henüz yazılmadığı bir ağaçta iddia sınamak demek.
Future<void> settleAsync(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }
}
