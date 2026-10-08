import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'design_system/app_theme.dart';
import 'localization/app_localizations.dart';
import 'localization/supported_locales.dart';
import 'core/navigation/app_router.dart';
import 'domain/view_models/theme_view_model.dart';
import 'data/datasources/ads_datasource.dart';
import 'presentation/lock/app_lock_gate.dart';
import 'presentation/reminders/reminder_sync.dart';
import 'presentation/widgets_preview/home_widget_sync.dart';
import 'presentation/calendar/view_models/calendar_view_model.dart';
import 'domain/view_models/intimacy_view_model.dart';
import 'domain/view_models/partner_view_model.dart';
import 'domain/view_models/pregnancy_view_model.dart';
import 'domain/view_models/user_view_model.dart';
import 'domain/view_models/subscription_view_model.dart';
import 'domain/services/subscription_service.dart';
import 'core/app_info.dart';
import 'core/firebase/firebase_config.dart';
import 'data/local/secure_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Global hata yakalama
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Mevcut kullanıcıların şifresiz kayıtlı sağlık verisini şifreli depoya
  // taşı. Repository'ler okumadan önce, yani runApp'ten önce çalışmalı.
  await const SecureStore().migrateFromSharedPreferences(
    SecureStore.sensitiveKeys,
  );

  // UserViewModel'ı önceden oluştur (router'a ihtiyaç duyduğu için)
  final userViewModel = UserViewModel();

  runApp(PeriodTrackerApp(userViewModel: userViewModel));

  // Ağ bağımlı SDK'lar ilk kareden **sonra** başlıyor.
  //
  // Önce `runApp`'ten önce ve **sırayla** bekleniyorlardı. Zaman aşımı
  // eklenmesi sonsuz beklemeyi kesti ama toplamı kesmedi: üçü arka arkaya
  // dörder saniye, yani en kötü durumda on iki saniye beyaz ekran. Gerçek
  // cihazda ölçüldü, reklam SDK'sı tek başına dördünü yakıyordu.
  //
  // Hiçbiri ilk kare için gerekli değil: ana ekran yalnızca cihazdaki
  // veriyi gösteriyor. Üçü birden ve paralel başlıyor; bitince kimlik
  // durumu tazeleniyor.
  unawaited(_startServices(userViewModel));
}

/// SDK'ları ilk kareden sonra, hep birlikte başlatır.
Future<void> _startServices(UserViewModel userViewModel) async {
  await Future.wait([
    _bootstrap('Firebase', FirebaseConfig.init),
    _bootstrap('RevenueCat', SubscriptionService.init),
    _bootstrap('Ads', AdsDatasource.init),
  ]);
  await userViewModel.refreshAuthState();
}

/// Açılışta bir SDK'yı başlatır; [limit] içinde bitmezse vazgeçer.
///
/// Vazgeçmek başlatmayı iptal etmiyor — çağrı arka planda sürüyor, yalnızca
/// ilk kare onu beklemiyor.
Future<void> _bootstrap(
  String name,
  Future<void> Function() init, {
  Duration limit = const Duration(seconds: 4),
}) async {
  try {
    await init().timeout(limit);
  } on TimeoutException {
    debugPrint('$name init timed out after ${limit.inSeconds}s — continuing.');
  } catch (e) {
    debugPrint('$name init failed: $e');
  }
}

class PeriodTrackerApp extends StatefulWidget {
  final UserViewModel userViewModel;

  const PeriodTrackerApp({super.key, required this.userViewModel});

  @override
  State<PeriodTrackerApp> createState() => _PeriodTrackerAppState();
}

