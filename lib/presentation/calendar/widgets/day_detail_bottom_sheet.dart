import '../../../design_system/app_tappable.dart';
import '../../pregnancy/stage_bleeding_note.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/date_names.dart';
import 'package:provider/provider.dart';
import '../view_models/calendar_view_model.dart';
import '../../../data/repositories/privacy_settings_repository.dart';
import '../../../domain/models/daily_log.dart';
import '../../../domain/models/life_stage.dart';
import '../../../domain/models/log_vocabulary.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_snack.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';

/// Gün detay sayfasını açar.
///
/// Sayfa birden fazla yerden açılıyor; `showModalBottomSheet` ayarlarının
/// (tam yükseklik, güvenli alan, şeffaf zemin) hepsinde aynı kalması için
/// çağrı tek bir yerde toplandı.
///
/// `useRootNavigator` şart: sekme gövdesinin navigatöründe açılırsa alt menü
/// çubuğu sayfanın **üstüne** çiziliyor, notlar alanının altını kapatıyor ve
/// karartma perdesinin dışında kaldığı için yanlışlıkla sekme değiştirmeye
/// açık duruyor.
Future<void> showDayDetailSheet(BuildContext context, DateTime date) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DayDetailBottomSheet(date: date),
  );
}

class DayDetailBottomSheet extends StatefulWidget {
  final DateTime date;

  const DayDetailBottomSheet({super.key, required this.date});

  @override
  State<DayDetailBottomSheet> createState() => _DayDetailBottomSheetState();
}

class _DayDetailBottomSheetState extends State<DayDetailBottomSheet> {
  late TextEditingController _notesController;
  late DailyLog _currentLog;

  // Regl kademeleri sözlükten geliyor: 'none' ve 'spotting' burada
  // gösterilmez, çünkü ikisi de regl günü değil. Listeyi burada yeniden
  // yazmak, lekelenme eklenirken bu ekranın atlanmasına yol açmıştı.
  static const List<String> _flowIntensities =
      LogVocabulary.periodFlowIntensities;

  static const Map<String, String> _moodEmojis = {
    'happy': '😊',
    'sensitive': '😢',
    'irritable': '😠',
    'calm': '😌',
    'tired': '😴',
  };

  static const List<String> _sexualActivities = LogVocabulary.sexualActivities;

