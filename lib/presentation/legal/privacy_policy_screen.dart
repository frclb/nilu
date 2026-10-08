import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          context.tr('privacy_policy_title'),
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
                context.tr('privacy_policy_last_updated'),
                style: TextStyle(color: mutedColor, fontSize: 13),
              ),
              const SizedBox(height: 24),
              // Bölümler tek tek yazılmıyor: her yeni bölüm için altı
              // satırlık aynı bloğu kopyalamak, ekranın sözlükten
              // ayrışmasına açık kapı bırakıyordu.
              for (var i = 1; i <= _sectionCount; i++)
                _buildSection(
                  context,
                  textColor,
                  mutedColor,
                  title: context.tr('privacy_policy_section${i}_title'),
                  content: context.tr(
                    'privacy_policy_section${i}_content',
                    params: {'email': _email(context)},
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Politikadaki bölüm sayısı.
  ///
  /// Sözlükte `privacy_policy_section1..N` anahtarları var; sayı burada
  /// tek yerde duruyor ve testi bu ikisinin uyuştuğunu doğruluyor.
  static const int _sectionCount = 10;

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
          // Ölçüler makale okuyucusuyla aynı (başlık 18, gövde 15): ikisi
          // de uzun metin ekranı. Ama stiller `TextStyle` ile sıfırdan
          // yazıldığı için başlıklar gövde yazı tipinde kalıyordu; makale
          // başlıkları `displayLarge` yani serif. Aynı uygulamanın iki
          // uzun metin ekranı iki farklı yazı ailesi kullanıyordu.
          Text(
            title,
            style: AppTheme.readingHeading(context, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTheme.readingBody(context, color: mutedColor),
          ),
        ],
      ),
    );
  }
}

/// Destek adresi; henüz verilmediyse dilin yer tutucusu.
String _email(BuildContext context) =>
    AppInfo.supportEmail ?? context.tr('legal_email_placeholder');
