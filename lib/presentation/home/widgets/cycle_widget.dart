import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../domain/models/cycle_info.dart';
import '../../calendar/view_models/calendar_view_model.dart';
import '../../../design_system/app_colors.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';

class CycleWidget extends StatelessWidget {
  const CycleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final viewModel = context.watch<CalendarViewModel>();
    final cycleInfo = viewModel.cycleInfo;

    final cycleDay = cycleInfo.currentCycleDay;
    final progress = cycleInfo.cycleProgress;
    final phase = cycleInfo.currentPhase;
    final daysUntil = cycleInfo.daysUntilNextPeriod;

    final phaseLabel = _getPhaseLabel(context, phase);
    final phaseIcon = _getPhaseIcon(phase);
    final fertilityInfo = _getFertilityInfo(context, phase);

    return GestureDetector(
      onTap: () {
        NavigationService().push(RouteNames.calendar);
      },
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer decorative rings
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: secondaryColor.withAlpha(76),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 256,
                  height: 256,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: secondaryColor.withAlpha(127),
                      width: 1.5,
                    ),
                  ),
                ),

                // Progress Ring
                SizedBox(
                  width: 212,
                  height: 212,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: theme.brightness == Brightness.dark
                        ? AppColors.surfaceDark
                        : secondaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      phase.color(context.tokens),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),

                // Center Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(phaseIcon, color: primaryColor, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('home_cycle_day_title').toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      cycleDay?.toString() ?? '-',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        phaseLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Cycle Status Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  daysUntil != null
                      ? context.tr(
                          'home_days_until_period',
                          params: {'days': daysUntil.toString()},
                        )
                      : context.tr('home_no_data_yet'),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: fertilityInfo.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                fertilityInfo.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPhaseLabel(BuildContext context, CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstruation:
        return context.tr('home_menstruation_phase');
      case CyclePhase.follicular:
        return context.tr('home_follicular_phase');
      case CyclePhase.ovulation:
        return context.tr('home_ovulation_phase');
      case CyclePhase.luteal:
        return context.tr('home_luteal_phase');
      case CyclePhase.unknown:
        return context.tr('home_no_data_yet');
    }
  }

  IconData _getPhaseIcon(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstruation:
        return Icons.water_drop;
      case CyclePhase.follicular:
        return Icons.local_florist;
      case CyclePhase.ovulation:
        return Icons.sunny;
      case CyclePhase.luteal:
        return Icons.nights_stay;
      case CyclePhase.unknown:
        return Icons.water_drop_outlined;
    }
  }

  _FertilityInfo _getFertilityInfo(BuildContext context, CyclePhase phase) {
    final color = phase.fertilityColor(context.tokens);
    return switch (phase) {
      CyclePhase.ovulation => _FertilityInfo(
        color: color,
        label: context.tr('home_very_high_fertility'),
      ),
      CyclePhase.follicular => _FertilityInfo(
        color: color,
        label: context.tr('home_medium_fertility'),
      ),
      CyclePhase.luteal || CyclePhase.menstruation => _FertilityInfo(
        color: color,
        label: context.tr('home_low_fertility'),
      ),
      CyclePhase.unknown => _FertilityInfo(
        color: color,
        label: context.tr('home_no_data_yet'),
      ),
    };
  }
}

class _FertilityInfo {
  final Color color;
  final String label;
  _FertilityInfo({required this.color, required this.label});
}
