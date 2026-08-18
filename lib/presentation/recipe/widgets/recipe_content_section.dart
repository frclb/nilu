import 'package:flutter/material.dart';
import '../../../design_system/app_palette.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class RecipeContentSection extends StatelessWidget {
  const RecipeContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ── Colour palette ──
    final bgColor = isDark
        ? AppColors.backgroundDeepDark
        : AppColors.backgroundLight;
    final textColor = isDark ? AppPalette.rose50 : AppColors.textMainLight;
    final mutedColor = isDark
        ? const Color(0xFFCFB6BD)
        : AppColors.textMutedLight;
    final surfaceColor = isDark ? const Color(0xFF2A151F) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withAlpha(12)
        : AppColors.borderGrayLight;
    final primaryColor = isDark
        ? const Color(0xFF551C25)
        : AppColors.primaryLight;
    final dotColor = isDark ? Colors.white.withAlpha(51) : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badges ──
          Row(
            children: [
              _buildBadge(
                label: context.tr('recipe_phase_follicular'),
                bgColor: primaryColor.withAlpha(51),
                textColor: isDark ? const Color(0xFFFBCFE8) : primaryColor,
                borderColor: primaryColor.withAlpha(76),
              ),
              const SizedBox(width: 8),
              _buildBadge(
                label: context.tr('recipe_tag_energizing'),
                bgColor: surfaceColor,
                textColor: mutedColor,
                borderColor: borderColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Title ──
          Text(
            context.tr('recipe_salmon_title'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),

          // ── Meta Row ──
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                context.tr('duration_minutes', params: {'n': '15'}),
                style: TextStyle(fontSize: 14, color: mutedColor),
              ),
              const SizedBox(width: 12),
              _dot(dotColor),
              const SizedBox(width: 12),
              Icon(Icons.bar_chart, size: 18, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                context.tr('recipe_difficulty_easy'),
                style: TextStyle(fontSize: 14, color: mutedColor),
              ),
              const SizedBox(width: 12),
              _dot(dotColor),
              const SizedBox(width: 12),
              Icon(Icons.star, size: 18, color: const Color(0xFFEAB308)),
              const SizedBox(width: 6),
              Text('4.9', style: TextStyle(fontSize: 14, color: mutedColor)),
            ],
          ),
          const SizedBox(height: 24),

          // ── Benefits Card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('recipe_benefits'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: mutedColor.withAlpha(204),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildBenefitItem(
                        icon: Icons.monitor_heart,
                        iconBgColor: isDark
                            ? AppPalette.iris500.withAlpha(25)
                            : const Color(0xFFEEF2FF),
                        iconColor: isDark
                            ? const Color(0xFFA5B4FC)
                            : AppPalette.iris500,
                        title: context.tr('recipe_magnesium'),
                        subtitle: context.tr('recipe_magnesium_desc'),
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBenefitItem(
                        icon: Icons.water_drop,
                        iconBgColor: isDark
                            ? AppPalette.clay600.withAlpha(25)
                            : AppPalette.clay100,
                        iconColor: isDark
                            ? AppPalette.clay400
                            : AppPalette.clay600,
                        title: context.tr('recipe_omega3'),
                        subtitle: context.tr('recipe_omega3_desc'),
                        textColor: textColor,
                        mutedColor: mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Ingredients ──
          _sectionTitle(
            context.tr('recipe_ingredients'),
            primaryColor,
            textColor,
          ),
          const SizedBox(height: 20),
          ..._buildIngredients(context, textColor, mutedColor, borderColor),
          const SizedBox(height: 32),

          // ── Steps ──
          _sectionTitle(context.tr('recipe_steps'), primaryColor, textColor),
          const SizedBox(height: 20),
          _buildStep(
            index: 1,
            text: context.tr('recipe_step_1'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            primaryColor: primaryColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildStep(
            index: 2,
            text: context.tr('recipe_step_2'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            primaryColor: primaryColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildStep(
            index: 3,
            text: context.tr('recipe_step_3'),
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            primaryColor: primaryColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
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
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: mutedColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, Color accentColor, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildIngredients(
    BuildContext context,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final items = [
      {'name': context.tr('recipe_ing_salmon'), 'amount': '150g'},
      {
        'name': context.tr('recipe_ing_quinoa'),
        'amount': context.tr('recipe_ing_quinoa_amount'),
      },
      {
        'name': context.tr('recipe_ing_avocado'),
        'amount': context.tr('recipe_ing_avocado_amount'),
      },
      {
        'name': context.tr('recipe_ing_spinach'),
        'amount': context.tr('recipe_ing_spinach_amount'),
      },
      {
        'name': context.tr('recipe_ing_dressing'),
        'amount': context.tr('recipe_ing_dressing_amount'),
      },
    ];

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                item['name']!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                item['amount']!,
                style: TextStyle(fontSize: 14, color: mutedColor),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStep({
    required int index,
    required String text,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
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
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: mutedColor, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
