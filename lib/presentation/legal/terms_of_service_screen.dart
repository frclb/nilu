import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textMainLight;
    final mutedColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          context.tr('terms_of_service_title'),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('terms_last_updated'),
              style: TextStyle(color: mutedColor, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              textColor,
              mutedColor,
              title: context.tr('terms_section1_title'),
              content: context.tr('terms_section1_content'),
            ),
            _buildSection(
              context,
              textColor,
              mutedColor,
              title: context.tr('terms_section2_title'),
              content: context.tr('terms_section2_content'),
            ),
            _buildSection(
              context,
              textColor,
              mutedColor,
              title: context.tr('terms_section3_title'),
              content: context.tr('terms_section3_content'),
            ),
            _buildSection(
              context,
              textColor,
              mutedColor,
              title: context.tr('terms_section4_title'),
              content: context.tr('terms_section4_content'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    Color textColor,
    Color mutedColor, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: mutedColor, fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}
