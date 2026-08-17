import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../design_system/app_colors.dart';

class HealthLibraryFeaturedArticle extends StatelessWidget {
  const HealthLibraryFeaturedArticle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: GestureDetector(
        onTap: () {
          NavigationService().push(RouteNames.recipeDetail);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? AppColors.surfaceWarmDark : Colors.white,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
            border: isDark
                ? Border.all(color: Colors.white.withAlpha(12))
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCenyJDry4u1pEvRNlp0yQs-hXXDyd-IBsxqWIgiVeBaOhLFgjeBauDC4hk82fAdKp6jhYe42BQ5MM4U_lL3FfajPCtw0mN5TeOH_AJeppG0pom75rQ4N2VHFwINFL2qiYBKm8rL3rQ5eKZY68UsqIXzH6DSEA68F2GH1MpoQOn9P61x9clJu8J_d1titXe27MC8P9NT3d-5N5Bc9ispT5UfPTSOgtIX9AWEEXhMd0BXaD74pkrSUhG2QAFYKsar_tuVZVhMK0y54Y',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.black54,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // Editor's Choice Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withAlpha(153)
                          : Colors.white.withAlpha(229),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.tr('health_library_editor_choice'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF8A4F5B)
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Article Info
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(204),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr('library_cat_hormones'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('library_article_hormones'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.white.withAlpha(229),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context
                                .tr('health_library_read_time')
                                .replaceAll('{min}', '6'),
                            style: TextStyle(
                              color: Colors.white.withAlpha(229),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
