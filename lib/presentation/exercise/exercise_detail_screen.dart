import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_names.dart';
import '../../../localization/app_localizations.dart';
import 'widgets/exercise_hero_header.dart';
import 'widgets/exercise_content_section.dart';
import '../../design_system/app_colors.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bottomBarBg = isDark
        ? AppColors.backgroundDark
        : Colors.white; // gradient base

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Main Scrollable Area
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const ExerciseHeroHeader(),
                Transform.translate(
                  offset: const Offset(0, -32), // Pull up to overlap header
                  child: const ExerciseContentSection(),
                ),
              ],
            ),
          ),

          // Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [bottomBarBg, bottomBarBg, bottomBarBg.withAlpha(0)],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.pushNamed(RouteNames.yogaDetail);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: theme.colorScheme.primary.withAlpha(127),
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  context.tr('exercise_start_button'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
