import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'design_system/app_theme.dart';
import 'localization/app_localizations.dart';
import 'core/navigation/app_router.dart';
import 'domain/view_models/theme_view_model.dart';
import 'presentation/lock/app_lock_gate.dart';
import 'presentation/calendar/view_models/calendar_view_model.dart';
import 'domain/view_models/intimacy_view_model.dart';
import 'domain/view_models/partner_view_model.dart';
import 'domain/view_models/user_view_model.dart';
import 'domain/view_models/subscription_view_model.dart';
import 'domain/services/subscription_service.dart';
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

  // Firebase Init
  await FirebaseConfig.init();

  // RevenueCat Init
  await SubscriptionService.init();

  // UserViewModel'ı önceden oluştur (router'a ihtiyaç duyduğu için)
  final userViewModel = UserViewModel();

  runApp(PeriodTrackerApp(userViewModel: userViewModel));
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
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
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
            title: 'Period Tracker',
            theme: AppTheme.light(flavor),
            darkTheme: AppTheme.dark(flavor),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            supportedLocales: const [
              Locale('tr', ''),
              Locale('en', ''),
              Locale('de', ''),
              Locale('fr', ''),
              Locale('es', ''),
              Locale('pt', ''),
            ],
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
            builder: (context, child) =>
                AppLockGate(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