class _PeriodTrackerAppState extends State<PeriodTrackerApp> {
  /// Router **bir kez** kurulur.
  ///
  /// Daha önce `build` içindeki bir `Builder`'da üretiliyordu; UserViewModel
  /// her `notifyListeners()` çağırdığında (ProxyProvider'lar yüzünden bu sık
  /// oluyor) yeni bir GoRouter oluşuyor ve gezinme yığını sıfırlanıyordu.
  /// Çıkış yapıp onboarding'e gidildikten sonra kullanıcının ana ekrana geri
  /// sıçramasının sebebi buydu.
  late final GoRouter _router = createAppRouter(widget.userViewModel);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.userViewModel),
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
              vm.applyPregnancies(
                gebelik.pregnancies,
                revision: gebelik.revision,
              );
            }
            return vm;
          },
        ),
        ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),

        // Abonelik durumu temayı besler: abonelik bitince premium tema
        // ücretsiz temaya düşmeli.
        ChangeNotifierProxyProvider<SubscriptionViewModel, ThemeViewModel>(
          create: (_) => ThemeViewModel(),
          update: (_, subscription, theme) {
            final vm = theme ?? ThemeViewModel();
            vm.setPremium(subscription.isPremium);
            return vm;
          },
        ),

        // ProxyProvider ile UserViewModel'daki ID'leri diğer ViewModel'lara enjekte ediyoruz
        ChangeNotifierProxyProvider<UserViewModel, IntimacyViewModel>(
          create: (_) => IntimacyViewModel(),
          update: (_, userVM, intimacyVM) {
            final vm = intimacyVM ?? IntimacyViewModel();
            vm.init(userVM.myId);
            return vm;
          },
        ),

        ChangeNotifierProxyProvider<UserViewModel, PartnerViewModel>(
          create: (_) => PartnerViewModel(),
          update: (_, userVM, partnerVM) {
            final vm = partnerVM ?? PartnerViewModel();
            vm.init(userVM.partnerId);
            return vm;
          },
        ),
      ],
      // Tema çeşidi provider'dan okunuyor. `_router` State üzerinde
      // `late final` olduğu için bu yeniden kurulum router'ı etkilemiyor —
      // eskiden burada bir Builder vardı ve her bildirimde yeni GoRouter
      // üretip gezinme yığınını sıfırlıyordu.
      child: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, _) {
          final flavor = themeViewModel.flavor;
          return MaterialApp.router(
            title: AppInfo.displayName,
            theme: AppTheme.light(flavor),
            darkTheme: AppTheme.dark(flavor),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            supportedLocales: appSupportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            // Kilit kapısı `MaterialApp`'in **içinde**: lokalizasyon ve tema
            // buradan geliyor. Yönlendirilen tüm içeriğin üstünde durur, yani
            // hangi ekranda olunursa olunsun kilit uygulanır.
            // ReminderSync kilidin içinde: bildirim planı ekran kilitliyken
            // de tazelenmeli, kullanıcı uygulamayı açmasa bile.
            // Yazı ölçeği üst sınırı.
            //
            // iOS erişilebilirlik boyutları 3.1 kata kadar çıkıyor. Ekranlar
            // bu ölçekte kullanılmaz hâle geliyordu: onboarding'de 689
            // piksel taşma, takvim ve grafikler ekran dışına çıkıyordu.
            // Sınırsız desteklemek yazı boyutuna göre yeniden düzenlenen
            // bir tasarım gerektiriyor; o gelene kadar sınır, uygulamayı
            // kırık değil sadece daha az büyük tutuyor.
            //
            // 1.5 seçildi: iOS'un **erişilebilirlik dışı** en büyük boyutu
            // (~1.35) tamamen destekleniyor, üstüne de pay kalıyor.
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.5,
              // Boşluğa dokunmak klavyeyi kapatır.
              //
              // Kapatmanın tek yolu klavyenin kendi tuşuydu; "Ad Soyad" gibi
              // tek satırlık alanlarda dönüş tuşu klavyeyi kapatmıyor ve
              // kullanıcı altındaki kaydet düğmesine ulaşamıyordu.
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                // Widget kilidin dışında: uygulama kilitliyken de ana
                // ekran widget'ının günü doğru kalsın.
                child: HomeWidgetSync(
                  child: AppLockGate(
                    child: ReminderSync(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
