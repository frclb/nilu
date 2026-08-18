import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/app_palette.dart';
import '../../../design_system/content_illustration.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class YogaContentSection extends StatelessWidget {
  const YogaContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── Colour palette ──
    final textColor = isDark ? Colors.white : AppColors.textMainSlate;
    final mutedColor = isDark
        ? AppPalette.nightInkMuted
        : AppColors.textMutedSlate;
    final cardColor = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final borderColor = isDark
        ? Colors.white.withAlpha(12)
        : AppColors.borderSlateLight;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryBgColor = isDark
        ? primaryColor.withAlpha(25)
        : primaryColor.withAlpha(25);
    final tagSecondaryBg = isDark
        ? Colors.white.withAlpha(25)
        : AppColors.borderSlate;
    final tagSecondaryText = context.tokens.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            context.tr('yoga_title'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // ── Tags ──
          Wrap(
            spacing: 8,
            children: [
              _buildTag(
                context.tr('yoga_tag_period'),
                primaryBgColor,
                primaryColor,
                primaryColor.withAlpha(51),
              ),
              _buildTag(
                context.tr('yoga_tag_relaxing'),
                tagSecondaryBg,
                tagSecondaryText,
                Colors.transparent,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stats Grid ──
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  value: context.tr('duration_minutes', params: {'n': '20'}),
                  label: context.tr('yoga_stat_duration'),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.signal_cellular_alt,
                  value: context.tr('yoga_level_beginner'),
                  label: context.tr('yoga_stat_level'),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.local_fire_department,
                  value: '120',
                  label: context.tr('yoga_stat_kcal'),
                  cardColor: cardColor,
                  borderColor: borderColor,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Benefits ──
          _sectionTitle(
            context.tr('yoga_benefits_title'),
            primaryColor,
            textColor,
          ),
          const SizedBox(height: 16),
          _buildBenefitCard(
            icon: Icons.spa,
            title: context.tr('yoga_benefit_cramps'),
            description: context.tr('yoga_benefit_cramps_desc'),
            cardColor: cardColor,
            borderColor: borderColor,
            primaryColor: primaryColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildBenefitCard(
            icon: Icons.self_improvement,
            title: context.tr('yoga_benefit_calm'),
            description: context.tr('yoga_benefit_calm_desc'),
            cardColor: cardColor,
            borderColor: borderColor,
            primaryColor: primaryColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildBenefitCard(
            icon: Icons.bedtime,
            title: context.tr('yoga_benefit_sleep'),
            description: context.tr('yoga_benefit_sleep_desc'),
            cardColor: cardColor,
            borderColor: borderColor,
            primaryColor: primaryColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
          const SizedBox(height: 32),

          // ── Yoga Poses ──
          _sectionTitle(
            context.tr('yoga_poses_title'),
            primaryColor,
            textColor,
          ),
          const SizedBox(height: 16),
          ..._buildYogaPoses(
            context,
            cardColor: cardColor,
            borderColor: borderColor,
            primaryColor: primaryColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
          const SizedBox(height: 32),

          // ── Instructor ──
          _sectionTitle(context.tr('yoga_instructor'), primaryColor, textColor),
          const SizedBox(height: 16),
          _buildInstructorCard(
            context: context,
            isDark: isDark,
            primaryColor: primaryColor,
            textColor: textColor,
            mutedColor: mutedColor,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Tag Badge ──
  Widget _buildTag(
    String label,
    Color bgColor,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ── Stat Card ──
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color cardColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title ──
  Widget _sectionTitle(String title, Color accent, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // ── Benefit Card ──
  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color cardColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: primaryColor, size: 22)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Yoga Poses List ──
  List<Widget> _buildYogaPoses(
    BuildContext context, {
    required Color cardColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    final poses = [
      {
        'name': context.tr('yoga_pose_child'),
        'duration': context.tr('duration_minutes', params: {'n': '3'}),
        'description': context.tr('yoga_pose_child_desc'),
        'icon': Icons.child_care,
      },
      {
        'name': context.tr('yoga_pose_cat_cow'),
        'duration': context.tr('duration_minutes', params: {'n': '3'}),
        'description': context.tr('yoga_pose_cat_cow_desc'),
        'icon': Icons.pets,
      },
      {
        'name': context.tr('yoga_pose_butterfly'),
        'duration': context.tr('duration_minutes', params: {'n': '4'}),
        'description': context.tr('yoga_pose_butterfly_desc'),
        'icon': Icons.flutter_dash,
      },
      {
        'name': context.tr('yoga_pose_twist'),
        'duration': context.tr('duration_minutes', params: {'n': '3'}),
        'description': context.tr('yoga_pose_twist_desc'),
        'icon': Icons.rotate_right,
      },
      {
        'name': context.tr('yoga_pose_legs_up'),
        'duration': context.tr('duration_minutes', params: {'n': '4'}),
        'description': context.tr('yoga_pose_legs_up_desc'),
        'icon': Icons.airline_seat_flat,
      },
      {
        'name': context.tr('yoga_pose_savasana'),
        'duration': context.tr('duration_minutes', params: {'n': '3'}),
        'description': context.tr('yoga_pose_savasana_desc'),
        'icon': Icons.hotel,
      },
    ];

    return poses
        .asMap()
        .entries
        .map(
          (entry) => Padding(
            padding: EdgeInsets.only(
              bottom: entry.key < poses.length - 1 ? 12 : 0,
            ),
            child: _buildPoseCard(
              index: entry.key + 1,
              name: entry.value['name'] as String,
              duration: entry.value['duration'] as String,
              description: entry.value['description'] as String,
              icon: entry.value['icon'] as IconData,
              cardColor: cardColor,
              borderColor: borderColor,
              primaryColor: primaryColor,
              textColor: textColor,
              mutedColor: mutedColor,
              isDark: isDark,
            ),
          ),
        )
        .toList();
  }

  Widget _buildPoseCard({
    required int index,
    required String name,
    required String duration,
    required String description,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required Color primaryColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 12, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Instructor Card ──
  Widget _buildInstructorCard({
    required BuildContext context,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primaryColor.withAlpha((isDark ? 0.20 : 0.08 * 255).toInt()),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: primaryColor.withAlpha(25)),
      ),
      child: Row(
        children: [
          // Avatar
          ClipOval(
            child: SizedBox(
              width: 48,
              height: 48,
              // Eğitmen fotoğrafı da geçici mockup adresindeydi.
              child: ContentIllustration(
                seed: 'yoga_instructor',
                icon: Icons.self_improvement,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('yoga_instructor_name'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('yoga_instructor_role'),
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
          // Profile button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('yoga_instructor_soon')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              context.tr('yoga_view_profile'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
