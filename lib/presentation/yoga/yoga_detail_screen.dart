import 'package:flutter/material.dart';
import '../widgets/favorite_button.dart';
import 'widgets/yoga_video_player.dart';
import 'widgets/yoga_content_section.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';

class YogaDetailScreen extends StatelessWidget {
  const YogaDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final primaryColor = AppColors.primaryDeep;
    final headerBorder = isDark
        ? Colors.white.withAlpha(12)
        : primaryColor.withAlpha(25);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Scrollable Content ──
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Sticky Header ──
              SliverAppBar(
                pinned: true,
                backgroundColor: isDark
                    ? bgColor.withAlpha(242)
                    : bgColor.withAlpha(242),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : AppColors.textMainSlate,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                centerTitle: true,
                title: Text(
                  context.tr('exercise_detail_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMainSlate,
                  ),
                ),
                actions: [const FavoriteButton(contentId: 'yoga_gentle_flow')],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: headerBorder),
                ),
              ),

              // ── Body ──
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const YogaVideoPlayer(
                      imageUrl:
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuAuOivrDk4ol2gFrgrkaeHOjAmU8eD_5Lqef293WrLOsSO1EBLaDpa8y8egTpVu2x9mpEWw6HTJ2VP-weChSGlzdAvHa8xIbDQ-hXTXcXzIbfAOS2k60C0kliH-9hRh0MXdcqjITvejx73APVwxaLk27B4pCug-lJsR7s4Ucq_e8f78IzLmZO0ApgdhNvIe1Ldan2kE7OgW51mNY812T8GHNpkRdTTNJe-5MiYtddBfvUudPdSQ7ApHqz61qXWnQsRDNV_tZfoL--8',
                    ),
                    const YogaContentSection(),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ],
          ),

          // ── Floating Bottom Button ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [bgColor, bgColor, bgColor.withAlpha(0)],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('exercise_starting'))),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: primaryColor.withAlpha(76),
                  ),
                  icon: const Icon(Icons.play_circle, size: 22),
                  label: Text(
                    context.tr('exercise_start'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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
}
