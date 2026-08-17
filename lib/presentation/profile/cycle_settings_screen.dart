import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/cycle_settings_repository.dart';
import '../../presentation/calendar/view_models/calendar_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';

class CycleSettingsScreen extends StatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  State<CycleSettingsScreen> createState() => _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends State<CycleSettingsScreen> {
  final CycleSettingsRepository _settingsRepo = CycleSettingsRepository();
  int _cycleLength = 28;
  int _periodLength = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cycleLength = await _settingsRepo.getCycleLength();
    final periodLength = await _settingsRepo.getPeriodLength();
    setState(() {
      _cycleLength = cycleLength;
      _periodLength = periodLength;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    // Ayarları kaydet (settings_updated_at otomatik güncellenir)
    await _settingsRepo.saveCycleSettings(
      cycleLength: _cycleLength,
      periodLength: _periodLength,
    );

    // CalendarViewModel'i yenile — yeni ayarlar yalnızca ileriye dönük uygulanır
    if (mounted) {
      context.read<CalendarViewModel>().refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cycle_settings_saved'))),
      );
      context.pop();
    }
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
          context.tr('cycle_settings_title'),
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
                _buildSliderSetting(
                  context,
                  context.tr('cycle_settings_length'),
                  '$_cycleLength Gün',
                  _cycleLength.toDouble(),
                  min: 21,
                  max: 35,
                  onChanged: (val) {
                    setState(() {
                      _cycleLength = val.toInt();
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildSliderSetting(
                  context,
                  context.tr('cycle_settings_period'),
                  '$_periodLength Gün',
                  _periodLength.toDouble(),
                  min: 2,
                  max: 10,
                  onChanged: (val) {
                    setState(() {
                      _periodLength = val.toInt();
                    });
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // Bilgi notu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withAlpha(12)
                        : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha(25)
                          : AppColors.accentRose.withAlpha(38),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: isDark ? Colors.grey[400] : AppColors.accentRose,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('cycle_settings_note'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRose,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr('save'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliderSetting(
    BuildContext context,
    String title,
    String valueText,
    double value, {
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.accentRose,
            inactiveColor: isDark ? Colors.blueGrey[800] : Colors.grey[300],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
