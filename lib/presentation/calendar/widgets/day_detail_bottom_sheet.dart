import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/calendar_view_model.dart';
import '../../../domain/models/daily_log.dart';
import '../../../domain/models/log_vocabulary.dart';
import '../../../localization/app_localizations.dart';
import '../../../../design_system/app_colors.dart';

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

  // Saklanan değerler kanonik kodlardır; etiketler lokalizasyondan gelir.
  static const List<String> _availableSymptoms = LogVocabulary.symptoms;

  // Akış yoğunluğunda 'none' bu ekranda gösterilmez (regl işaretliyken açılır).
  static const List<String> _flowIntensities = ['light', 'medium', 'heavy'];

  static const Map<String, String> _moodEmojis = {
    'happy': '😊',
    'sensitive': '😢',
    'irritable': '😠',
    'calm': '😌',
    'tired': '😴',
  };

  static const List<String> _sexualActivities = LogVocabulary.sexualActivities;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<CalendarViewModel>();
    _currentLog = viewModel.getDailyLogForDate(widget.date);
    _notesController = TextEditingController(text: _currentLog.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedLog = DailyLog(
      date: widget.date,
      symptoms: _currentLog.symptoms,
      notes: _notesController.text,
      flowIntensity: _currentLog.flowIntensity,
      moods: _currentLog.moods,
      sexualActivity: _currentLog.sexualActivity,
      painLevel: _currentLog.painLevel,
      painLimitedActivity: _currentLog.painLimitedActivity,
    );
    context.read<CalendarViewModel>().updateDailyLog(updatedLog);
  }

  void _updateCurrentLog({
    List<String>? symptoms,
    String? flowIntensity,
    List<String>? moods,
    String? sexualActivity,
    // Ağrı seviyesi kaldırılabilmeli: `clearPain` olmadan `painLevel: null`
    // "değiştirme" anlamına gelirdi ve seçim geri alınamazdı.
    String? painLevel,
    bool clearPain = false,
    bool? painLimitedActivity,
  }) {
    setState(() {
      _currentLog = DailyLog(
        date: widget.date,
        symptoms: symptoms ?? _currentLog.symptoms,
        notes: _notesController.text,
        flowIntensity: flowIntensity ?? _currentLog.flowIntensity,
        moods: moods ?? _currentLog.moods,
        sexualActivity: sexualActivity ?? _currentLog.sexualActivity,
        painLevel: clearPain ? null : (painLevel ?? _currentLog.painLevel),
        painLimitedActivity:
            painLimitedActivity ?? _currentLog.painLimitedActivity,
      );
    });
    _save(); // Auto-save
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
                      // doğurganlık" demek uydurma bir bilgi olurdu.
                      if (viewModel.cycleInfo.fertilityTracked) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getFertilityText(context, isFertile, isOvulation),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: (isFertile || isOvulation)
                                ? AppColors.moodOrangeText
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
                  // Regl Durumu
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.tr('day_detail_period_toggle'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Switch(
                      value: isPeriod,
                      activeThumbColor: AppColors.flowMedium,
                      onChanged: (_) async {
                        final success = await viewModel.togglePeriodDay(
                          widget.date,
                        );
                        if (!context.mounted) return;
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr('calendar_future_date_error'),
                              ),
                            ),
                          );
                        }
                      },
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
                    children: _availableSymptoms.map((code) {
                      final isSelected = _currentLog.symptoms.contains(code);
                      return FilterChip(
                        label: Text(context.tr(LogVocabulary.symptomKey(code))),
                        selected: isSelected,
                        onSelected: (_) => _toggleSymptom(code),
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.primary,
                      );
                    }).toList(),
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
                      return GestureDetector(
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

                  // Cinsel Aktivite
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
                          );
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

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
