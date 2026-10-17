import '../reminders/care_plan_loader.dart';
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
  const NotificationSettingsScreen({
    super.key,
    @visibleForTesting this.scheduler,
  });

  /// Testte izin durumunu taklit eden zamanlayıcı.
  final ReminderScheduler? scheduler;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  final NotificationSettingsRepository _repository =
      NotificationSettingsRepository();
  late final ReminderScheduler _scheduler =
      widget.scheduler ?? ReminderScheduler();

  GeneralNotificationSettings _settings = const GeneralNotificationSettings();
  bool _isLoading = true;

  /// Açık görünen hatırlatıcılar bildirim izni olmadığı için gelmiyor mu?
  ///
  /// Varsayılan olarak regl ve doğurganlık hatırlatıcıları açık. İzni
  /// vermemiş (ya da "Şimdi değil" demiş) kullanıcı bu ekranda anahtarları
  /// açık görüyor, hatırlatıcıların kurulduğunu sanıyordu; uyarı ancak bir
  /// anahtara dokununca çıkıyordu. Artık ekran açılırken izne bakılıyor.
  ///
  /// Snackbar değil: sebep, izin verilene kadar ekranda kalmalı.
  bool _permissionBlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Ayarlar'dan izin verip dönen kullanıcı için: uyarı kalkıyor ve
  /// hatırlatıcılar hemen kuruluyor.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_permissionBlocked) return;
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (!await _scheduler.isPermissionGranted() || !mounted) return;
    await _reschedule(_settings, askPermission: false);
  }

  Future<void> _load() async {
    final settings = await _repository.getGeneralSettings();
    final granted = await _scheduler.isPermissionGranted();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _isLoading = false;
      _permissionBlocked = !granted && _anyReminderOn(settings);
    });
  }

  /// Bildirim gerektiren bir hatırlatıcı açık mı? Gizli bildirim bir
  /// hatırlatıcı değil, hepsinin görünüşü.
  bool _anyReminderOn(GeneralNotificationSettings s) =>
      s.periodReminders ||
      s.fertileWindow ||
      s.dailyLogs ||
      s.careReminders ||
      s.lateReminder;

  /// [next] bir hatırlatıcıyı açıyor mu? İzin yalnızca o zaman isteniyor:
  /// kapatmak için izin gerekmez. Önceden izin yokken bir anahtarı
  /// **kapatmak** da izin istiyor, alınamayınca anahtar yeniden açılıyordu.
  bool _turnsOn(
    GeneralNotificationSettings previous,
    GeneralNotificationSettings next,
  ) =>
      (!previous.periodReminders && next.periodReminders) ||
      (!previous.fertileWindow && next.fertileWindow) ||
      (!previous.dailyLogs && next.dailyLogs) ||
      (!previous.careReminders && next.careReminders) ||
      (!previous.lateReminder && next.lateReminder);

  /// Uyarıdaki düğme: izni ister; iOS istemi bir kez gösterdiği için
  /// alınamazsa uygulamanın Ayarlar sayfasını açar.
  Future<void> _askPermission() async {
    bool granted;
    try {
      granted = await _scheduler.requestPermission();
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      granted = false;
    }
    if (!mounted) return;
    if (granted) {
      await _reschedule(_settings, askPermission: false);
    } else if (AppSettingsLink.isSupported) {
      await AppSettingsLink.open();
    }
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

    final applied = await _reschedule(
      next,
      askPermission: _turnsOn(previous, next),
    );
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
  Future<bool> _reschedule(
    GeneralNotificationSettings settings, {
    required bool askPermission,
  }) async {
    try {
      return await _applyPlan(settings, askPermission: askPermission);
    } catch (e) {
      debugPrint('Reminder scheduling failed: $e');
      if (mounted) setState(() => _permissionBlocked = true);
      return false;
    }
  }

  Future<bool> _applyPlan(
    GeneralNotificationSettings settings, {
    required bool askPermission,
  }) async {
    final cycleInfo = context.read<CalendarViewModel>().cycleInfo;
    final localize = context.tr;

    final scheduler = _scheduler;

    // Gebelik/lohusalık hatırlatıcıları da plana giriyor. `apply` önce
    // hepsini iptal ediyor; bu girdi olmasaydı bir döngü anahtarını
    // değiştirmek bütün gebelik hatırlatıcılarını silerdi.
    final care = await loadCarePlanInput();

    // Kullanıcı ilk kez bir hatırlatıcı açtığında izin iste.
    final wantsReminders =
        settings.periodReminders ||
        settings.fertileWindow ||
        settings.dailyLogs ||
        settings.lateReminder ||
        // Gebelik planlama hatırlatıcıları da bu anahtarda ve bakım
        // kalemine bağlı değil: yalnızca kalemlere bakılsaydı planlama
        // yapan kullanıcıdan izin hiç istenmez, folik asit hatırlatması
        // sessizce kurulamazdı.
        (settings.careReminders &&
            (care.events.isNotEmpty || care.conception != null));
    if (wantsReminders && !await scheduler.isPermissionGranted()) {
      if (!askPermission) {
        // Kapatma ya da gizli bildirim: ayar kaydediliyor, uyarı duruyor.
        // Plan kurulmuyor — izin verilince kurulacak.
        if (mounted) setState(() => _permissionBlocked = true);
        return true;
      }
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
      care: care,
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
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
                  if (_permissionBlocked) _buildPermissionNotice(),
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
                        if (_settings.periodReminders)
                          _buildValueTile(
                            key: const Key('notif_lead_days'),
                            title: context.tr('notif_lead_days'),
                            value: _leadLabel(_settings.periodLeadDays),
                            onTap: _pickLeadDays,
                          ),
                        _buildSwitchTile(
                          context.tr('notif_late_setting'),
                          _settings.lateReminder,
                          (val) =>
                              _update(_settings.copyWith(lateReminder: val)),
                          Icons.hourglass_bottom_outlined,
                          true,
                          subtitle: context.tr(
                            'notif_late_setting_body',
                            params: {'n': '${ReminderPlanner.lateAfterDays}'},
                          ),
                          key: const Key('notif_late_switch'),
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
                          true,
                        ),
                        if (_settings.dailyLogs)
                          _buildValueTile(
                            key: const Key('notif_daily_log_time'),
                            title: context.tr('notif_daily_log_time'),
                            value: _timeLabel(_settings.dailyLogMinuteOfDay),
                            onTap: () => _pickTime(
                              _settings.dailyLogMinuteOfDay,
                              (m) => _settings.copyWith(dailyLogMinuteOfDay: m),
                            ),
                          ),
                        // Gebelik ve lohusalık izlemleri, taramalar, destekler
                        // ve gebelik planlama (folik asit, hekime başvuru).
                        _buildSwitchTile(
                          context.tr('notif_care_setting'),
                          _settings.careReminders,
                          (val) =>
                              _update(_settings.copyWith(careReminders: val)),
                          Icons.event_note_outlined,
                          false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Saat ayrı kartta: tek bir türün değil, gün içindeki
                  // bütün hatırlatıcıların saati.
                  Container(
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: _buildValueTile(
                      key: const Key('notif_reminder_time'),
                      title: context.tr('notif_reminder_time'),
                      subtitle: context.tr('notif_reminder_time_body'),
                      value: _timeLabel(_settings.reminderMinuteOfDay),
                      icon: Icons.schedule,
                      hasBorder: false,
                      onTap: () => _pickTime(
                        _settings.reminderMinuteOfDay,
                        (m) => _settings.copyWith(reminderMinuteOfDay: m),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gizlilik ayrı kartta: bir hatırlatıcı türü değil, hepsinin
                  // nasıl görüneceği.
                  Container(
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: SwitchListTile(
                      key: const Key('notif_discreet_switch'),
                      secondary: Icon(
                        Icons.visibility_off_outlined,
                        color: context.tokens.textMuted,
                      ),
                      title: Text(
                        context.tr('notif_discreet_setting'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.tokens.text,
                        ),
                      ),
                      subtitle: Text(
                        context.tr('notif_discreet_setting_body'),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: context.tokens.textMuted,
                        ),
                      ),
                      value: _settings.discreet,
                      onChanged: (val) =>
                          _update(_settings.copyWith(discreet: val)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// İzin yokken anahtarların üstünde duran açıklama.
  Widget _buildPermissionNotice() {
    return Container(
      key: const Key('notif_permission_notice'),
      margin: const EdgeInsets.only(bottom: 16),
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
                  context.tr('notif_permission_off'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: context.tokens.textMuted,
                  ),
                ),
                // iOS sistem istemini ikinci kez göstermiyor; o zaman düğme
                // kullanıcıyı Ayarlar'a götürüyor (bkz. [_askPermission]).
                TextButton(
                  key: const Key('notif_permission_allow'),
                  onPressed: _askPermission,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 44),
                    visualDensity: VisualDensity.standard,
                  ),
                  child: Text(
                    context.tr('notif_permission_allow'),
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

  String _leadLabel(int days) => days == 1
      ? context.tr('notif_lead_one')
      : context.tr('notif_lead_many', params: {'n': '$days'});

  /// Cihazın 12/24 saat tercihine göre.
  String _timeLabel(int minuteOfDay) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  Future<void> _pickLeadDays() async {
    final secilen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.tokens.surface,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (
                var d = GeneralNotificationSettings.minPeriodLeadDays;
                d <= GeneralNotificationSettings.maxPeriodLeadDays;
                d++
              )
                ListTile(
                  key: Key('notif_lead_option_$d'),
                  title: Text(_leadLabel(d)),
                  trailing: d == _settings.periodLeadDays
                      ? Icon(
                          Icons.check,
                          color: Theme.of(ctx).colorScheme.primary,
                        )
                      : null,
                  selected: d == _settings.periodLeadDays,
                  onTap: () => Navigator.of(ctx).pop(d),
                ),
            ],
          ),
        ),
      ),
    );
    if (secilen == null || secilen == _settings.periodLeadDays || !mounted) {
      return;
    }
    await _update(_settings.copyWith(periodLeadDays: secilen));
  }

  Future<void> _pickTime(
    int current,
    GeneralNotificationSettings Function(int minuteOfDay) apply,
  ) async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (secilen == null || !mounted) return;
    final dakika = secilen.hour * 60 + secilen.minute;
    if (dakika == current) return;
    await _update(apply(dakika));
  }

  /// Bir hatırlatıcının ayrıntısı: dokununca seçim açılır.
  Widget _buildValueTile({
    required Key key,
    required String title,
    required String value,
    required VoidCallback onTap,
    String? subtitle,
    IconData? icon,
    bool hasBorder = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(bottom: BorderSide(color: context.tokens.border))
            : null,
      ),
      child: ListTile(
        key: key,
        onTap: onTap,
        // Simgesiz satır üstteki anahtarın altına girintili: neye ait
        // olduğu görünsün.
        contentPadding: EdgeInsets.only(
          left: icon == null ? 48 : 16,
          right: 16,
        ),
        leading: icon == null
            ? null
            : Icon(icon, size: 20, color: context.tokens.textMuted),
        title: Text(
          title,
          style: TextStyle(fontSize: 15, color: context.tokens.text),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: context.tokens.textMuted,
                ),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: context.tokens.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
    bool hasBorder, {
    String? subtitle,
    Key? key,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(bottom: BorderSide(color: context.tokens.border))
            : null,
      ),
      child: SwitchListTile(
        key: key,
        subtitle: subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: context.tokens.textMuted,
                  ),
                ),
              ),
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
