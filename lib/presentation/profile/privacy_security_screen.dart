import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../data/repositories/privacy_settings_repository.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final PrivacySettingsRepository _repository =
      const PrivacySettingsRepository();

  bool _faceIdEnabled = false;
  bool _pinEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final biometric = await _repository.getBiometricEnabled();
    final pin = await _repository.getPinEnabled();
    if (!mounted) return;
    setState(() {
      _faceIdEnabled = biometric;
      _pinEnabled = pin;
      _isLoading = false;
    });
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
                    border: Border.all(
                      color: isDark
                          ? Colors.blueGrey[800]!.withAlpha(127)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        context.tr('privacy_biometric'),
                        _faceIdEnabled,
                        (val) async {
                          setState(() => _faceIdEnabled = val);
                          await _repository.setBiometricEnabled(val);
                        },
                        isDark,
                        Icons.face_retouching_natural,
                        true,
                      ),
                      _buildSwitchTile(
                        context.tr('privacy_pin'),
                        _pinEnabled,
                        (val) async {
                          setState(() => _pinEnabled = val);
                          await _repository.setPinEnabled(val);
                        },
                        isDark,
                        Icons.pin,
                        false,
                      ),
                    ],
                  ),
                ),

                // Kilit tercihi kaydedilir ama henüz uygulama açılışında
                // zorunlu tutulmaz; kullanıcıyı yanıltmamak için açıkça yazılır.
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                  child: Text(
                    context.tr('privacy_lock_not_enforced'),
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
                    border: Border.all(
                      color: isDark
                          ? Colors.blueGrey[800]!.withAlpha(127)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Colors.green[600],
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
            ? Border(
                bottom: BorderSide(
                  color: isDark
                      ? Colors.blueGrey[800]!.withAlpha(127)
                      : Colors.grey[200]!,
                ),
              )
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
        inactiveTrackColor: isDark ? Colors.blueGrey[700] : Colors.grey[300],
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
    final color = isDestructive
        ? Colors.red[400]
        : (isDark ? Colors.white : Colors.black87);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceNavyDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.blueGrey[800]!.withAlpha(127)
              : Colors.grey[200]!,
        ),
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
        backgroundColor: isDark ? AppColors.surfaceNavyDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('privacy_export'),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              final messenger = ScaffoldMessenger.of(context);
              final doneMessage = context.tr('privacy_export_done');
              Navigator.of(ctx).pop();

              final json = await _repository.exportDataAsJson();
              await Clipboard.setData(ClipboardData(text: json));

              messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
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

  void _showDeleteAccountDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceNavyDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.tr('privacy_delete_account'),
          style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('privacy_delete_desc'),
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
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              final userViewModel = context.read<UserViewModel>();
              final doneMessage = context.tr('privacy_delete_done');
              Navigator.of(ctx).pop();

              // Cihazdaki tüm veriyi gerçekten sil, ardından onboarding'e dön.
              await _repository.deleteAllLocalData();
              await userViewModel.reloadAfterDataWipe();

              messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
              router.goNamed(RouteNames.onboarding);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(context.tr('privacy_delete_confirm')),
          ),
        ],
      ),
    );
  }
}
