import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/local/reminder_scheduler.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../domain/models/notification_settings.dart';
import '../../domain/services/reminder_planner.dart';
import '../../core/platform/app_settings_link.dart';
import '../../localization/app_localizations.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/app_layout.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationSettingsRepository _repository =
      NotificationSettingsRepository();

  GeneralNotificationSettings _settings = const GeneralNotificationSettings();
  bool _isLoading = true;

  /// Bildirim izni alınamadı mı?
  ///
  /// Eskiden bu bir snackbar'dı ve iki sorunu vardı: kullanıcıyı ekrandan
  /// ekrana takip ediyor, süresi dolduğu hâlde kapanmıyordu. Üstelik mesajın
  /// geçici olması da yanlıştı — anahtar geri kapandı, sebebi ekranda
  /// kalmalı. Kullanıcı izni verip anahtarı tekrar açtığında kendiliğinden
  /// kayboluyor.
  bool _permissionBlocked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.getGeneralSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  /// Her değişiklik anında kalıcılaştırılır ve **hatırlatıcılar yeniden
  /// planlanır**.
  ///
  /// Eskiden yalnızca tercih kaydediliyordu; hiçbir bildirim planlanmadığı
  /// için kullanıcı hatırlatıcıyı açsa da bildirim almıyordu.
  Future<void> _update(GeneralNotificationSettings next) async {
    final previous = _settings;
    setState(() => _settings = next);
    await _repository.saveGeneralSettings(next);

    final applied = await _reschedule(next);
    if (!applied) {
      // İzin verilmedi: anahtar açık kalırsa kullanıcı hatırlatıcıların
      // kurulduğunu sanıyor ama hiçbir bildirim gelmiyor. Eski hâline
      // döndürülüyor ve kayıt da geri alınıyor.
      if (!mounted) return;
      setState(() => _settings = previous);
      await _repository.saveGeneralSettings(previous);
    }
  }

  /// Planı uygular. İzin alınamadıysa ya da planlama başarısız olduysa
  /// `false` döner.
  ///
  /// Hata da reddedilme gibi ele alınıyor: kullanıcı açısından ikisi de
  /// "hatırlatıcı kurulmadı" demek. Yakalanmazsa anahtar açık kalıyor ve
  /// kayıtlı kalıyordu — bildirim gelmediği hâlde ayar "açık" görünüyordu.
  Future<bool> _reschedule(GeneralNotificationSettings settings) async {
    try {
      return await _applyPlan(settings);
    } catch (e) {
      debugPrint('Reminder scheduling failed: $e');
      if (mounted) setState(() => _permissionBlocked = true);
      return false;
    }
  }

  Future<bool> _applyPlan(GeneralNotificationSettings settings) async {
    final cycleInfo = context.read<CalendarViewModel>().cycleInfo;
    final localize = context.tr;

    final scheduler = ReminderScheduler();

    // Kullanıcı ilk kez bir hatırlatıcı açtığında izin iste.
    final wantsReminders =
        settings.periodReminders ||
        settings.fertileWindow ||
        settings.dailyLogs;
    if (wantsReminders) {
      final granted = await scheduler.requestPermission();
      if (!granted) {
        if (!mounted) return false;
        setState(() => _permissionBlocked = true);
        return false;
      }
    }

    if (_permissionBlocked && mounted) {
      setState(() => _permissionBlocked = false);
    }

    final plan = ReminderPlanner.plan(
      cycleInfo: cycleInfo,
      settings: settings,
      now: DateTime.now(),
    );

    await scheduler.apply(plan, localize: localize);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Hormonal doğum kontrolünde doğurganlık verisi kaynakta hiç
    // üretilmiyor, dolayısıyla o hatırlatıcı hiçbir zaman planlanamaz.
    // Anahtarı yine de göstermek, açıldığında hiçbir şey olmayan bir
    // düğme bırakırdı — kullanıcı bildirimin gelmemesini bir arıza
    // sanır. Kayıtlı değer korunuyor: ayar kapatılınca anahtar eski
    // hâliyle geri geliyor.
    final tracksFertility = context.select<CalendarViewModel, bool>(
      (vm) => vm.cycleInfo.fertilityTracked,
    );

    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(
        title: Text(
          context.tr('notif_general_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.tokens.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.tokens.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.tokens.text,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppContentWidth(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          context.tr('notif_period_reminders'),
                          _settings.periodReminders,
                          (val) =>
                              _update(_settings.copyWith(periodReminders: val)),
                          Icons.water_drop_outlined,
                          true,
                        ),
                        if (tracksFertility)
                          _buildSwitchTile(
                            context.tr('notif_fertile_window'),
                            _settings.fertileWindow,
                            (val) =>
                                _update(_settings.copyWith(fertileWindow: val)),
                            Icons.child_care,
                            true,
                          ),
                        _buildSwitchTile(
                          context.tr('notif_daily_logs'),
                          _settings.dailyLogs,
                          (val) => _update(_settings.copyWith(dailyLogs: val)),
                          Icons.edit_note,
                          false,
                        ),
                      ],
                    ),
                  ),
                  if (_permissionBlocked) _buildPermissionNotice(),
                ],
              ),
      ),
    );
  }

  /// İzin alınamadığında anahtarların altında kalan açıklama.
  Widget _buildPermissionNotice() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 18,
            color: context.tokens.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('notif_permission_denied'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: context.tokens.textMuted,
                  ),
                ),
                // iOS sistem istemini ikinci kez göstermiyor; tarif etmek
                // yerine kullanıcıyı oraya götürüyoruz.
                if (AppSettingsLink.isSupported)
                  TextButton(
                    onPressed: AppSettingsLink.open,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 44),
                      visualDensity: VisualDensity.standard,
                    ),
                    child: Text(
                      context.tr('open_settings'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    bool hasBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(bottom: BorderSide(color: context.tokens.border))
            : null,
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(icon, size: 20, color: context.tokens.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.tokens.text,
                ),
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
