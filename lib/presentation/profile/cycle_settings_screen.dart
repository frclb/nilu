import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/cycle_settings_repository.dart';
import '../../presentation/calendar/view_models/calendar_view_model.dart';
import '../../core/navigation/route_names.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';
import 'widgets/settings_surface.dart';

class CycleSettingsScreen extends StatefulWidget {
  const CycleSettingsScreen({super.key});

  @override
  State<CycleSettingsScreen> createState() => _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends State<CycleSettingsScreen> {
  final CycleSettingsRepository _settingsRepo = CycleSettingsRepository();
  int _cycleLength = 28;
  int _periodLength = 5;
  bool _hormonalContraception = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cycleLength = await _settingsRepo.getCycleLength();
    final periodLength = await _settingsRepo.getPeriodLength();
    final contraception = await _settingsRepo.getHormonalContraception();
    setState(() {
      // Sınıra kırpılıyor. `Slider` aralık dışı bir değerle çöküyor ve
      // ekran kırmızı hataya dönüşüyor; depodaki değer yedekten gelmiş ya
      // da eski bir sürümde yazılmış olabilir. Kullanıcının ayar ekranı,
      // veri beklenmedik diye kapanmamalı.
      _cycleLength = cycleLength.clamp(
        CycleSettingsRepository.minCycleLength,
        CycleSettingsRepository.maxCycleLength,
      );
      _periodLength = periodLength.clamp(
        CycleSettingsRepository.minPeriodLength,
        CycleSettingsRepository.maxPeriodLength,
      );
      _hormonalContraception = contraception;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    // Ayarları kaydet (settings_updated_at otomatik güncellenir)
    await _settingsRepo.saveCycleSettings(
      cycleLength: _cycleLength,
      periodLength: _periodLength,
    );
    await _settingsRepo.setHormonalContraception(_hormonalContraception);

    // CalendarViewModel'i yenile — yeni ayarlar yalnızca ileriye dönük uygulanır
    if (mounted) {
      context.read<CalendarViewModel>().refreshData();
      AppSnack.success(context, context.tr('cycle_settings_saved'));
      context.pop();
    }
  }

  String _days(int n) => context.tr('cycle_settings_days', params: {'n': '$n'});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: SettingsAppBar(
        title: context.tr('cycle_settings_title'),
        onBack: () => context.pop(),
      ),
      body: AmbientBackground(
        child: AppContentWidth(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    _buildSliderSetting(
                      context,
                      context.tr('cycle_settings_length'),
                      _cycleLength,
                      min: CycleSettingsRepository.minCycleLength,
                      max: CycleSettingsRepository.maxCycleLength,
                      color: scheme.primary,
                      onChanged: (val) {
                        setState(() {
                          _cycleLength = val.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSliderSetting(
                      context,
                      context.tr('cycle_settings_period'),
                      _periodLength,
                      min: CycleSettingsRepository.minPeriodLength,
                      max: CycleSettingsRepository.maxPeriodLength,
                      color: t.secondary,
                      onChanged: (val) {
                        setState(() {
                          _periodLength = val.toInt();
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Hormonal doğum kontrolü.
                    //
                    // Bu yöntemler çoğunlukla yumurtlamayı baskılar. Bayrak
                    // açıkken tahmin katmanı yumurtlama ve doğurganlık
                    // penceresi **hiç üretmiyor**; öncesinde hap kullanan bir
                    // kullanıcıya da yumurtlama günü gösteriliyordu.
                    SettingsCard(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        // Uzun açıklama: simge ve anahtar başlık hizasında.
                        isThreeLine: true,
                        value: _hormonalContraception,
                        onChanged: (v) =>
                            setState(() => _hormonalContraception = v),
                        // Renkler temadan geliyor. Burada `activeThumbColor`
                        // rayla **aynı** renge (primary) eziliyordu: açık
                        // hâlde topuz görünmüyor, anahtar tek parça bir
                        // dikdörtgene dönüyordu. Açık mı kapalı mı olduğu
                        // yalnızca renk tonundan anlaşılıyordu — konumdan
                        // değil.
                        secondary: AppIconTile(
                          icon: Icons.medication_outlined,
                          color: t.secondary,
                          background: t.secondaryTint,
                        ),
                        title: Text(
                          context.tr('cycle_settings_contraception'),
                          style: SettingsText.title(context),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            context.tr('cycle_settings_contraception_desc'),
                            style: SettingsText.subtitle(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Geçmiş başlangıçlar: ortalama ve aralık tahmini ancak
                    // birkaç döngüyle çıkıyor. Regl kaydı tutulmayan evrede
                    // (gebelik, lohusalık) yok.
                    if (context
                        .watch<CalendarViewModel>()
                        .lifeStage
                        .recordsPeriods) ...[
                      SettingsCard(
                        child: ListTile(
                          key: const Key('cycle_settings_past_periods'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: AppIconTile(
                            icon: Icons.history,
                            size: 48,
                            circle: true,
                          ),
                          title: Text(
                            context.tr('past_periods_entry'),
                            style: SettingsText.title(context),
                          ),
                          subtitle: Text(
                            context.tr('past_periods_entry_body'),
                            style: SettingsText.subtitle(context),
                          ),
                          trailing: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: t.brandTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: scheme.primary,
                            ),
                          ),
                          onTap: () =>
                              context.pushNamed(RouteNames.pastPeriods),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Bilgi notu
                    SettingsNote(text: context.tr('cycle_settings_note')),
                    const SizedBox(height: AppSpacing.xxl),
                    AppGradientButton(
                      label: context.tr('save'),
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _saveSettings,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// Süre kartı: başlık, sağda değer hapı, kaydırıcı ve uç değerler.
  Widget _buildSliderSetting(
    BuildContext context,
    String title,
    int value, {
    required int min,
    required int max,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    final ucStil = theme.textTheme.labelMedium?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    );

    return SettingsCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: SettingsText.title(context)?.copyWith(fontSize: 17),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Değer tek metin: dile göre "28 gün" / "28 days" — sayı ile
              // birimi ayrı yazmak birimi Türkçeye sabitlerdi.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.soft(context),
                ),
                child: Text(
                  _days(value),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            activeColor: color,
            onChanged: onChanged,
          ),
          Padding(
            // Uç değerler kaydırıcının ray uçlarının altında.
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_days(min), style: ucStil),
                Text(_days(max), style: ucStil),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
