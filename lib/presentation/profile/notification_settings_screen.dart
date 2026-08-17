import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../domain/models/notification_settings.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';

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

  /// Her değişiklik anında kalıcılaştırılır — bu ekranda ayrı bir "Kaydet"
  /// düğmesi yok.
  Future<void> _update(GeneralNotificationSettings next) async {
    setState(() => _settings = next);
    await _repository.saveGeneralSettings(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundNavyDark
          : AppColors.backgroundLightAlt,
      appBar: AppBar(
        title: Text(
          context.tr('notif_general_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundNavyDark
            : AppColors.backgroundLightAlt,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceNavyDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.blueGrey[800]!.withAlpha(127)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        context.tr('notif_period_reminders'),
                        _settings.periodReminders,
                        (val) =>
                            _update(_settings.copyWith(periodReminders: val)),
                        isDark,
                        Icons.water_drop_outlined,
                        true,
                      ),
                      _buildSwitchTile(
                        context.tr('notif_fertile_window'),
                        _settings.fertileWindow,
                        (val) =>
                            _update(_settings.copyWith(fertileWindow: val)),
                        isDark,
                        Icons.child_care,
                        true,
                      ),
                      _buildSwitchTile(
                        context.tr('notif_daily_logs'),
                        _settings.dailyLogs,
                        (val) => _update(_settings.copyWith(dailyLogs: val)),
                        isDark,
                        Icons.edit_note,
                        true,
                      ),
                      _buildSwitchTile(
                        context.tr('notif_partner_updates'),
                        _settings.partnerUpdates,
                        (val) =>
                            _update(_settings.copyWith(partnerUpdates: val)),
                        isDark,
                        Icons.group_outlined,
                        false,
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
    bool isDark,
    IconData icon,
    bool hasBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.blueGrey[800]!.withAlpha(127)
                      : Colors.grey[200]!,
                ),
              )
            : null,
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accentAmber,
        activeTrackColor: AppColors.accentAmber.withAlpha(127),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: isDark ? Colors.blueGrey[700] : Colors.grey[300],
      ),
    );
  }
}
