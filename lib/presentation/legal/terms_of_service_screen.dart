import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = context.tokens.text;
    final mutedColor = context.tokens.textMuted;

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
      body: AppContentWidth(
        child: SingleChildScrollView(
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
              // Politika ekranıyla aynı kalıp: bölümler tek tek
              // yazılmıyor, sayı tek yerde duruyor.
              for (var i = 1; i <= _sectionCount; i++)
                _buildSection(
                  context,
                  textColor,
                  mutedColor,
                  title: context.tr('terms_section${i}_title'),
                  content: context.tr('terms_section${i}_content'),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Şartlardaki bölüm sayısı. Sözlükteki `terms_sectionN_*` anahtarlarıyla
  /// uyuşması testle doğrulanıyor.
  static const int _sectionCount = 4;

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
