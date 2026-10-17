import 'care_plan_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navigation/navigation_service.dart';
import '../../data/local/reminder_scheduler.dart';
import '../../design_system/app_theme.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/services/reminder_planner.dart';
import '../../localization/app_localizations.dart';
import '../../domain/view_models/user_view_model.dart';
import '../calendar/view_models/calendar_view_model.dart';

/// Döngü tahminleri değiştikçe hatırlatıcı planını tazeler.
///
/// Plan eskiden **yalnızca** bildirim ayarları ekranından kuruluyordu. İki
/// sonucu vardı:
///
/// - Kullanıcı takvimde regl işaretleyince tahminler kayıyor ama planlanmış
///   bildirimler eski tarihte kalıyordu; regl başladıktan sonra "regl
///   yaklaşıyor" bildirimi geliyordu.
/// - Plan en fazla üç döngü ileri gittiği için yaklaşık üç ay sonra
///   hatırlatıcılar tamamen susuyordu. Kullanıcı ayar ekranına dönmedikçe bir
///   daha hiç bildirim almıyordu.
///
/// Uygulama açılışında ve her yeniden hesapta çalışır. Bildirim metinleri
/// cihazda üretildiği için çeviri burada, `MaterialApp` altında çözülüyor.
class ReminderSync extends StatefulWidget {
  const ReminderSync({super.key, required this.child, this.scheduler});

  final Widget child;

