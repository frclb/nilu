import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../domain/view_models/account_view_model.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../calendar/view_models/calendar_view_model.dart';

/// Bulut eşitlemeyi uygulamanın geri kalanına bağlar.
///
/// * Takvim ya da gebelik verisi değişince eşitleme planlanıyor (kısa bir
///   beklemeyle; veri gerçekten değiştiyse — bkz.
///   [AccountViewModel.scheduleSync]).
/// * Uygulama öne gelince başka cihazın yüklediği kopya soruluyor; arka
///   plana giderken bekleyen değişiklik hemen yükleniyor.
/// * Buluttan veri inince bellekteki kopyalar yenileniyor; hesap değişince
///   partner kimliği tazeleniyor; hesap silinirken partner verisi ve kimlik
///   de siliniyor.
///
/// Yalnızca kurulumu bitmiş, kendi kaydını tutan kullanıcı için: partner
/// rolündeki cihazın eşitlenecek kendi verisi yok.
class CloudSyncTrigger extends StatefulWidget {
  const CloudSyncTrigger({super.key, required this.child});

  final Widget child;

  @override
  State<CloudSyncTrigger> createState() => _CloudSyncTriggerState();
}

class _CloudSyncTriggerState extends State<CloudSyncTrigger>
    with WidgetsBindingObserver {
  AccountViewModel? _account;
  UserViewModel? _user;
  CalendarViewModel? _calendar;
  PregnancyViewModel? _pregnancy;
  bool _onboarded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_account != null) return;
    final account = _account = context.read<AccountViewModel>();
    final user = _user = context.read<UserViewModel>();
    final calendar = _calendar = context.read<CalendarViewModel>();
    final pregnancy = _pregnancy = context.read<PregnancyViewModel>();
    _onboarded = user.onboardingComplete;

    account
      ..onRemoteApplied = () async {
        await pregnancy.load();
        await calendar.refreshData();
      }
      ..onIdentityChanged = user.refreshAuthState
      ..deleteIdentityAndPartnerData = () async {
        final ok = await user.deleteRemoteData();
        if (ok) await user.forgetIdentity();
        return ok;
      };

    calendar.addListener(_dataChanged);
    pregnancy.addListener(_dataChanged);
    user.addListener(_userChanged);
  }

  bool get _active {
    final user = _user;
    return user != null && user.onboardingComplete && !user.isPartner;
  }

  void _dataChanged() {
    if (_active) _account?.scheduleSync();
  }

  void _userChanged() {
    final now = _user?.onboardingComplete ?? false;
    // Kurulum az önce bitti: kurulumda girilenler yüklensin.
    if (now && !_onboarded && _active) _account?.scheduleSync();
    _onboarded = now;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _account?.scheduleSync(immediately: true);
      case AppLifecycleState.paused:
        _account?.syncIfChanged();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _calendar?.removeListener(_dataChanged);
    _pregnancy?.removeListener(_dataChanged);
    _user?.removeListener(_userChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
