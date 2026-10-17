import '../../../design_system/app_tappable.dart';
import '../../pregnancy/stage_bleeding_note.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
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
        return FilterChip(
          label: Text(context.tr(labelKey(code))),
          selected: isSelected,
          onSelected: (_) {
            final next = List<String>.from(selected);
            isSelected ? next.remove(code) : next.add(code);
            onChanged(next);
          },
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
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
    final viewModel = context.watch<CalendarViewModel>();
    final isPeriod = viewModel.isPeriodDay(widget.date);
    final cycleDay = viewModel.getCycleDayForDate(widget.date);

    final isFertile = viewModel.cycleInfo.isFertile(widget.date);
    final isOvulation = viewModel.cycleInfo.isOvulationDay(widget.date);

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
          // Header
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.date.day} / ${widget.date.month} / ${widget.date.year}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 22,
                        ),
                      ),
                      if (cycleDay != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            'day_detail_cycle_day',
                            params: {'day': '$cycleDay'},
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      // Hormonal doğum kontrolünde doğurganlık satırı hiç
                      // gösterilmiyor: yumurtlama baskılanmışken "düşük
                      // doğurganlık" demek uydurma bir bilgi olurdu. Gebelik
                      // ve lohusalıkta da yok: gebe kullanıcıya "doğurganlık
                      // şansı: düşük" yazıyordu.
                      if (viewModel.lifeStage.showsCyclePredictions &&
                          viewModel.cycleInfo.fertilityTracked) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getFertilityText(context, isFertile, isOvulation),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: (isFertile || isOvulation)
                                ? context.tokens.accent
                                : theme.textTheme.bodySmall?.color,
                            fontWeight: (isFertile || isOvulation)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Regl Durumu — yalnızca regl kaydının tutulduğu evrede.
                  // Gebelikte anahtar basılınca koruma reddediyor ve ekran
                  // "gelecek bir tarihe regl girilemez" diyordu.
                  if (!viewModel.lifeStage.recordsPeriods) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StageBleedingNote(stage: viewModel.lifeStage),
                    ),
                    // Tansiyon ve kilo yalnızca kayıt ekranında; o ekran
                    // önceden yalnızca bugünü açıyordu. Geçmiş güne ölçüm
                    // buradan.
                    if (!_gelecekGun)
                      ListTile(
                        key: const Key('day_detail_measure'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.monitor_heart_outlined),
                        title: Text(
                          context.tr('day_detail_add_measurement'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _olcumEkle,
                      ),
                  ] else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.tr('day_detail_period_toggle'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

                  // Regl olmayan günlerde lekelenme. Ara kanama tam da
                  // geçmişe dönük girilen bulgu: kişi genelde ertesi gün
                  // fark ediyor. Yalnızca bugünü kaydeden "+" ekranında
                  // kalsaydı hiç yazılamazdı.
                  if (!isPeriod)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.tr('log_flow_spotting'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(context.tr('day_detail_spotting_hint')),
                      value:
                          _currentLog.flowIntensity == LogVocabulary.spotting,
                      onChanged: (selected) => _updateCurrentLog(
                        flowIntensity: selected ? LogVocabulary.spotting : null,
                        clearFlow: !selected,
                      ),
                    ),

                  if (isPeriod) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.tr('log_flow_intensity'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: _flowIntensities
                            .map(
                              (code) => ButtonSegment<String>(
                                value: code,
                                label: Text(
                                  context.tr(LogVocabulary.flowKey(code)),
                                ),
                              ),
                            )
                            .toList(),
                        selected: {
                          _flowIntensities.contains(_currentLog.flowIntensity)
                              ? _currentLog.flowIntensity!
                              : _flowIntensities[1],
                        },
                        onSelectionChanged: (Set<String> newSelection) {
                          _updateCurrentLog(flowIntensity: newSelection.first);
                        },
                      ),
                    ),
                  ],

                  const Divider(height: 32),

                  // Semptomlar
                  Text(
                    context.tr('day_detail_symptoms'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    // Saklanan değerler kanonik kodlar; etiketler
                    // lokalizasyondan. Liste evreye göre: gebelikte bulantı,
                    // mide yanması, ödem…
                    children: LogVocabulary.symptomsFor(viewModel.lifeStage)
                        .map((code) {
                          final isSelected = _currentLog.symptoms.contains(
                            code,
                          );
                          return FilterChip(
                            label: Text(
                              context.tr(LogVocabulary.symptomKey(code)),
                            ),
                            selected: isSelected,
                            onSelected: (_) => _toggleSymptom(code),
                            selectedColor: theme.colorScheme.primaryContainer,
                            checkmarkColor: theme.colorScheme.primary,
                          );
                        })
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  // Ağrı şiddeti.
                  //
                  // Önceden ağrı yalnızca "kramp var/yok"tu; her ay bir gün
                  // kramp giren kullanıcıyla her ay üç gün yatakta kalan
                  // kullanıcı aynı görünüyordu.
                  Text(
                    context.tr('day_detail_pain'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LogVocabulary.painLevels.map((code) {
                      final isSelected = _currentLog.painLevel == code;
                      return ChoiceChip(
                        label: Text(
                          context.tr(LogVocabulary.painLevelKey(code)),
                        ),
                        selected: isSelected,
                        // Aynı seçeneğe tekrar dokunmak seçimi kaldırır.
                        onSelected: (_) => _updateCurrentLog(
                          painLevel: isSelected ? null : code,
                          clearPain: isSelected,
                        ),
                        selectedColor: theme.colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),

                  // "Aktivitemi engelledi" — endometriozis için ayırt edici
                  // olan, ağrının varlığı değil normal aktiviteyi durdurması.
                  // Ağrı seçilmeden sormak anlamsız.
                  if (_currentLog.painLevel != null) ...[
                    const SizedBox(height: 4),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      value: _currentLog.painLimitedActivity,
                      onChanged: (v) =>
                          _updateCurrentLog(painLimitedActivity: v ?? false),
                      title: Text(
                        context.tr('day_detail_pain_limited'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),

                    // Ağrının yeri ve bağlamı. Şiddet tek başına örüntü
                    // vermiyor; hekimi yönlendiren ayrıntı bunlar.
                    const SizedBox(height: 12),
                    Text(
                      context.tr('log_pain_location'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _chips(
                      codes: LogVocabulary.painLocations,
                      selected: _currentLog.painLocations,
                      labelKey: LogVocabulary.painLocationKey,
                      onChanged: (v) => _updateCurrentLog(painLocations: v),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      context.tr('log_pain_when'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('log_pain_when_hint'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.tokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _chips(
                      codes: LogVocabulary.painContexts,
                      selected: _currentLog.painContexts,
                      labelKey: LogVocabulary.painContextKey,
                      onChanged: (v) => _updateCurrentLog(painContexts: v),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Ruh Hali
                  Text(
                    context.tr('log_mood'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _moodEmojis.entries.map((entry) {
                      final code = entry.key;
                      final isSelected = _currentLog.moods.contains(code);
                      return AppTappable(
                        selected: isSelected,
                        onTap: () => _toggleMood(code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.dividerColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.value,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.tr(LogVocabulary.moodKey(code)),
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyMedium?.color,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Cinsel aktivite: Gizlilik'te açılınca. O günün kaydı varsa
                  // ayar kapalı olsa da görünüyor — kayıtlı bir değeri
                  // görünmez yapmak düzeltilemez yapmak olurdu.
                  if (_sexualLogging || _currentLog.sexualActivity != null) ...[
                    Text(
                      context.tr('day_detail_sexual_activity'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _sexualActivities.map((code) {
                        final isSelected = _currentLog.sexualActivity == code;
                        return ChoiceChip(
                          label: Text(
                            context.tr(LogVocabulary.sexualActivityKey(code)),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            _updateCurrentLog(
                              sexualActivity: selected ? code : null,
                              clearSexualActivity: !selected,
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Gebelik testi — yalnızca döngü evresinde ve geçmiş/bugün
                  // için. Gebelikte ve lohusalıkta anlamsız; gelecek güne
                  // test sonucu girilemez.
                  // Boşluklar bölümlerin sonunda: gizli bir bölüm araya iki
                  // kat boşluk bırakmasın.
                  if (viewModel.lifeStage == LifeStage.cycle &&
                      !_gelecekGun) ...[
                    Text(
                      context.tr('day_detail_pregnancy_test'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: LogVocabulary.pregnancyTests.map((code) {
                        final isSelected = _currentLog.pregnancyTest == code;
                        return ChoiceChip(
                          key: Key('day_detail_preg_test_$code'),
                          label: Text(
                            context.tr(LogVocabulary.pregnancyTestKey(code)),
                          ),
                          selected: isSelected,
                          onSelected: (selected) => _updateCurrentLog(
                            pregnancyTest: selected ? code : null,
                            clearPregnancyTest: !selected,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_currentLog.pregnancyTest ==
                        LogVocabulary.pregnancyTestPositive)
                      _PositiveTestCard(onStart: _gebelikBaslat),
                    const SizedBox(height: 24),
                  ],

                  // Notlar
                  Text(
                    context.tr('day_detail_notes'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    onChanged: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: context.tr('day_detail_notes_hint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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
