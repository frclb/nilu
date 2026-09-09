import 'package:flutter/material.dart';
import '../../design_system/app_palette.dart';
import '../../design_system/app_snack.dart';
import 'package:provider/provider.dart';
import 'widgets/log_entry_app_bar.dart';
import 'widgets/log_entry_header.dart';
import 'widgets/flow_intensity_section.dart';
import 'widgets/symptoms_section.dart';
import 'widgets/mood_section.dart';
import 'widgets/notes_section.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../domain/models/daily_log.dart';
import '../calendar/view_models/calendar_view_model.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final TextEditingController _notesController = TextEditingController();

  String? _flowIntensity;
  List<String> _symptoms = [];
  List<String> _moods = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    final viewModel = context.read<CalendarViewModel>();
    final today = DateTime.now();

    final log = DailyLog(
      date: today,
      flowIntensity: _flowIntensity,
      symptoms: _symptoms,
      moods: _moods,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    await viewModel.updateDailyLog(log);

    // Akış yoğunluğu girildiyse kanama var demektir: dönemi başlat. Tek
    // günlük kapalı bir kayıt açsaydık ertesi gün ana ekran yine "Reglim
    // başladı" derdi.
    if (_flowIntensity != null && !viewModel.isPeriodDay(today)) {
      await viewModel.startPeriodToday();
    }

    if (mounted) {
      AppSnack.show(context, context.tr('home_log_saved'));
      NavigationService().pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const LogEntryAppBar(),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LogEntryHeader(),
                FlowIntensitySection(
                  initialValue: _flowIntensity,
                  onChanged: (value) {
                    _flowIntensity = value;
                  },
                ),
                _buildDivider(isDark, theme),
                SymptomsSection(
                  initialSymptoms: _symptoms,
                  onChanged: (value) {
                    _symptoms = value;
                  },
                ),
                _buildDivider(isDark, theme),
                MoodSection(
                  initialMoods: _moods,
                  onChanged: (value) {
                    _moods = value;
                  },
                ),
                _buildDivider(isDark, theme),
                NotesSection(controller: _notesController),
              ],
            ),
          ),

          // Fixed Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppPalette.night800.withAlpha(229)
                    : Colors.white.withAlpha(204),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withAlpha(12)
                        : theme.colorScheme.primary.withAlpha(12),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: theme.colorScheme.primary.withAlpha(102),
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  label: Text(
                    context.tr('log_save_button'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Divider(
        color: isDark
            ? Colors.white.withAlpha(25)
            : theme.colorScheme.primary.withAlpha(25),
        height: 1,
      ),
    );
  }
}
