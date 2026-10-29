import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'design_system/app_theme.dart';
import 'localization/app_localizations.dart';
import 'localization/supported_locales.dart';
import 'core/navigation/app_router.dart';
import 'core/navigation/route_names.dart';
import 'core/platform/launch_actions.dart';
import 'domain/view_models/theme_view_model.dart';
import 'data/datasources/ads_datasource.dart';
import 'presentation/account/cloud_sync_trigger.dart';
import 'presentation/lock/app_lock_gate.dart';
import 'presentation/reminders/reminder_sync.dart';
import 'presentation/widgets_preview/home_widget_sync.dart';
import 'presentation/calendar/view_models/calendar_view_model.dart';
import 'domain/view_models/account_view_model.dart';
import 'domain/view_models/intimacy_view_model.dart';
import 'domain/view_models/partner_view_model.dart';
import 'domain/view_models/pregnancy_view_model.dart';
import 'domain/view_models/user_view_model.dart';
import 'domain/view_models/subscription_view_model.dart';
import 'domain/services/auth_action_link.dart';
import 'domain/services/pairing_token.dart';
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

  // Uygulama silinip yeniden kurulduysa Anahtar Zinciri'nde kalan eski
  // kayıtlar silinir (iOS onları uygulamayla birlikte silmiyor).
  await const SecureStore().clearIfFreshInstall();

  // Mevcut kullanıcıların şifresiz kayıtlı sağlık verisini şifreli depoya
  // taşı. Repository'ler okumadan önce, yani runApp'ten önce çalışmalı.
  await const SecureStore().migrateFromSharedPreferences(
    SecureStore.sensitiveKeys,
  );

  // UserViewModel'ı önceden oluştur (router'a ihtiyaç duyduğu için)
  final userViewModel = UserViewModel();
  // İsteğe bağlı hesap ve bulut eşitleme. Firebase hazır olunca tazeleniyor.
  final accountViewModel = AccountViewModel();

  runApp(
    PeriodTrackerApp(
      userViewModel: userViewModel,
      accountViewModel: accountViewModel,
    ),
  );

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
  unawaited(_startServices(userViewModel, accountViewModel));
}

