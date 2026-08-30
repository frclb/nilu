import 'dart:io';
import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/navigation/route_names.dart';
import '../../data/repositories/privacy_settings_repository.dart';
import '../../design_system/app_colors.dart';
import '../../domain/services/app_lock_service.dart';
import '../../domain/services/data_export_service.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/view_models/subscription_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../localization/app_localizations.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final PrivacySettingsRepository _repository =
      const PrivacySettingsRepository();

  final AppLockService _lockService = AppLockService();

  bool _lockEnabled = false;
  LockCapability _capability = LockCapability.none;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _lockService.isEnabled();
    final capability = await _lockService.capability();
    if (!mounted) return;
    setState(() {
      _lockEnabled = enabled;
      _capability = capability;
      _isLoading = false;
    });
  }

  /// Kilidi açıp kapatır.
  ///
  /// Açarken doğrulama istenir: kullanıcının kilidi gerçekten açabildiğini
  /// **açmadan önce** görmek gerekiyor, yoksa kendi verisinden kilitlenir.
  /// Kapatırken de istenir; telefonu eline geçiren biri kilidi sessizce
  /// kaldıramasın.
  Future<void> _toggleLock(bool value) async {
    if (value && !_capability.isAvailable) {
      _showMessage(context.tr('lock_unavailable'));
      return;
    }

    final ok = await _lockService.authenticate(
      reason: value
          ? context.tr('lock_reason_enable')
          : context.tr('lock_reason_disable'),
    );
    if (!mounted) return;

    if (!ok) {
      _showMessage(context.tr('lock_auth_failed'));
      return;
    }

    await _lockService.setEnabled(value);
    if (!mounted) return;
    setState(() => _lockEnabled = value);
    _showMessage(
      value ? context.tr('lock_enabled') : context.tr('lock_disabled'),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundNavyDark
          : AppColors.backgroundLightAlt,
      appBar: AppBar(
        title: Text(
          context.tr('privacy_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark
            ? AppColors.backgroundNavyDark
            : AppColors.backgroundLightAlt,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceNavyDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.tokens.border),
                  ),
                  child: Column(
                    children: [
                      // Eskiden burada iki anahtar vardı — "Biyometrik
                      // Kilit" ve "PIN Kodu" — ve ikisi de yalnızca bir
                      // tercih kaydediyordu. Tek anahtara indirildi:
                      // uygulama kendi PIN'ini saklamıyor, cihazın kimlik
                      // doğrulamasını kullanıyor (biyometri, yoksa cihaz
                      // şifresi). Parola saklamamak, saklamanın her
                      // türlüsünden güvenli.
                      _buildSwitchTile(
                        context.tr('privacy_app_lock'),
                        _lockEnabled,
                        _toggleLock,
                        isDark,
                        Icons.lock_outline,
                        true,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                  child: Text(
                    switch (_capability) {
                      LockCapability.biometric => context.tr(
                        'lock_hint_biometric',
                      ),
                      LockCapability.deviceCredential => context.tr(
                        'lock_hint_device',
                      ),
                      LockCapability.none => context.tr('lock_unavailable'),
                    },
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceNavyDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.tokens.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: context.tokens.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('privacy_encryption_notice'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildActionTile(
                  context,
                  context.tr('privacy_export'),
                  Icons.file_download_outlined,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  context,
                  context.tr('privacy_delete_account'),
                  Icons.person_remove_outlined,
                  isDark,
                  isDestructive: true,
                ),
              ],
            ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    IconData icon,
    bool hasBorder,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: hasBorder
            ? Border(bottom: BorderSide(color: context.tokens.border))
            : null,
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accentAmber,
        activeTrackColor: AppColors.accentAmber.withAlpha(127),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: isDark
            ? context.tokens.surfaceAlt
            : Colors.grey[300],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? context.tokens.danger : context.tokens.text;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceNavyDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tokens.border),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        onTap: () => isDestructive
            ? _showDeleteAccountDialog(context, isDark)
            : _showExportDataDialog(context, isDark),
      ),
    );
  }

  void _showExportDataDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('privacy_export')),
        content: Text(
          context.tr('privacy_export_desc'),
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.tr('cancel'),
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _exportAndShare();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(context.tr('privacy_export_confirm')),
          ),
        ],
      ),
    );
  }

  /// Veriyi dosya olarak dışa aktarır ve sistem paylaşım sayfasını açar.
  ///
  /// Eskiden JSON panoya kopyalanıyordu: sistem panosunu okuyabilen her
  /// uygulama sağlık verisini görebiliyordu ve binlerce satırı bir yere
  /// yapıştırmak pratikte kullanılamıyordu.
  ///
  /// Üç dosya birlikte veriliyor — okunabilir özet (muayenede telefondan
  /// okunur), CSV (tablo programı) ve tam JSON (kayıpsız yedek).
  Future<void> _exportAndShare() async {
    // Not: verinin kendisi her zaman kullanıcınındır — "Hesabımı Sil" ve
    // yerel kayıtlar kilitli değil. Premium olan yalnızca biçimlendirilmiş
    // dosya üretme kolaylığı.
    if (!PremiumGate.canExport(
      isPremium: context.read<SubscriptionViewModel>().isPremium,
    )) {
      final message = context.tr('insights_export_locked');
      final router = GoRouter.of(context);
      _showMessage(message);
      router.pushNamed(RouteNames.premium);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.tr('privacy_export_failed');

    // Çeviri fonksiyonu senkron olmalı; async boşluktan sonra context
    // kullanılamaz diye şimdiden yakalanıyor.
    String translate(String key, {Map<String, String>? params}) =>
        context.tr(key, params: params);

    try {
      final data = await _repository.loadExportData();
      final json = await _repository.exportDataAsJson();
      final now = DateTime.now();

      final summary = DataExportService.buildSummary(
        periodLogs: data.periodLogs,
        dailyLogs: data.dailyLogs,
        generatedAt: now,
        translate: translate,
      );
      final csv = DataExportService.buildCsv(
        dailyLogs: data.dailyLogs,
        periodLogs: data.periodLogs,
      );

      // Geçici dizin: paylaşım bittikten sonra sistem temizler, veri
      // cihazda kalıcı bir yerde birikmez.
      final dir = await getTemporaryDirectory();
      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';

      final files = <XFile>[
        await _writeTemp(dir.path, 'dongu-ozeti-$stamp.txt', summary),
        await _writeTemp(dir.path, 'dongu-kayitlari-$stamp.csv', csv),
        await _writeTemp(dir.path, 'dongu-yedek-$stamp.json', json),
      ];

      await SharePlus.instance.share(
        ShareParams(files: files, subject: translate('export_title')),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }

  Future<XFile> _writeTemp(String dir, String name, String content) async {
    final file = File('$dir/$name');
    await file.writeAsString(content);
    return XFile(file.path);
  }

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // Kırmızı burada yerinde — işlem gerçekten geri alınamaz. Ama ham
        // `Colors.red` değil paletin uyarı rengi kullanılıyor.
        title: Text(
          context.tr('privacy_delete_account'),
          style: Theme.of(
            context,
          ).dialogTheme.titleTextStyle?.copyWith(color: context.tokens.danger),
        ),
        content: Text(context.tr('privacy_delete_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              final userViewModel = context.read<UserViewModel>();
              final doneMessage = context.tr('privacy_delete_done');
              Navigator.of(ctx).pop();

              // Önce uzak veri: yerel silme `myId`'yi temizliyor, ondan
              // sonra hangi dokümanın silineceği bilinemez.
              await userViewModel.deleteRemoteData();
              await _repository.deleteAllLocalData();
              await userViewModel.reloadAfterDataWipe();

              messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
              router.goNamed(RouteNames.onboarding);
            },
            style: AppTheme.dialogAction().copyWith(
              backgroundColor: WidgetStatePropertyAll(context.tokens.danger),
              foregroundColor: const WidgetStatePropertyAll(Colors.white),
            ),
            child: Text(context.tr('privacy_delete_confirm')),
          ),
        ],
      ),
    );
  }
}
