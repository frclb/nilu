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
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/app_layout.dart';
import 'widgets/settings_surface.dart';

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
    final t = context.tokens;
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

    // Her hatırlatıcı bir blok: anahtar ve (açıksa) ona bağlı ayrıntı.
    final bloklar = <List<Widget>>[
      [
        _buildSwitchTile(
          context.tr('notif_period_reminders'),
          _settings.periodReminders,
          (val) => _update(_settings.copyWith(periodReminders: val)),
          Icons.water_drop_outlined,
        ),
        if (_settings.periodReminders)
          _buildValueTile(
            key: const Key('notif_lead_days'),
            title: context.tr('notif_lead_days'),
            value: _leadLabel(_settings.periodLeadDays),
            onTap: _pickLeadDays,
          ),
      ],
      [
        _buildSwitchTile(
          context.tr('notif_late_setting'),
          _settings.lateReminder,
          (val) => _update(_settings.copyWith(lateReminder: val)),
          Icons.hourglass_bottom_outlined,
          subtitle: context.tr(
            'notif_late_setting_body',
            params: {'n': '${ReminderPlanner.lateAfterDays}'},
          ),
          key: const Key('notif_late_switch'),
        ),
      ],
      if (tracksFertility)
        [
          _buildSwitchTile(
            context.tr('notif_fertile_window'),
            _settings.fertileWindow,
            (val) => _update(_settings.copyWith(fertileWindow: val)),
            Icons.flare_rounded,
          ),
        ],
      [
        _buildSwitchTile(
          context.tr('notif_daily_logs'),
          _settings.dailyLogs,
          (val) => _update(_settings.copyWith(dailyLogs: val)),
          Icons.edit_note,
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
      ],
      // Gebelik ve lohusalık izlemleri, taramalar, destekler ve gebelik
      // planlama (folik asit, hekime başvuru).
      [
        _buildSwitchTile(
          context.tr('notif_care_setting'),
          _settings.careReminders,
          (val) => _update(_settings.copyWith(careReminders: val)),
          Icons.volunteer_activism_outlined,
        ),
      ],
    ];

    return Scaffold(
      appBar: SettingsAppBar(
        title: context.tr('notif_general_title'),
        onBack: () => context.pop(),
      ),
      body: AppContentWidth(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (_permissionBlocked) _buildPermissionNotice(),
                  SettingsCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < bloklar.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 9,
                              thickness: 1,
                              indent: 16,
                              endIndent: 16,
                              color: AppCard.dividerColor(t),
                            ),
                          ...bloklar[i],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Saat ayrı kartta: tek bir türün değil, gün içindeki
                  // bütün hatırlatıcıların saati.
                  SettingsCard(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          key: const Key('notif_reminder_time'),
                          contentPadding: EdgeInsets.zero,
                          onTap: () => _pickTime(
                            _settings.reminderMinuteOfDay,
                            (m) => _settings.copyWith(reminderMinuteOfDay: m),
                          ),
                          leading: _tile(Icons.schedule_rounded),
                          title: Text(
                            context.tr('notif_reminder_time'),
                            style: SettingsText.title(context),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.fromLTRB(14, 7, 8, 7),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _timeLabel(_settings.reminderMinuteOfDay),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: t.brandTint,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            context.tr('notif_reminder_time_body'),
                            style: SettingsText.subtitle(
                              context,
                            )?.copyWith(fontSize: 13.5, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Gizlilik ayrı kartta: bir hatırlatıcı türü değil, hepsinin
                  // nasıl görüneceği.
                  SettingsCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          key: const Key('notif_discreet_switch'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          secondary: _tile(Icons.lock_outline_rounded),
                          title: Text(
                            context.tr('notif_discreet_setting'),
                            style: SettingsText.title(context),
                          ),
                          subtitle: Text(
                            context.tr('notif_discreet_setting_body'),
                            style: SettingsText.subtitle(context),
                          ),
                          value: _settings.discreet,
                          onChanged: (val) =>
                              _update(_settings.copyWith(discreet: val)),
                        ),
                        if (_settings.discreet)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: _DiscreetPreview(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Satır başındaki yuvarlak simge kutusu.
  Widget _tile(IconData icon) => AppIconTile(
    icon: icon,
    circle: true,
    background: context.tokens.brandTint,
  );

  /// İzin yokken anahtarların üstünde duran açıklama.
  Widget _buildPermissionNotice() {
    final t = context.tokens;
    return Container(
      key: const Key('notif_permission_notice'),
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: t.secondaryTint,
        borderRadius: BorderRadius.circular(AppRadius.lg - 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: Icons.notifications_off_outlined,
            size: 36,
            circle: true,
            background: t.surface,
            color: t.secondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.tr('notif_permission_off'),
                    style: SettingsText.subtitle(
                      context,
                      color: t.text,
                    )?.copyWith(fontSize: 13.5, height: 1.45),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: t.secondary,
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
  ///
  /// Üstteki anahtarın simge sütunundan içeride, tül zeminli bir kutu:
  /// neye ait olduğu görünsün.
  Widget _buildValueTile({
    required Key key,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(68, 0, 16, 8),
      child: ListTile(
        key: key,
        onTap: onTap,
        tileColor: t.brandTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(
          title,
          style: SettingsText.subtitle(context)?.copyWith(fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon, {
    String? subtitle,
    Key? key,
  }) {
    return SwitchListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: _tile(icon),
      title: Text(title, style: SettingsText.title(context)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, style: SettingsText.subtitle(context)),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Gizli bildirimin kilit ekranında nasıl göründüğü: başlık ve gövde,
/// planlayıcının gizli bildirimde kullandığı metinlerin aynısı.
class _DiscreetPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    // Açıklama zaten alt satırda yazıyor; VoiceOver aynı cümleyi iki kez
    // okumasın.
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: t.brandTint,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: AppShadows.soft(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogoMark(size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('notif_discreet_title'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('notif_discreet_body'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: t.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
