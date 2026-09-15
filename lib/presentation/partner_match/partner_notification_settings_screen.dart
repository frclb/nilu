import 'package:flutter/material.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/notification_settings_repository.dart';
import '../../domain/models/notification_settings.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

class PartnerNotificationSettingsScreen extends StatefulWidget {
  const PartnerNotificationSettingsScreen({super.key});

  @override
  State<PartnerNotificationSettingsScreen> createState() =>
      _PartnerNotificationSettingsScreenState();
}

class _PartnerNotificationSettingsScreenState
    extends State<PartnerNotificationSettingsScreen> {
  final NotificationSettingsRepository _repository =
      NotificationSettingsRepository();

  // Toggle states based on HTML design
  bool _periodStartEnabled = true;
  bool _ovulationEnabled = false;
  bool _symptomsEnabled = true;
  bool _dailySupportEnabled = true;

  // Dropdown states. Değerler dilden bağımsız kodlardır (görünen metin
  // lokalizasyondan gelir) — kalıcı hâle geldikleri için sabit kalmalıdır.
  String _periodStartValue = '1';
  String _ovulationValue = '0';
  String _symptomsValue = '1';
  String _dailySupportValue = '0900';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repository.getPartnerSettings();
    if (!mounted) return;
    setState(() {
      _periodStartEnabled = s.periodStartEnabled;
      _ovulationEnabled = s.ovulationEnabled;
      _symptomsEnabled = s.symptomsEnabled;
      _dailySupportEnabled = s.dailySupportEnabled;
      _periodStartValue = s.periodStartValue;
      _ovulationValue = s.ovulationValue;
      _symptomsValue = s.symptomsValue;
      _dailySupportValue = s.dailySupportValue;
    });
  }

  Future<void> _save() {
    return _repository.savePartnerSettings(
      PartnerNotificationSettings(
        periodStartEnabled: _periodStartEnabled,
        ovulationEnabled: _ovulationEnabled,
        symptomsEnabled: _symptomsEnabled,
        dailySupportEnabled: _dailySupportEnabled,
        periodStartValue: _periodStartValue,
        ovulationValue: _ovulationValue,
        symptomsValue: _symptomsValue,
        dailySupportValue: _dailySupportValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Base colors matching the HTML design
    // Dark: bg #1E1415, Light: bg #F8F6F6
    final bgColor = context.tokens.background;
    final primaryColor = Theme.of(
      context,
    ).colorScheme.primary; // Primary color from design
    final textMainColor = context.tokens.text;
    final textMutedColor = context.tokens.textMuted;

    // Card colors
    final cardBgColor = isDark
        ? primaryColor.withValues(alpha: 0.1)
        : primaryColor.withValues(alpha: 0.05);
    final borderColor = primaryColor.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textMainColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('partner_notif_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: textMainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: primaryColor.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, primaryColor, textMutedColor),
                      const SizedBox(height: 24),
                      _buildReminderItem(
                        context,
                        icon: Icons.water_drop_outlined,
                        title: context.tr('partner_notif_period_start'),
                        subtitle: context.tr('partner_notif_period_start_desc'),
                        dropdownLabel: context.tr(
                          'partner_notif_how_long_before',
                        ),
                        switchValue: _periodStartEnabled,
                        onSwitchChanged: (val) =>
                            setState(() => _periodStartEnabled = val),
                        dropdownValue: _periodStartValue,
                        dropdownItems: [
                          DropdownMenuItem(
                            value: '1',
                            child: Text(
                              context.tr('partner_notif_1_day_before'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text(
                              context.tr('partner_notif_2_days_before'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '3',
                            child: Text(
                              context.tr('partner_notif_3_days_before'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '7',
                            child: Text(
                              context.tr('partner_notif_1_week_before'),
                            ),
                          ),
                        ],
                        onDropdownChanged: (val) =>
                            setState(() => _periodStartValue = val!),
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        primaryColor: primaryColor,
                        textMainColor: textMainColor,
                        textMutedColor: textMutedColor,
                        bgColor: bgColor,
                      ),
                      const SizedBox(height: 24),
                      _buildReminderItem(
                        context,
                        icon: Icons
                            .local_florist_outlined, // Flower icon approximation
                        title: context.tr('partner_notif_ovulation'),
                        subtitle: context.tr('partner_notif_ovulation_desc'),
                        dropdownLabel: context.tr(
                          'partner_notif_how_long_before',
                        ),
                        switchValue: _ovulationEnabled,
                        onSwitchChanged: (val) =>
                            setState(() => _ovulationEnabled = val),
                        dropdownValue: _ovulationValue,
                        dropdownItems: [
                          DropdownMenuItem(
                            value: '0',
                            child: Text(context.tr('partner_notif_same_day')),
                          ),
                          DropdownMenuItem(
                            value: '1',
                            child: Text(
                              context.tr('partner_notif_1_day_before'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text(
                              context.tr('partner_notif_2_days_before'),
                            ),
                          ),
                        ],
                        onDropdownChanged: (val) =>
                            setState(() => _ovulationValue = val!),
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        primaryColor: primaryColor,
                        textMainColor: textMainColor,
                        textMutedColor: textMutedColor,
                        bgColor: bgColor,
                      ),
                      const SizedBox(height: 24),
                      _buildReminderItem(
                        context,
                        icon: Icons.favorite_border,
                        title: context.tr('partner_notif_symptoms'),
                        subtitle: context.tr('partner_notif_symptoms_desc'),
                        dropdownLabel: context.tr('partner_notif_frequency'),
                        switchValue: _symptomsEnabled,
                        onSwitchChanged: (val) =>
                            setState(() => _symptomsEnabled = val),
                        dropdownValue: _symptomsValue,
                        dropdownItems: [
                          DropdownMenuItem(
                            value: '1',
                            child: Text(context.tr('partner_notif_instantly')),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text(
                              context.tr('partner_notif_daily_summary'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: '3',
                            child: Text(
                              context.tr('partner_notif_weekly_summary'),
                            ),
                          ),
                        ],
                        onDropdownChanged: (val) =>
                            setState(() => _symptomsValue = val!),
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        primaryColor: primaryColor,
                        textMainColor: textMainColor,
                        textMutedColor: textMutedColor,
                        bgColor: bgColor,
                      ),
                      const SizedBox(height: 24),
                      _buildReminderItem(
                        context,
                        icon: Icons.lightbulb_outline,
                        title: context.tr('partner_notif_daily_support'),
                        subtitle: context.tr(
                          'partner_notif_daily_support_desc',
                        ),
                        dropdownLabel: context.tr(
                          'partner_notif_reminder_time',
                        ),
                        switchValue: _dailySupportEnabled,
                        onSwitchChanged: (val) =>
                            setState(() => _dailySupportEnabled = val),
                        dropdownValue: _dailySupportValue,
                        dropdownItems: [
                          DropdownMenuItem(
                            value: '0900',
                            child: Text(context.tr('partner_notif_morning')),
                          ),
                          DropdownMenuItem(
                            value: '1200',
                            child: Text(context.tr('partner_notif_noon')),
                          ),
                          DropdownMenuItem(
                            value: '1900',
                            child: Text(context.tr('partner_notif_evening')),
                          ),
                        ],
                        onDropdownChanged: (val) =>
                            setState(() => _dailySupportValue = val!),
                        cardBgColor: cardBgColor,
                        borderColor: borderColor,
                        primaryColor: primaryColor,
                        textMainColor: textMainColor,
                        textMutedColor: textMutedColor,
                        bgColor: bgColor,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(context, primaryColor, bgColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color primaryColor,
    Color? textMutedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('partner_notif_header'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('partner_notif_header_desc'),
          style: TextStyle(fontSize: 14, color: textMutedColor),
        ),
      ],
    );
  }

  Widget _buildReminderItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String dropdownLabel,
    required bool switchValue,
    required ValueChanged<bool> onSwitchChanged,
    required String dropdownValue,
    required List<DropdownMenuItem<String>> dropdownItems,
    required ValueChanged<String?> onDropdownChanged,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textMainColor,
    required Color? textMutedColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Icon(icon, color: primaryColor, size: 24),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textMainColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: textMutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeThumbColor: context.tokens.surface,
                activeTrackColor: primaryColor,
                inactiveThumbColor: context.tokens.surface,
                inactiveTrackColor: context.tokens.border,
                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => Colors.transparent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            dropdownLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              color: textMutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: dropdownValue,
                isExpanded: true,
                icon: Icon(Icons.unfold_more, color: textMutedColor, size: 20),
                dropdownColor: bgColor,
                style: TextStyle(
                  fontSize: 14,
                  color: textMainColor,
                  fontFamily: 'Inter',
                ),
                items: dropdownItems,
                onChanged: onDropdownChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    Color primaryColor,
    Color bgColor,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: primaryColor.withValues(alpha: 0.1)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            // context'e bağlı her şey await ve pop'tan ÖNCE okunur.
            final messenger = ScaffoldMessenger.of(context);
            final screenHeight = MediaQuery.of(context).size.height;
            final router = GoRouter.of(context);
            final savedMessage = context.tr('partner_notif_saved');

            await _save();

            router.pop(); // Return to previous screen

            messenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppSnack.foreground,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      savedMessage,
                      style: const TextStyle(
                        color: AppSnack.foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                backgroundColor: primaryColor,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: screenHeight - 160,
                  left: 16,
                  right: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 8,
            shadowColor: primaryColor.withValues(alpha: 0.2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            context.tr('partner_notif_save'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
