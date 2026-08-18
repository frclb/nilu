import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../domain/models/cycle_info.dart';
import '../../calendar/view_models/calendar_view_model.dart';

class DailySuggestionCard extends StatelessWidget {
  const DailySuggestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();
    final phase = viewModel.cycleInfo.currentPhase;
    final suggestion = _getSuggestionForPhase(context, phase);
    final phaseColor = phase.color(context.tokens);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.tr('home_daily_suggestion_title'),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  NavigationService().push(RouteNames.healthLibrary);
                },
                child: Text(
                  context.tr('home_see_all'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Faz renginde gradient banner.
                //
                // Renk artık fazdan türetiliyor; öncesinde her öneri kendi
                // sabit rengini taşıyordu (yumurtlama önerisi açık maviydi)
                // ve kart paletin dışına düşüyordu.
                Container(
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        phaseColor.withAlpha(64),
                        phaseColor.withAlpha(18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(suggestion.icon, size: 40, color: phaseColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.title,
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  153,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                suggestion.duration,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        suggestion.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            NavigationService().push(RouteNames.yogaDetail);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            context.tr('home_start_button'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _PhaseSuggestion _getSuggestionForPhase(
    BuildContext context,
    CyclePhase phase,
  ) {
    switch (phase) {
      case CyclePhase.menstruation:
        return _PhaseSuggestion(
          title: context.tr('suggestion_yin_yoga_title'),
          description: context.tr('suggestion_yin_yoga_desc'),
          duration: context.tr('duration_minutes', params: {'n': '15'}),
          icon: Icons.self_improvement,
        );
      case CyclePhase.follicular:
        return _PhaseSuggestion(
          title: context.tr('suggestion_energy_title'),
          description: context.tr('suggestion_energy_desc'),
          duration: context.tr('duration_minutes', params: {'n': '25'}),
          icon: Icons.fitness_center,
        );
      case CyclePhase.ovulation:
        return _PhaseSuggestion(
          title: context.tr('suggestion_hiit_title'),
          description: context.tr('suggestion_hiit_desc'),
          duration: context.tr('duration_minutes', params: {'n': '30'}),
          icon: Icons.directions_run,
        );
      case CyclePhase.luteal:
        return _PhaseSuggestion(
          title: context.tr('suggestion_meditation_title'),
          description: context.tr('suggestion_meditation_desc'),
          duration: context.tr('duration_minutes', params: {'n': '10'}),
          icon: Icons.spa,
        );
      case CyclePhase.unknown:
        return _PhaseSuggestion(
          title: context.tr('suggestion_wellness_title'),
          description: context.tr('suggestion_wellness_desc'),
          duration: context.tr('duration_minutes', params: {'n': '15'}),
          icon: Icons.favorite_border,
        );
    }
  }
}

class _PhaseSuggestion {
  final String title;
  final String description;
  final String duration;
  final IconData icon;

  _PhaseSuggestion({
    required this.title,
    required this.description,
    required this.duration,
    required this.icon,
  });
}