  /// Cinsel aktivite alanı açık mı (Gizlilik ayarı, varsayılan kapalı)?
  bool _sexualLogging = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<CalendarViewModel>();
    _currentLog = viewModel.getDailyLogForDate(widget.date);
    _notesController = TextEditingController(text: _currentLog.notes);
    _loadSexualLogging();
  }

  Future<void> _loadSexualLogging() async {
    final on = await const PrivacySettingsRepository()
        .getSexualActivityLogging();
    if (mounted && on) setState(() => _sexualLogging = true);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    // `copyWith`: bu sayfada olmayan alanlar (tansiyon, kilo) korunuyor.
    final updatedLog = _currentLog.copyWith(notes: _notesController.text);
    context.read<CalendarViewModel>().updateDailyLog(updatedLog);
  }

  void _updateCurrentLog({
    List<String>? symptoms,
    String? flowIntensity,
    List<String>? moods,
    String? sexualActivity,
    // Seçili çipe yeniden dokunmak seçimi kaldırmalı. `sexualActivity: null`
    // "dokunma" demek olduğu için seçim önceden hiç geri alınamıyordu.
    bool clearSexualActivity = false,
    String? pregnancyTest,
    bool clearPregnancyTest = false,
    // Ağrı seviyesi kaldırılabilmeli: `clearPain` olmadan `painLevel: null`
    // "değiştirme" anlamına gelirdi ve seçim geri alınamazdı.
    String? painLevel,
    bool clearPain = false,
    bool? painLimitedActivity,
    List<String>? painLocations,
    List<String>? painContexts,
    // Lekelenme anahtarı kapatılabilmeli; `flowIntensity: null` tek başına
    // "dokunma" anlamına geliyor.
    bool clearFlow = false,
  }) {
    setState(() {
      _currentLog = _currentLog.copyWith(
        symptoms: symptoms,
        notes: _notesController.text,
        flowIntensity: flowIntensity,
        clearFlow: clearFlow,
        moods: moods,
        sexualActivity: sexualActivity,
        clearSexualActivity: clearSexualActivity,
        pregnancyTest: pregnancyTest,
        clearPregnancyTest: clearPregnancyTest,
        painLevel: painLevel,
        clearPain: clearPain,
        painLimitedActivity: painLimitedActivity,
        painLocations: painLocations,
        painContexts: painContexts,
      );
    });
    _save(); // Auto-save
  }

  /// Çoklu seçim çip satırı.
  ///
  /// Ağrı yeri ve bağlamı aynı kalıbı paylaşıyor; ikisini ayrı ayrı
  /// yazmak, listelerden birine seçenek eklenince diğerinin unutulmasına
  /// açık kapı bırakırdı.
  Widget _chips({
    required List<String> codes,
    required List<String> selected,
    required String Function(String) labelKey,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: codes.map((code) {
        final isSelected = selected.contains(code);
        return _pill(
          label: context.tr(labelKey(code)),
          selected: isSelected,
          strong: true,
          onSelected: () {
            final next = List<String>.from(selected);
            isSelected ? next.remove(code) : next.add(code);
            onChanged(next);
          },
        );
      }).toList(),
    );
  }

  void _toggleSymptom(String symptom) {
    final newSymptoms = List<String>.from(_currentLog.symptoms);
    if (newSymptoms.contains(symptom)) {
      newSymptoms.remove(symptom);
    } else {
      newSymptoms.add(symptom);
    }
    _updateCurrentLog(symptoms: newSymptoms);
  }

  void _toggleMood(String label) {
    final newMoods = List<String>.from(_currentLog.moods);
    if (newMoods.contains(label)) {
      newMoods.remove(label);
    } else {
      newMoods.add(label);
    }
    _updateCurrentLog(moods: newMoods);
  }

  String _getFertilityText(
    BuildContext context,
    bool isFertile,
    bool isOvulation,
  ) {
    if (isOvulation) return context.tr('day_detail_fertility_peak');
    if (isFertile) return context.tr('day_detail_fertility_high');
    return context.tr('day_detail_fertility_low');
  }

  /// Gün gelecekte mi? Saat yok sayılıyor: takvim seçili günü saatiyle
  /// veriyor (`DateTime.now()`) ve bugün 01:43 gece yarısından "sonra"
  /// olduğu için bugün gelecek sayılıyor, gebelik testi ve ölçüm girişi
  /// bugün için gizleniyordu.
  bool get _gelecekGun {
    final n = DateTime.now();
    final d = widget.date;
    return DateTime(
      d.year,
      d.month,
      d.day,
    ).isAfter(DateTime(n.year, n.month, n.day));
  }

  void _olcumEkle() {
    final d = widget.date;
    final tarih =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    Navigator.pop(context);
    NavigationService().push(
      RouteNames.logEntry,
      queryParameters: {'date': tarih},
    );
  }

  /// Pozitif testten gebelik takibine: karar kullanıcının. Test tek başına
  /// evreyi değiştirmiyor; yanlış pozitif ya da erken kayıp mümkün ve
  /// gebelik kurulumu tarihleri zaten soruyor.
  void _gebelikBaslat() {
    Navigator.pop(context);
    NavigationService().push(RouteNames.pregnancySetup);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final viewModel = context.watch<CalendarViewModel>();
    final isPeriod = viewModel.isPeriodDay(widget.date);
    final cycleDay = viewModel.getCycleDayForDate(widget.date);

    final isFertile = viewModel.cycleInfo.isFertile(widget.date);
    final isOvulation = viewModel.cycleInfo.isOvulationDay(widget.date);

    final d = widget.date;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tutamaç (yalnızca görsel; sayfa aşağı çekilerek kapanıyor).
          ExcludeSemantics(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),

          // Başlık: tarih, gün adı, döngü günü ve doğurganlık etiketi.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 8,
                        children: [
                          Text(
                            context.capitalized(
                              context.tr(
                                'log_date_other',
                                params: {
                                  'day': '${d.day}',
                                  'month': context.monthName(d.month),
                                  'year': '${d.year}',
                                },
                              ),
                            ),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 26,
                              color: theme.colorScheme.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              context.weekdayName(d.weekday),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: t.textFaint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (cycleDay != null)
                            _HeaderTag(
                              icon: Icons.autorenew,
                              text: context.tr(
                                'day_detail_cycle_day',
                                params: {'day': '$cycleDay'},
                              ),
                              background: theme.colorScheme.primary,
                              foreground: theme.colorScheme.onPrimary,
                            ),
                          // Hormonal doğum kontrolünde doğurganlık satırı
                          // hiç gösterilmiyor: yumurtlama baskılanmışken
                          // "düşük doğurganlık" demek uydurma bir bilgi
                          // olurdu. Gebelik ve lohusalıkta da yok: gebe
                          // kullanıcıya "doğurganlık şansı: düşük"
                          // yazıyordu.
                          if (viewModel.lifeStage.showsCyclePredictions &&
                              viewModel.cycleInfo.fertilityTracked)
                            _HeaderTag(
                              dot: (isFertile || isOvulation)
                                  ? (isOvulation ? t.ovulation : t.secondary)
                                  : null,
                              text: _getFertilityText(
                                context,
                                isFertile,
                                isOvulation,
                              ),
                              background: (isFertile || isOvulation)
                                  ? t.secondaryTint
                                  : t.surfaceAlt,
                              foreground: (isFertile || isOvulation)
                                  ? t.secondary
                                  : t.textMuted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: t.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Regl ve lekelenme anahtarları.
                  _SheetCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Regl Durumu — yalnızca regl kaydının tutulduğu
                        // evrede. Gebelikte anahtar basılınca koruma
                        // reddediyor ve ekran "gelecek bir tarihe regl
                        // girilemez" diyordu.
                        if (!viewModel.lifeStage.recordsPeriods) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 4),
                            child: StageBleedingNote(
                              stage: viewModel.lifeStage,
                            ),
                          ),
                          // Tansiyon ve kilo yalnızca kayıt ekranında; o
                          // ekran önceden yalnızca bugünü açıyordu. Geçmiş
                          // güne ölçüm buradan.
                          if (!_gelecekGun)
                            ListTile(
                              key: const Key('day_detail_measure'),
                              contentPadding: EdgeInsets.zero,
                              leading: _RowIcon(
                                icon: Icons.monitor_heart_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(
                                context.tr('day_detail_add_measurement'),
                                style: theme.textTheme.titleMedium,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: t.textFaint,
                              ),
                              onTap: _olcumEkle,
                            ),
                        ] else
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: _RowIcon(
                              icon: Icons.water_drop,
                              color: t.secondary,
                            ),
                            title: Text(
                              context.tr('day_detail_period_toggle'),
                              style: theme.textTheme.titleMedium,
                            ),
                            trailing: Switch(
                              value: isPeriod,
                              onChanged: (_) async {
                                final success = await viewModel.togglePeriodDay(
                                  widget.date,
                                );
                                if (!context.mounted) return;
                                if (!success) {
                                  AppSnack.error(
                                    context,
                                    context.tr('calendar_future_date_error'),
                                  );
                                }
                              },
                            ),
                          ),

                        // Regl olmayan günlerde lekelenme. Ara kanama tam
                        // da geçmişe dönük girilen bulgu: kişi genelde
                        // ertesi gün fark ediyor. Yalnızca bugünü kaydeden
                        // "+" ekranında kalsaydı hiç yazılamazdı.
                        if (!isPeriod) ...[
                          Divider(height: 1, color: AppCard.dividerColor(t)),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: _RowIcon(
                              icon: Icons.opacity,
                              color: theme.colorScheme.primary,
                            ),
                            title: Text(
                              context.tr('log_flow_spotting'),
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              context.tr('day_detail_spotting_hint'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                            value:
                                _currentLog.flowIntensity ==
                                LogVocabulary.spotting,
                            onChanged: (selected) => _updateCurrentLog(
                              flowIntensity: selected
                                  ? LogVocabulary.spotting
                                  : null,
                              clearFlow: !selected,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (isPeriod)
                    _SheetCard(
                      title: context.tr('log_flow_intensity'),
                      child: _FlowTiles(
                        codes: _flowIntensities,
                        // Kayıt yoksa "Orta" seçili görünüyor (eski
                        // bölümlü düğmeyle aynı); dokunulunca kaydediliyor.
                        selected:
                            _flowIntensities.contains(_currentLog.flowIntensity)
                            ? _currentLog.flowIntensity!
                            : _flowIntensities[1],
                        onSelected: (code) =>
                            _updateCurrentLog(flowIntensity: code),
                      ),
                    ),

                  // Semptomlar
                  _SheetCard(
                    title: context.tr('day_detail_symptoms'),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      // Saklanan değerler kanonik kodlar; etiketler
                      // lokalizasyondan. Liste evreye göre: gebelikte
                      // bulantı, mide yanması, ödem…
                      children: LogVocabulary.symptomsFor(viewModel.lifeStage)
                          .map(
                            (code) => _pill(
                              label: context.tr(LogVocabulary.symptomKey(code)),
                              selected: _currentLog.symptoms.contains(code),
                              onSelected: () => _toggleSymptom(code),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  // Ağrı şiddeti.
                  //
                  // Önceden ağrı yalnızca "kramp var/yok"tu; her ay bir gün
                  // kramp giren kullanıcıyla her ay üç gün yatakta kalan
                  // kullanıcı aynı görünüyordu.
                  _SheetCard(
                    title: context.tr('day_detail_pain'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Segmented(
                          options: [
                            for (final code in LogVocabulary.painLevels)
                              _Option(
                                label: context.tr(
                                  LogVocabulary.painLevelKey(code),
                                ),
                                selected: _currentLog.painLevel == code,
                                // Aynı seçeneğe tekrar dokunmak seçimi
                                // kaldırır.
                                onTap: () {
                                  final isSelected =
                                      _currentLog.painLevel == code;
                                  _updateCurrentLog(
                                    painLevel: isSelected ? null : code,
                                    clearPain: isSelected,
                                  );
                                },
                              ),
                          ],
                        ),

                        // "Aktivitemi engelledi" — endometriozis için ayırt
                        // edici olan, ağrının varlığı değil normal
                        // aktiviteyi durdurması. Ağrı seçilmeden sormak
                        // anlamsız.
                        if (_currentLog.painLevel != null) ...[
                          const SizedBox(height: 6),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            value: _currentLog.painLimitedActivity,
                            onChanged: (v) => _updateCurrentLog(
                              painLimitedActivity: v ?? false,
                            ),
                            title: Text(
                              context.tr('day_detail_pain_limited'),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),

                          // Ağrının yeri ve bağlamı. Şiddet tek başına
                          // örüntü vermiyor; hekimi yönlendiren ayrıntı
                          // bunlar.
                          const SizedBox(height: 10),
                          _SubLabel(context.tr('log_pain_location')),
                          const SizedBox(height: 10),
                          _chips(
                            codes: LogVocabulary.painLocations,
                            selected: _currentLog.painLocations,
                            labelKey: LogVocabulary.painLocationKey,
                            onChanged: (v) =>
                                _updateCurrentLog(painLocations: v),
                          ),

                          const SizedBox(height: 18),
                          _SubLabel(context.tr('log_pain_when')),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('log_pain_when_hint'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _chips(
                            codes: LogVocabulary.painContexts,
                            selected: _currentLog.painContexts,
                            labelKey: LogVocabulary.painContextKey,
                            onChanged: (v) =>
                                _updateCurrentLog(painContexts: v),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Ruh Hali
                  _SheetCard(
                    title: context.tr('log_mood'),
                    // Kutular eşit boyda: küçülen etiket kutuyu kısaltmasın.
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final entry in _moodEmojis.entries) ...[
                            if (entry.key != _moodEmojis.keys.first)
                              const SizedBox(width: 6),
                            Expanded(
                              child: _MoodTile(
                                emoji: entry.value,
                                label: context.tr(
                                  LogVocabulary.moodKey(entry.key),
                                ),
                                selected: _currentLog.moods.contains(entry.key),
                                onTap: () => _toggleMood(entry.key),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Cinsel aktivite: Gizlilik'te açılınca. O günün kaydı
                  // varsa ayar kapalı olsa da görünüyor — kayıtlı bir değeri
                  // görünmez yapmak düzeltilemez yapmak olurdu.
                  if (_sexualLogging || _currentLog.sexualActivity != null)
                    _SheetCard(
                      title: context.tr('day_detail_sexual_activity'),
                      trailing: Icon(
                        Icons.favorite_border,
                        size: 20,
                        color: t.secondary,
                      ),
                      child: _ChoiceRow(
                        options: [
                          for (final code in _sexualActivities)
                            _Option(
                              label: context.tr(
                                LogVocabulary.sexualActivityKey(code),
                              ),
                              selected: _currentLog.sexualActivity == code,
                              onTap: () {
                                final isSelected =
                                    _currentLog.sexualActivity == code;
                                _updateCurrentLog(
                                  sexualActivity: isSelected ? null : code,
                                  clearSexualActivity: isSelected,
                                );
                              },
                            ),
                        ],
                      ),
                    ),

                  // Gebelik testi — yalnızca döngü evresinde ve geçmiş/bugün
                  // için. Gebelikte ve lohusalıkta anlamsız; gelecek güne
                  // test sonucu girilemez.
                  if (viewModel.lifeStage == LifeStage.cycle && !_gelecekGun)
                    _SheetCard(
                      title: context.tr('day_detail_pregnancy_test'),
                      trailing: Icon(
                        Icons.biotech_outlined,
                        size: 20,
                        color: t.textFaint,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ChoiceRow(
                            options: [
                              for (final code in LogVocabulary.pregnancyTests)
                                _Option(
                                  key: Key('day_detail_preg_test_$code'),
                                  label: context.tr(
                                    LogVocabulary.pregnancyTestKey(code),
                                  ),
                                  selected: _currentLog.pregnancyTest == code,
                                  onTap: () {
                                    final isSelected =
                                        _currentLog.pregnancyTest == code;
                                    _updateCurrentLog(
                                      pregnancyTest: isSelected ? null : code,
                                      clearPregnancyTest: isSelected,
                                    );
                                  },
                                ),
                            ],
                          ),
                          if (_currentLog.pregnancyTest ==
                              LogVocabulary.pregnancyTestPositive)
                            _PositiveTestCard(onStart: _gebelikBaslat),
                        ],
                      ),
                    ),

                  // Notlar
                  _SheetCard(
                    title: context.tr('day_detail_notes'),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      onChanged: (_) => _save(),
                      decoration: InputDecoration(
                        hintText: context.tr('day_detail_notes_hint'),
                        filled: true,
                        fillColor: t.surfaceAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sayfa her değişikliği anında kaydediyor; bu düğme ("Tamam")
          // yalnızca kapatıyor — kaydetmek için basılması gerekmiyor.
          // Klavye açıkken gizli: not alanına yer kalsın.
          if (!keyboardOpen)
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: AppCard.dividerColor(t))),
              ),
              child: AppGradientButton(
                label: context.tr('ok'),
                icon: Icons.check,
                height: 50,
                radius: AppRadius.pill,
                onPressed: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }

  /// Tek bir seçim çipi: seçiliyken gül tülü ve onay işareti.
  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    bool strong = false,
  }) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final fg = selected
        ? (strong ? scheme.onPrimary : t.secondary)
        : t.textMuted;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: t.surfaceAlt,
      selectedColor: strong ? scheme.primary : t.secondaryTint,
      checkmarkColor: fg,
      side: BorderSide.none,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: fg,
      ),
    );
  }
}

/// Pozitif test sonucunun altındaki not: doğrulama önerisi ve isteğe bağlı
/// gebelik takibi.
class _PositiveTestCard extends StatelessWidget {
  const _PositiveTestCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      key: const Key('day_detail_preg_test_positive_card'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.brandTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('day_detail_preg_test_positive_body'),
            style: TextStyle(fontSize: 14, height: 1.45, color: t.text),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('day_detail_preg_test_start'),
            onPressed: onStart,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 44),
            ),
            icon: const Icon(Icons.pregnant_woman, size: 20),
            label: Text(context.tr('day_detail_preg_test_start')),
          ),
        ],
      ),
    );
  }
}

/// Gün sayfasının bölüm kartı: beyaz, yuvarlak, başlıklı.
class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: AppCard.decoration(context.tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.tokens.text,
                      ),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Anahtar satırlarının solundaki yuvarlak simge kutusu.
class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AppIconTile(
    icon: icon,
    circle: true,
    background: context.tokens.surfaceAlt,
    color: color,
  );
}

/// Başlıktaki küçük hap etiket (döngü günü, doğurganlık).
class _HeaderTag extends StatelessWidget {
  const _HeaderTag({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
    this.dot,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ] else if (dot != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Regl günü akış kademesi: simge kutuları, seçili olan böğürtlen
/// degradesinde.
class _FlowTiles extends StatelessWidget {
  const _FlowTiles({
    required this.codes,
    required this.selected,
    required this.onSelected,
  });

  final List<String> codes;
  final String selected;
  final ValueChanged<String> onSelected;

  static const Map<String, IconData> _icons = {
    'light': Icons.opacity,
    'medium': Icons.water_drop,
    'heavy': Icons.waves,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final code in codes) ...[
          if (code != codes.first) const SizedBox(width: 8),
          Expanded(
            child: AppTappable(
              selected: code == selected,
              // Seçili kademeye yeniden dokunmak bir şey değiştirmiyor
              // (eski bölümlü düğmede de öyleydi).
              onTap: code == selected ? () {} : () => onSelected(code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: code == selected ? null : t.surfaceAlt,
                  gradient: code == selected
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [t.secondary, scheme.primary],
                        )
                      : null,
                  boxShadow: code == selected ? AppShadows.soft(context) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _icons[code] ?? Icons.water_drop,
                      size: 22,
                      color: code == selected ? scheme.onPrimary : t.secondary,
                    ),
                    const SizedBox(height: 6),
                    // Sığmayan etiket kelimenin ortasından bölünmesin;
                    // hafifçe küçülsün.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.tr(LogVocabulary.flowKey(code)),
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontSize: 12,
                              fontWeight: code == selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: code == selected
                                  ? scheme.onPrimary
                                  : t.textMuted,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bölümlü seçimin bir seçeneği.
class _Option {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Key? key;
}

/// Ağrı şiddeti: tül bir rayın içinde, seçili olan beyaz hap.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.options});

  final List<_Option> options;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: AppTappable(
                key: o.key,
                selected: o.selected,
                onTap: o.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: o.selected ? t.surface : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: o.selected ? AppShadows.soft(context) : null,
                  ),
                  child: Text(
                    o.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: o.selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: o.selected ? t.secondary : t.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Eşit genişlikte seçenek düğmeleri (cinsel aktivite, gebelik testi);
/// seçili olan erik dolgulu.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.options});

  final List<_Option> options;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AppTappable(
              key: options[i].key,
              selected: options[i].selected,
              onTap: options[i].onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 46),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: options[i].selected ? scheme.primary : t.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: options[i].selected
                      ? AppShadows.soft(context)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (options[i].selected) ...[
                      Icon(Icons.check, size: 16, color: scheme.onPrimary),
                      const SizedBox(width: 4),
                    ],
                    // Sığmayan etiket kelimenin ortasından bölünmesin;
                    // hafifçe küçülsün.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          options[i].label,
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 13.5,
                            fontWeight: options[i].selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: options[i].selected
                                ? scheme.onPrimary
                                : t.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Ruh hâli: emojili kutu.
class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppTappable(
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.secondaryTint : t.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? t.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji süs; VoiceOver yalnızca etiketi okusun.
            ExcludeSemantics(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 4),
            // Sığmayan etiket kelimenin ortasından bölünmesin; hafifçe
            // küçülsün.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? t.secondary : t.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bölüm içindeki alt başlık ("Ağrı nerede?").
class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: context.tokens.textMuted,
    ),
  );
}
