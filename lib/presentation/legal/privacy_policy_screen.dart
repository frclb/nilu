import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';
import '../profile/widgets/settings_surface.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  /// Politikadaki bölüm sayısı.
  ///
  /// Sözlükte `privacy_policy_section1..N` anahtarları var; sayı burada
  /// tek yerde duruyor ve testi bu ikisinin uyuştuğunu doğruluyor.
  static const int _sectionCount = 11;

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  /// Bölüm dizinindeki bir başlığa dokununca o bölüme kaydırmak için.
  final _sections = List.generate(
    PrivacyPolicyScreen._sectionCount,
    (_) => GlobalKey(),
  );

  void _jumpTo(int index) {
    final ctx = _sections[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final titles = [
      for (var i = 1; i <= PrivacyPolicyScreen._sectionCount; i++)
        context.trPlatform('privacy_policy_section${i}_title'),
    ];

    return Scaffold(
      appBar: SettingsAppBar(
        title: context.tr('privacy_policy_title'),
        onBack: () => Navigator.of(context).pop(),
      ),
      body: AppContentWidth(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppTag(
                  label: context.tr('privacy_policy_last_updated'),
                  icon: Icons.history_rounded,
                  background: t.brandTint,
                  foreground: t.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionIndex(titles: titles, onTap: _jumpTo),
              const SizedBox(height: AppSpacing.lg),
              // Bölümler tek tek yazılmıyor: her yeni bölüm için altı
              // satırlık aynı bloğu kopyalamak, ekranın sözlükten
              // ayrışmasına açık kapı bırakıyordu.
              for (var i = 0; i < titles.length; i++)
                Padding(
                  key: _sections[i],
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildSection(
                    context,
                    title: titles[i],
                    content: context.trPlatform(
                      'privacy_policy_section${i + 1}_content',
                      params: {'email': _email(context)},
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final t = context.tokens;
    return SettingsCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ölçüler makale okuyucusuyla aynı (gövde 15): ikisi de uzun
          // metin ekranı. Ama stiller `TextStyle` ile sıfırdan yazıldığı
          // için başlıklar gövde yazı tipinde kalıyordu; makale başlıkları
          // `displayLarge` yani serif. Aynı uygulamanın iki uzun metin
          // ekranı iki farklı yazı ailesi kullanıyordu.
          Semantics(
            header: true,
            child: Text(
              title,
              style: AppTheme.readingHeading(
                context,
                color: Theme.of(context).colorScheme.primary,
              )?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTheme.readingBody(context, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Bölüm dizini: yatay kayan başlık hapları; dokununca o bölüme gider.
class _SectionIndex extends StatelessWidget {
  const _SectionIndex({required this.titles, required this.onTap});

  final List<String> titles;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: titles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => Material(
          color: t.surface,
          shape: StadiumBorder(side: BorderSide(color: t.border)),
          child: InkWell(
            onTap: () => onTap(i),
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  titles[i],
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Destek adresi; henüz verilmediyse dilin yer tutucusu.
String _email(BuildContext context) =>
    AppInfo.supportEmail ?? context.tr('legal_email_placeholder');