/// SDK'ları ilk kareden sonra, hep birlikte başlatır.
Future<void> _startServices(
  UserViewModel userViewModel,
  AccountViewModel accountViewModel,
) async {
  // `init` kendi hatasını yakalıyor; bu Future hiç hata vermiyor.
  final firebase = FirebaseConfig.init();
  await Future.wait([
    _bootstrap('Firebase', () => firebase),
    _bootstrap('RevenueCat', SubscriptionService.init),
    _bootstrap('Ads', AdsDatasource.init),
  ]);
  await userViewModel.refreshAuthState();
  await accountViewModel.refresh();

  // Firebase süre sınırını aştıysa başlatma arka planda sürüyor. Bittiğinde
  // kimlik ve hesap yeniden okunmalı: yoksa giriş yapmış kullanıcı bir
  // sonraki açılışa kadar "giriş yapılmadı" görüyor ve eşitleme başlamıyor.
  if (!FirebaseConfig.isAvailable) {
    unawaited(
      firebase.then((_) async {
        if (!FirebaseConfig.isAvailable) return;
        await userViewModel.refreshAuthState();
        await accountViewModel.refresh();
      }),
    );
  }
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

  /// Verilmezse uygulama kendisi kuruyor (testler).
  final AccountViewModel? accountViewModel;

  /// Uygulamayı açan bağlantılar. Verilmezse telefonda `app_links`; testte
  /// (masaüstü) hiçbiri.
  final Stream<Uri>? links;

  const PeriodTrackerApp({
    super.key,
    required this.userViewModel,
    this.accountViewModel,
    this.links,
  });

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

  late final AccountViewModel _account =
      widget.accountViewModel ?? AccountViewModel();

  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    LaunchActions.attach(_onLaunchAction);
    final links =
        widget.links ??
        (!kIsWeb && (Platform.isIOS || Platform.isAndroid)
            ? AppLinks().uriLinkStream
            : null);
    _links = links?.listen(
      _onLink,
      onError: (Object e) => debugPrint('App link failed: $e'),
    );
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  /// Partner davet bağlantısı uygulamayı açtı: kod okutulmuş gibi
  /// işleniyor. Hesap yoksa okutma ekranı önce girişi soruyor.
  ///
  /// E-postadaki doğrulama ve şifre yenileme bağlantıları da buradan
  /// geliyor ([_onAuthLink]).
  void _onLink(Uri uri) {
    if (AuthActionLink.fromUri(uri) case final auth?) {
      _onAuthLink(auth);
      return;
    }
    final kod = PairingToken.fromInviteLink(uri);
    if (kod == null) return;
    _whenSettled(
      () => _router.pushNamed(
        RouteNames.partnerScan,
        queryParameters: {'k': kod},
      ),
    );
  }

  /// Doğrulama bağlantısında kod uygulanıyor; adres doğrulanınca doğrulama
  /// ekranı kendisi devam ettiriyor. Şifre yenileme bağlantısı yeni şifre
  /// ekranını açıyor.
  void _onAuthLink(AuthActionLink link) {
    switch (link.action) {
      case AuthAction.verifyEmail:
        unawaited(_account.applyEmailVerification(link.code!));
      case AuthAction.verified:
        unawaited(_account.checkEmailVerified());
      case AuthAction.resetPassword:
        _whenSettled(
          () => _router.pushNamed(
            RouteNames.resetPassword,
            queryParameters: {'code': link.code!},
          ),
        );
    }
  }

  /// Açılış yönlendirmesi bitince [open]'ı çalıştırır.
  ///
  /// Durum yüklenirken açılan sayfayı açılış yönlendirmesi eziyordu.
  void _whenSettled(VoidCallback open) {
    final delegate = _router.routerDelegate;
    bool settled() {
      if (!widget.userViewModel.isLoaded) return false;
      final path = delegate.currentConfiguration.uri.path;
      return path.isNotEmpty && path != '/' && path != splashPath;
    }

    if (settled()) {
      open();
      return;
    }
    late final VoidCallback listener;
    listener = () {
      if (!settled()) return;
      delegate.removeListener(listener);
      WidgetsBinding.instance.addPostFrameCallback((_) => open());
    };
    delegate.addListener(listener);
  }

  /// Health Connect'in "gizlilik politikası" bağlantısı uygulamayı açtı.
  ///
  /// Politika yönlendirici açılış ekranından çıkıp yerine oturduktan sonra
  /// açılıyor; durum yüklenirken açılınca açılış yönlendirmesi onu
  /// eziyordu. Politika kapanınca, pencere yalnızca onun için açıldıysa
  /// kapanıyor: kullanıcı ana sayfaya değil Health Connect'in izin
  /// ekranına dönüyor.
  void _onLaunchAction(String action) {
    if (action != LaunchActions.privacyPolicy) return;
    final delegate = _router.routerDelegate;

    // Kapanışı yönlendiricinin konumundan izle: sistem geri tuşuyla
    // kapanan sayfada `pushNamed`'in döndürdüğü bekleme tamamlanmıyor.
    void open() {
      final policy = _router.namedLocation(RouteNames.privacyPolicy);
      var shown = false;
      late final VoidCallback watch;
      watch = () {
        // `push` adresi değiştirmiyor; açılan sayfa yığının son öğesi.
        final config = delegate.currentConfiguration;
        final path = config.isEmpty ? '' : config.last.matchedLocation;
        if (path == policy) {
          shown = true;
        } else if (shown) {
          delegate.removeListener(watch);
          LaunchActions.done();
        }
      };
      delegate.addListener(watch);
      _router.pushNamed(RouteNames.privacyPolicy);
    }

    _whenSettled(open);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.userViewModel),
        ChangeNotifierProvider.value(value: _account),
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
            vm.init(
              userVM.myId,
              hasPartner: userVM.hasPartner && !userVM.isPartner,
            );
            return vm;
          },
        ),

        ChangeNotifierProxyProvider<UserViewModel, PartnerViewModel>(
          create: (_) => PartnerViewModel(),
          update: (_, userVM, partnerVM) {
            final vm = partnerVM ?? PartnerViewModel();
            // Yalnızca partner rolünde: sahibin cihazı partnerinin
            // dokümanını dinlemiyor (partner bir şey paylaşmıyor).
            vm.init(
              userVM.isPartner ? userVM.partnerId : null,
              requestToken: userVM.pendingRequestToken,
              myUid: userVM.myId,
            );
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
                // ekran widget'ının günü doğru kalsın. Bulut eşitleme de:
                // öne gelince kilit açılmadan önce başlayabilir.
                child: HomeWidgetSync(
                  child: CloudSyncTrigger(
                    child: AppLockGate(
                      child: ReminderSync(
                        child: child ?? const SizedBox.shrink(),
                      ),
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
