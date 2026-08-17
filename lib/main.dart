import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'design_system/app_theme.dart';
import 'localization/app_localizations.dart';
import 'core/navigation/app_router.dart';
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

class PeriodTrackerApp extends StatelessWidget {
  final UserViewModel userViewModel;

  const PeriodTrackerApp({super.key, required this.userViewModel});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userViewModel),
        ChangeNotifierProvider(create: (_) => CalendarViewModel()),
        ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),

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
      child: Builder(
        builder: (context) {
          final router = createAppRouter(context.read<UserViewModel>());
          return MaterialApp.router(
            title: 'Period Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
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
            routerConfig: router,
          );
        },
      ),
    );
  }
}
