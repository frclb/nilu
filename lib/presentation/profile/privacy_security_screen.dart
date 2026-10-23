import '../../domain/view_models/pregnancy_view_model.dart';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
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
import '../../domain/services/backup_crypto.dart';
import '../../domain/services/backup_import_service.dart';
import '../../domain/services/data_export_service.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/view_models/subscription_view_model.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';
import 'widgets/settings_surface.dart';

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
  bool _sexualLogging = false;
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
    final sexualLogging = await _repository.getSexualActivityLogging();
    if (!mounted) return;
    setState(() {
      _lockEnabled = enabled;
      _sexualLogging = sexualLogging;
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
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: SettingsAppBar(
        title: context.tr('privacy_title'),
        onBack: () => context.pop(),
      ),
      body: AppContentWidth(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  // Eskiden burada iki anahtar vardı — "Biyometrik Kilit" ve
                  // "PIN Kodu" — ve ikisi de yalnızca bir tercih
                  // kaydediyordu. Tek anahtara indirildi: uygulama kendi
                  // PIN'ini saklamıyor, cihazın kimlik doğrulamasını
                  // kullanıyor (biyometri, yoksa cihaz şifresi). Parola
                  // saklamamak, saklamanın her türlüsünden güvenli.
                  SettingsCard(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: _buildSwitchTile(
                      context.tr('privacy_app_lock'),
                      _lockEnabled,
                      _toggleLock,
                      Icons.lock_outline_rounded,
                      subtitle: switch (_capability) {
                        LockCapability.biometric => context.tr(
                          'lock_hint_biometric',
                        ),
                        LockCapability.deviceCredential => context.tr(
                          'lock_hint_device',
                        ),
                        LockCapability.none => context.tr('lock_unavailable'),
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Hassas alanların görünürlüğü.
                  SettingsCard(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: _buildSwitchTile(
                      context.tr('privacy_sexual_log'),
                      _sexualLogging,
                      (v) async {
                        setState(() => _sexualLogging = v);
                        await _repository.setSexualActivityLogging(v);
                      },
                      Icons.favorite_border_rounded,
                      subtitle: context.tr('privacy_sexual_log_desc'),
                      key: const Key('privacy_sexual_log'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg + 2),
                    decoration: BoxDecoration(
                      color: t.brandTint,
                      borderRadius: BorderRadius.circular(AppCard.radius),
                    ),
                    child: Row(
                      children: [
                        AppIconTile(
                          icon: Icons.shield_outlined,
                          circle: true,
                          background: t.surface,
                          color: t.success,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            context.tr('privacy_encryption_notice'),
                            style: SettingsText.title(
                              context,
                            )?.copyWith(fontSize: 15, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reklam bildirimi. Ücretsiz sürümde reklam gösteriliyorsa
                  // kullanıcı bunu gizlilik ekranında görmeli — hem de ne
                  // toplanmadığıyla birlikte.
                  const SizedBox(height: AppSpacing.lg),
                  SettingsCard(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.campaign_outlined,
                              size: 22,
                              color: t.secondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.tr('privacy_ads_title'),
                                style: SettingsText.title(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.tr('privacy_ads_notice'),
                          style: SettingsText.subtitle(
                            context,
                          )?.copyWith(fontSize: 13.5, height: 1.5),
                        ),
                        if (_adPrivacyOptions)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton(
                              onPressed: AdConsent.showPrivacyOptions,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 44),
                                visualDensity: VisualDensity.standard,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      context.tr('privacy_ads_options'),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: t.secondary,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: t.secondary,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  SettingsCard(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        _buildActionTile(
                          context,
                          context.tr('privacy_export'),
                          Icons.download_rounded,
                          onTap: () => _showExportDataDialog(context),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 68,
                          endIndent: 14,
                          color: AppCard.dividerColor(t),
                        ),
                        _buildActionTile(
                          context,
                          context.tr('privacy_import'),
                          Icons.settings_backup_restore_rounded,
                          onTap: () => _showImportDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SettingsCard(
                    padding: const EdgeInsets.all(6),
                    child: _buildActionTile(
                      context,
                      context.tr('privacy_delete_account'),
                      Icons.delete_outline_rounded,
                      isDestructive: true,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
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
    IconData icon, {
    String? subtitle,
    Key? key,
  }) {
    return SwitchListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      // Açıklamalar uzun: simge ve anahtar başlık hizasında dursun.
      isThreeLine: subtitle != null,
      secondary: AppIconTile(
        icon: icon,
        circle: true,
        background: context.tokens.brandTint,
      ),
      title: Text(title, style: SettingsText.title(context)),
      subtitle: subtitle == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle, style: SettingsText.subtitle(context)),
            ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final t = context.tokens;
    final color = isDestructive ? t.danger : t.text;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: AppIconTile(
        icon: icon,
        color: isDestructive ? t.danger : null,
        background: isDestructive ? t.danger.withAlpha(28) : t.brandTint,
      ),
      title: Text(title, style: SettingsText.title(context, color: color)),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: isDestructive ? t.danger : t.textFaint,
      ),
      onTap: onTap,
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
        icon: const _DialogIcon(Icons.settings_backup_restore_rounded),
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
    final wrongPassword = message('privacy_import_password_wrong');

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

      var metin = await file.readAsString();
      if (BackupCrypto.isEncrypted(metin)) {
        if (!mounted) return;
        final parola = await _askBackupPassword();
        if (parola == null) return;
        try {
          final sifreli = metin;
          metin = await _withProgress(
            () => Isolate.run(() => BackupCrypto.decrypt(sifreli, parola)),
          );
        } on BackupPasswordException {
          messenger.showSnackBar(SnackBar(content: Text(wrongPassword)));
          return;
        } on BackupFormatException {
          messenger.showSnackBar(
            SnackBar(content: Text(failureText[ImportFailure.wrongFormat]!)),
          );
          return;
        }
      }

      final report = await _repository.importDataFromJson(metin);

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

  void _showExportDataDialog(BuildContext context) {
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
      builder: (ctx) => _ExportDialog(
        withReports: withReports,
        onExport: (password) async {
          Navigator.of(ctx).pop();
          await _exportAndShare(password: password);
        },
      ),
    );
  }

  /// İçe aktarılan şifreli yedeğin parolası. Vazgeçilirse `null`.
  Future<String?> _askBackupPassword() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const _DialogIcon(Icons.lock_open_rounded),
        title: Text(ctx.tr('privacy_import_password_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctx.tr('privacy_import_password_desc'),
              style: TextStyle(color: ctx.tokens.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('privacy_import_password'),
              controller: controller,
              obscureText: true,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: ctx.tr('privacy_export_password'),
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
          ],
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
            key: const Key('privacy_import_password_open'),
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(ctx.tr('privacy_import_open')),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  /// Uzun süren bir işi (anahtar türetme) dokunulmaz bir bekleme kutusuyla
  /// sarar: kullanıcı ekranın donduğunu sanıp ikinci kez basmasın.
  Future<T> _withProgress<T>(Future<T> Function() job) async {
    final nav = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Semantics(
            label: ctx.tr('privacy_working'),
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
    );
    try {
      return await job();
    } finally {
      nav.pop();
    }
  }

  /// Veriyi dosya olarak dışa aktarır ve sistem paylaşım sayfasını açar.
  ///
  /// Eskiden JSON panoya kopyalanıyordu: sistem panosunu okuyabilen her
  /// uygulama sağlık verisini görebiliyordu ve binlerce satırı bir yere
  /// yapıştırmak pratikte kullanılamıyordu.
  ///
  /// Üç dosya birlikte veriliyor — okunabilir özet (muayenede telefondan
  /// okunur), CSV (tablo programı) ve tam JSON (kayıpsız yedek).
  Future<void> _exportAndShare({String? password}) async {
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

      // Parolalı yedekte yalnızca şifreli dosya gidiyor: özet ve tablo düz
      // metin; kullanıcı "parolayla koru" dediğinde yanında açık bir kopya
      // göndermek korumayı boşa çıkarırdı.
      final yedek = password == null
          ? json
          : await _withProgress(
              () => Isolate.run(() => BackupCrypto.encrypt(json, password)),
            );

      final files = <XFile>[
        await _writeTemp(dir.path, 'nilu-yedek-$stamp.json', yedek),
        if (withReports && password == null) ...[
          await _writeTemp(dir.path, 'nilu-ozet-$stamp.txt', summary),
          await _writeTemp(dir.path, 'nilu-kayitlar-$stamp.csv', csv),
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        // Kırmızı burada yerinde — işlem gerçekten geri alınamaz. Ama ham
        // `Colors.red` değil paletin uyarı rengi kullanılıyor.
        icon: const _DialogIcon(
          Icons.delete_forever_outlined,
          destructive: true,
        ),
        title: Text(
          context.tr('privacy_delete_account'),
          style: Theme.of(
            context,
          ).dialogTheme.titleTextStyle?.copyWith(color: context.tokens.danger),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('privacy_delete_desc')),
            if (context.read<AccountViewModel>().isSignedIn) ...[
              const SizedBox(height: 12),
              Text(context.tr('privacy_delete_signed_in')),
            ],
          ],
        ),
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
              final hesap = context.read<AccountViewModel>();
              final gebelik = context.read<PregnancyViewModel>();
              final takvim = context.read<CalendarViewModel>();
              final doneMessage = context.tr('privacy_delete_done');
              final reauthMessage = context.tr('privacy_delete_reauth');
              final cancelledMessage = context.tr('account_delete_cancelled');
              final failedMessage = context.tr('account_delete_failed');
              Navigator.of(ctx).pop();

              // Önce uzak veri: yerel silme `myId`'yi temizliyor, ondan
              // sonra hangi dokümanın silineceği bilinemez.
              //
              // Apple ya da Google ile giriş yapıldıysa hesap silme kimliği
              // yeniden doğruluyor (Apple jetonu iptali dahil) ve bulut
              // kopyasını da siliyor. Doğrulamadan vazgeçilirse ya da
              // silinemezse **hiçbir şey** silinmiyor: cihazdaki veri
              // gidip buluttaki kalsaydı "tüm verilerim silindi" yanlış
              // olurdu.
              final bool accountDeleted;
              if (hesap.isSignedIn) {
                final sonuc = await hesap.deleteAccount();
                if (sonuc != AccountDeleteResult.deleted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        sonuc == AccountDeleteResult.cancelled
                            ? cancelledMessage
                            : failedMessage,
                      ),
                    ),
                  );
                  return;
                }
                accountDeleted = true;
              } else {
                accountDeleted = await userViewModel.deleteRemoteData();
              }
              await _repository.deleteAllLocalData();
              await userViewModel.reloadAfterDataWipe();
              // Bellekteki kopyalar da. Yalnızca depo silinip ViewModel'ler
              // yeniden okunmasaydı uygulama silinmiş kayıtları tutmaya
              // devam ediyordu: onboarding'den yeniden geçen kullanıcıya
              // silinmiş doğumun lohusa panosu açılıyordu.
              await gebelik.load();
              await takvim.refreshData();

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

/// Dışa aktarma kutusu: isteğe bağlı parola.
class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.withReports, required this.onExport});

  final bool withReports;

  /// Parola `null` ise yedek şifrelenmiyor.
  final Future<void> Function(String? password) onExport;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  final _parola = TextEditingController();
  final _tekrar = TextEditingController();
  bool _koru = false;

  @override
  void dispose() {
    _parola.dispose();
    _tekrar.dispose();
    super.dispose();
  }

  /// Gösterilecek hata; parola geçerliyse `null`.
  String? get _hata {
    if (!_koru) return null;
    if (_parola.text.length < BackupCrypto.minPasswordLength) {
      return context.tr(
        'privacy_export_password_short',
        params: {'n': '${BackupCrypto.minPasswordLength}'},
      );
    }
    if (_parola.text != _tekrar.text) {
      return context.tr('privacy_export_password_mismatch');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hata = _hata;
    // Hata yalnızca kullanıcı yazmaya başladıktan sonra: boş alanın
    // altında kırmızı yazı açılışta azarlıyor gibi görünür.
    final hataGoster =
        hata != null && (_parola.text.isNotEmpty || _tekrar.text.isNotEmpty);

    return AlertDialog(
      icon: const _DialogIcon(Icons.download_rounded),
      title: Text(context.tr('privacy_export')),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              widget.withReports
                  ? 'privacy_export_desc'
                  : 'privacy_export_desc_free',
            ),
            style: TextStyle(color: t.textMuted),
          ),
          const SizedBox(height: 16),
          // Parola seçeneği tül zeminli bir kutuda: yedeğin kendisinden
          // ayrı, isteğe bağlı bir katman olduğu görünsün.
          Material(
            color: t.brandTint,
            borderRadius: BorderRadius.circular(AppRadius.md),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              key: const Key('privacy_export_protect'),
              contentPadding: const EdgeInsets.only(left: 12, right: 4),
              secondary: Icon(
                Icons.enhanced_encryption_outlined,
                color: t.secondary,
              ),
              value: _koru,
              onChanged: (v) => setState(() => _koru = v),
              title: Text(
                context.tr('privacy_export_protect'),
                style: TextStyle(fontWeight: FontWeight.w600, color: t.text),
              ),
            ),
          ),
          if (_koru) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.key_off_outlined, size: 18, color: t.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('privacy_export_protect_desc'),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: t.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('privacy_export_password'),
              controller: _parola,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('privacy_export_password'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('privacy_export_password_repeat'),
              controller: _tekrar,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: context.tr('privacy_export_password_repeat'),
                errorText: hataGoster ? hata : null,
                errorMaxLines: 2,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            context.tr('cancel'),
            style: TextStyle(color: t.textMuted),
          ),
        ),
        ElevatedButton(
          key: const Key('privacy_export_confirm'),
          onPressed: hata != null
              ? null
              : () => widget.onExport(_koru ? _parola.text : null),
          style: AppTheme.dialogAction(),
          child: Text(context.tr('privacy_export_confirm')),
        ),
      ],
    );
  }
}

/// Diyalogların başındaki yuvarlak simge.
class _DialogIcon extends StatelessWidget {
  const _DialogIcon(this.icon, {this.destructive = false});

  final IconData icon;

  /// Geri alınamaz işlem: uyarı renginde.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppIconTile(
      icon: icon,
      size: 56,
      circle: true,
      color: destructive ? t.danger : t.secondary,
      background: destructive ? t.danger.withAlpha(28) : t.secondaryTint,
    );
  }
}
