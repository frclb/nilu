import 'dart:io';
import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import 'package:file_selector/file_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/navigation/route_names.dart';
import '../../data/datasources/ad_consent.dart';
import '../../data/repositories/privacy_settings_repository.dart';
import '../../domain/services/app_lock_service.dart';
import '../../domain/services/backup_import_service.dart';
import '../../domain/services/data_export_service.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/view_models/subscription_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

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

  /// AEA'da rızasını veren kullanıcının onu **geri alabilmesi** gerekiyor.
  /// Girişi olmayan bir rıza kurulumu Google'ın gözünde eksik sayılıyor.
  /// AEA dışında Google "gerekli değil" diyor ve düğme hiç çizilmiyor.
  bool _adPrivacyOptions = false;

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

    // Rıza sorgusu ağa çıkıyor. Ekranın açılması ona bağlanmıyor — kilit
    // ayarları uzaktaki bir yanıtı beklemek zorunda değil. Düğme varsa
    // sonradan beliriyor.
    final adOptions = await AdConsent.privacyOptionsRequired();
    if (!mounted) return;
    setState(() => _adPrivacyOptions = adOptions);
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
      backgroundColor: context.tokens.surfaceAlt,
      appBar: AppBar(
        title: Text(
          context.tr('privacy_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.tokens.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.tokens.surfaceAlt,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.tokens.text,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppContentWidth(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
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
                        color: context.tokens.textMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
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
                              color: context.tokens.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reklam bildirimi. Ücretsiz sürümde reklam gösteriliyorsa
                  // kullanıcı bunu gizlilik ekranında görmeli — hem de ne
                  // toplanmadığıyla birlikte.
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.tokens.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.tokens.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 18,
                          color: context.tokens.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('privacy_ads_title'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.tokens.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('privacy_ads_notice'),
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: context.tokens.textMuted,
                                ),
                              ),
                              if (_adPrivacyOptions)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: AdConsent.showPrivacyOptions,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: const Size(0, 44),
                                      visualDensity: VisualDensity.standard,
                                    ),
                                    child: Text(
                                      context.tr('privacy_ads_options'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                    onTap: () => _showExportDataDialog(context, isDark),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    context,
                    context.tr('privacy_import'),
                    Icons.file_upload_outlined,
                    isDark,
                    onTap: () => _showImportDialog(context),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    context,
                    context.tr('privacy_delete_account'),
                    Icons.person_remove_outlined,
                    isDark,
                    isDestructive: true,
                    onTap: () => _showDeleteAccountDialog(context, isDark),
                  ),
                ],
              ),
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
            Icon(icon, size: 20, color: context.tokens.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.tokens.text,
                ),
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    bool isDark, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? context.tokens.danger : context.tokens.text;

    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
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
          color: context.tokens.textFaint,
        ),
        onTap: onTap,
      ),
    );
  }

  /// Yedeği geri yükleme akışı.
  ///
  /// Önce ne olacağı anlatılıyor: kullanıcı "geri yükleme" deyince çoğu
  /// uygulamada cihazdaki veri silinir, burada silinmiyor. Bunu söylemeden
  /// dosya seçtirmek, olmayan bir riski varmış gibi hissettirir.
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('privacy_import')),
        content: Text(
          ctx.tr('privacy_import_desc'),
          style: TextStyle(color: ctx.tokens.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              ctx.tr('cancel'),
              style: TextStyle(color: ctx.tokens.textMuted),
            ),
          ),
          ElevatedButton(
            style: AppTheme.dialogAction(),
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickAndImport();
            },
            child: Text(ctx.tr('privacy_import_confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImport() async {
    // Metinler `await`ten **önce** okunuyor: sonrasında `context` bir async
    // boşluğun ötesinde kalıyor.
    final messenger = ScaffoldMessenger.of(context);
    final viewModel = context.read<CalendarViewModel>();
    String message(String key, {Map<String, String>? params}) =>
        context.tr(key, params: params);

    final failureText = {
      ImportFailure.unreadable: message('privacy_import_unreadable'),
      ImportFailure.wrongFormat: message('privacy_import_wrong_format'),
      ImportFailure.empty: message('privacy_import_empty'),
    };
    final genericFailure = message('privacy_import_failed');

    try {
      // Yedek `.json`; iOS belge seçicisinde yalnızca o türü göstermek
      // kullanıcıyı yanlış dosyadan koruyor.
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'JSON',
            extensions: ['json'],
            uniformTypeIdentifiers: ['public.json'],
          ),
        ],
      );
      if (file == null) return; // Kullanıcı vazgeçti.

      final report = await _repository.importDataFromJson(
        await file.readAsString(),
      );

      if (!report.succeeded) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(failureText[report.failure] ?? genericFailure),
          ),
        );
        return;
      }

      // Bellekteki veri artık bayat: yenilenmezse kullanıcı geri
      // yüklediği kayıtları ancak uygulamayı kapatıp açınca görürdü.
      await viewModel.refreshData();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.totalAdded == 0
                ? message('privacy_import_nothing_new')
                : message(
                    'privacy_import_done',
                    params: {'n': '${report.totalAdded}'},
                  ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Import failed: $e');
      messenger.showSnackBar(SnackBar(content: Text(genericFailure)));
    }
  }

  void _showExportDataDialog(BuildContext context, bool isDark) {
    // Katman ekranın kendi bağlamından okunuyor, diyalogunkinden değil.
    //
    // Metin katmana göre değişiyor: ücretsiz kullanıcıya üretilmeyecek
    // dosyaları saymak, olmayan bir şeyi vaat etmek olurdu. Ama diyaloğun
    // bağlamı `Navigator`'ın altında; sağlayıcılar `MaterialApp`'in
    // üstünde olduğu sürece çalışıyor, olmadığında sessizce patlıyor.
    // Ekranın bağlamında böyle bir varsayım yok.
    final withReports = PremiumGate.canExportReports(
      isPremium: context.read<SubscriptionViewModel>().isPremium,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('privacy_export')),
        content: Text(
          ctx.tr(
            withReports ? 'privacy_export_desc' : 'privacy_export_desc_free',
          ),
          style: TextStyle(color: ctx.tokens.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.tr('cancel'),
              style: TextStyle(color: context.tokens.textMuted),
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
    // Yedek herkese açık, raporlar premium.
    //
    // Makine-okunur bir kopya almak KVKK ve GDPR'da bir hak; ücrete
    // bağlanamaz. Üstelik veri cihazda duruyor: yedek alamayan bir
    // kullanıcı telefonunu kaybettiğinde sağlık geçmişinin tamamını
    // kaybederdi. Hekim özeti ve tablo ise kolaylık — veri zaten yedekte
    // eksiksiz.
    final withReports = PremiumGate.canExportReports(
      isPremium: context.read<SubscriptionViewModel>().isPremium,
    );

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

      final summary = !withReports
          ? ''
          : DataExportService.buildSummary(
              periodLogs: data.periodLogs,
              dailyLogs: data.dailyLogs,
              generatedAt: now,
              translate: translate,
              breaks: data.breaks,
            );
      final csv = !withReports
          ? ''
          : DataExportService.buildCsv(
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
        await _writeTemp(dir.path, 'dongu-yedek-$stamp.json', json),
        if (withReports) ...[
          await _writeTemp(dir.path, 'dongu-ozeti-$stamp.txt', summary),
          await _writeTemp(dir.path, 'dongu-kayitlari-$stamp.csv', csv),
        ],
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
              final reauthMessage = context.tr('privacy_delete_reauth');
              Navigator.of(ctx).pop();

              // Önce uzak veri: yerel silme `myId`'yi temizliyor, ondan
              // sonra hangi dokümanın silineceği bilinemez.
              final accountDeleted = await userViewModel.deleteRemoteData();
              await _repository.deleteAllLocalData();
              await userViewModel.reloadAfterDataWipe();

              // Kimlik silinemediyse (Firebase eskimiş oturumu reddeder)
              // "hesabın silindi" demek yanlış olur: veri gitti ama hesap
              // duruyor ve yeniden girişte geri geliyor.
              messenger.showSnackBar(
                SnackBar(
                  content: Text(accountDeleted ? doneMessage : reauthMessage),
                ),
              );
              router.goNamed(RouteNames.onboarding);
            },
            style: AppTheme.dialogAction().copyWith(
              backgroundColor: WidgetStatePropertyAll(context.tokens.danger),
              foregroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: Text(context.tr('privacy_delete_confirm')),
          ),
        ],
      ),
    );
  }
}