  /// Testte sahte bir zamanlayıcı verilebilsin diye.
  final ReminderScheduler? scheduler;

  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync> {
  final NotificationSettingsRepository _repository =
      NotificationSettingsRepository();
  late final ReminderScheduler _scheduler =
      widget.scheduler ?? ReminderScheduler();

  /// En son uygulanan planın imzası. Aynı imzayla yeniden yazmıyoruz.
  String? _applied;

  /// Aynı anda birden fazla planlama çalışmasın.
  bool _running = false;

  /// İzin sorusu kapandı mı?
  ///
  /// "Şimdi değil" hiçbir iz bırakmıyordu: plan imzası uygulanmadığı için
  /// bir sonraki yeniden çizimde `_sync` baştan çalışıyor ve kutu geri
  /// geliyordu. Kullanıcı kapatıyor, ekran tazeleniyor, kutu yine açılıyor.
  ///
  /// Kalıcı. Önceden oturumla sınırlıydı: "Şimdi değil" diyen kullanıcıya
  /// gerekçe her açılışta yeniden çıkıyordu. Sistem istemini reddetmiş
  /// kullanıcıya da — iOS istemi ikinci kez göstermediği için "Devam"
  /// hiçbir şey yapmıyordu. Artık bir kez soruluyor; sonrası kullanıcının
  /// elinde: ayar ekranı izin yokken bunu baştan söylüyor ve izin isteme
  /// düğmesi orada (bkz. `NotificationSettingsScreen`).
  bool _permissionSettledThisSession = false;

  static const String _askedKey = 'reminder_permission_asked';

  Future<bool> _askedBefore() async {
    if (_permissionSettledThisSession) return true;
    try {
      final prefs = await SharedPreferences.getInstance();
      return _permissionSettledThisSession = prefs.getBool(_askedKey) ?? false;
    } catch (e) {
      debugPrint('Reminder permission flag unreadable: $e');
      return false;
    }
  }

  Future<void> _settle() async {
    _permissionSettledThisSession = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_askedKey, true);
    } catch (e) {
      debugPrint('Reminder permission flag not saved: $e');
    }
  }

  Future<void> _sync(CalendarViewModel viewModel) async {
    if (_running) return;
    _running = true;

    try {
      final settings = await _repository.getGeneralSettings();
      final care = await loadCarePlanInput();
      if (!mounted) return;

      final now = DateTime.now();
      final signature = ReminderPlanner.signature(
        cycleInfo: viewModel.cycleInfo,
        settings: settings,
        now: now,
        care: care,
      );
      if (signature == _applied) return;

      final plan = ReminderPlanner.plan(
        cycleInfo: viewModel.cycleInfo,
        settings: settings,
        now: now,
        care: care,
      );

      // Plan boşsa yine de temizle.
      //
      // Önceden burada `return` vardı — hatırlatacak bir şey yokken izin
      // sormamak için — ve `apply` hiç çağrılmadığından `cancelAll()` da
      // çalışmıyordu. Düşükten sonra döngü tahmini olmadığı için plan tam
      // olarak boş oluyor; daha önce kurulmuş "18–22. hafta: anomali
      // taraması" bildirimi olduğu gibi kalıyordu. İptal izin gerektirmiyor,
      // yani izin sorusu hâlâ sorulmuyor.
      //
      // Bütün anahtarlar kapalıyken de aynı şey: eskiden imza kaydedilip
      // dönülüyor, kurulu bildirimler duruyordu.
      if (plan.isEmpty) {
        await _scheduler.cancelAll();
        _applied = signature;
        return;
      }

      // İzin buradan isteniyor çünkü regl ve doğurganlık hatırlatıcıları
      // varsayılan olarak açık: ayar ekranına hiç girmeyen kullanıcı
      // anahtarları "açık" görüyor ama kendisinden izin hiç istenmediği için
      // tek bir bildirim bile almıyordu.
      //
      // Plan boşken sormuyoruz — hatırlatacak bir şey yokken izin istemek
      // kullanıcıya anlamsız gelir. İlk kurulum tamamlanıp tahminler
      // oluştuğunda soruluyor. iOS sistem istemini yalnızca bir kez gösterir.
      //
      // Sistem isteminden **önce** gerekçe gösteriliyor. Kamera, Face ID ve
      // Sağlık izinlerinin gerekçesi Info.plist'ten sisteme geçiyor ve
      // istemde görünüyor; bildirim isteminde öyle bir alan yok. Kullanıcı
      // ana ekrana düşer düşmez bağlamsız bir kutu görüyordu — hem reddetme
      // oranını artırıyor hem de iOS istemi bir daha göstermediği için
      // kararı kalıcı hâle getiriyordu.
      // İzin zaten verilmişse gerekçeye gerek yok, doğrudan uygula.
      //
      // Bu kontrol yokken gerekçe kutusu izni çoktan vermiş kullanıcıya
      // **her** plan değişikliğinde yeniden açılıyordu: her açılışta, regl
      // işaretleyince, gebelik başlatınca, randevu girince. Oturum bayrağı
      // yalnızca "şimdi değil" ve reddedilme yolunda kuruluyordu; izin
      // verilen yolda hiç kurulmuyordu.
      if (await _scheduler.isPermissionGranted()) {
        if (!mounted) return;
        await _scheduler.apply(plan, localize: context.tr);
        _applied = signature;
        return;
      }

      if (await _askedBefore() || !mounted) return;

      final wantsToBeAsked = await _explainReminders(care.stage);
      if (!wantsToBeAsked) {
        await _settle();
        return;
      }
      if (!mounted) return;

      final granted = await _scheduler.requestPermission();
      await _settle();
      if (!granted) {
        // iOS sistem istemini ikinci kez göstermiyor; tekrar sormanın
        // karşılığı yok.
        return;
      }
      if (!mounted) return;

      await _scheduler.apply(plan, localize: context.tr);
      _applied = signature;
    } finally {
      _running = false;
    }
  }

  /// Sistem izin isteminden önceki gerekçe.
  ///
  /// "Şimdi değil" sistem istemini hiç açmıyor: iOS onu bir kez gösterip bir
  /// daha göstermediği için, kullanıcının hazır olmadığı anda yakmak kalıcı
  /// bir kayıp olurdu. Kutu bir daha kendiliğinden açılmıyor; izin ayar
  /// ekranındaki düğmeyle istenebilir.
  ///
  /// Gerekçe evreye göre: gebelikte ve lohusalıkta regl ve doğurganlık
  /// tahmini yok, hatırlatıcılar kontroller için. Önceden gebe kullanıcıya
  /// da "reglinin yaklaştığını haber verebilmemiz için" deniyordu.
  Future<bool> _explainReminders(LifeStage stage) async {
    // Diyalog **router'ın** navigator'ından açılıyor. `ReminderSync`
    // `MaterialApp.builder` içinde, yani Navigator'ın üstünde duruyor;
    // kendi context'iyle `showDialog` çağırmak "No Navigator" hatası verir
    // ve gerekçe hiç görünmezdi.
    final dialogContext = NavigationService().navigatorKey.currentContext;
    if (dialogContext == null) return false;

    final result = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('reminder_permission_title')),
        content: Text(
          ctx.tr(
            stage == LifeStage.cycle
                ? 'reminder_permission_body'
                : 'reminder_permission_body_care',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('reminder_permission_later')),
          ),
          FilledButton(
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('reminder_permission_continue')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CalendarViewModel>();

    // Kurulum bitmeden dokunmuyoruz. Onboarding'in ortasında bildirim izni
    // istemek hem erken hem kaba: kullanıcı henüz uygulamanın ne yaptığını
    // görmedi.
    final onboarded = context.select<UserViewModel, bool>(
      (vm) => vm.onboardingComplete,
    );

    // Partner modunda hiç çalışmıyor. Buradaki plan `CalendarViewModel`'den,
    // yani **cihazın kendi** döngü verisinden üretiliyor; partnerin öyle bir
    // verisi yok. Kapı yalnızca onboarding'e bakarken partner:
    //   * sahibin metniyle ("Reglinin yaklaştığını…") bildirim izni
    //     isteniyordu — kendi regli hakkında sanıyordu,
    //   * ve kendi boş takvimine göre hatırlatıcı planlanıyordu.
    // Partner modunda cihaz bildirimi yok; partner paylaşılan durumu
    // uygulamayı açınca görüyor.
    final isPartner = context.select<UserViewModel, bool>((vm) => vm.isPartner);

    // Yükleme sürerken tahminler henüz boş; o hâli planlamak anlamsız.
    if (onboarded && !isPartner && !viewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sync(viewModel);
      });
    }

    return widget.child;
  }
}
