import '../pregnancy/danger_signs_screen.dart';
import '../../domain/models/life_stage.dart';
import '../../core/navigation/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/app_snack.dart';
import 'package:provider/provider.dart';
import 'widgets/log_entry_app_bar.dart';
import 'widgets/log_entry_header.dart';
import 'widgets/flow_intensity_section.dart';
import 'widgets/symptoms_section.dart';
import 'widgets/mood_section.dart';
import 'widgets/pain_section.dart';
import 'widgets/notes_section.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../domain/models/daily_log.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../../design_system/app_layout.dart';
import '../../domain/models/log_vocabulary.dart';

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});

  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final TextEditingController _notesController = TextEditingController();

  /// Günün mevcut kaydı. Ekran onunla açılıyor; kaydederken bu ekranda
  /// olmayan alanlar ondan korunuyor.
  ///
  /// Önceden ekran boş açılıyor ve kaydedince günün kaydını bütünüyle
  /// değiştiriyordu (`CalendarViewModel.updateDailyLog`): aynı gün takvimden
  /// girilen cinsel aktivite ya da lekelenme, lohusa panosundan girilen
  /// lohia, sabah girilen belirtiler — akşam yalnızca ruh hâli seçen
  /// kullanıcının hepsi siliniyordu.
  late final DailyLog _mevcut;

  String? _flowIntensity;
  List<String> _symptoms = [];
  List<String> _moods = [];
  PainEntry _pain = const PainEntry();

  @override
  void initState() {
    super.initState();
    _mevcut = context.read<CalendarViewModel>().getDailyLogForDate(
      DateTime.now(),
    );
    _flowIntensity = _mevcut.flowIntensity;
    _symptoms = List.of(_mevcut.symptoms);
    _moods = List.of(_mevcut.moods);
    _pain = PainEntry(
      level: _mevcut.painLevel,
      limitedActivity: _mevcut.painLimitedActivity,
      locations: _mevcut.painLocations,
      contexts: _mevcut.painContexts,
    );
    _notesController.text = _mevcut.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    final viewModel = context.read<CalendarViewModel>();
    final today = DateTime.now();

    final log = DailyLog(
      date: today,
      flowIntensity: _flowIntensity,
      symptoms: _symptoms,
      moods: _moods,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      painLevel: _pain.level,
      painLimitedActivity: _pain.limitedActivity,
      painLocations: _pain.locations,
      painContexts: _pain.contexts,
      // Bu ekranda sorulmuyor; günün kaydından korunuyor.
      sexualActivity: _mevcut.sexualActivity,
    );

    await viewModel.updateDailyLog(log);

    // Yalnızca **regl kademesindeki** akış dönemi başlatır. Tek günlük
    // kapalı bir kayıt açsaydık ertesi gün ana ekran yine "Reglim başladı"
    // derdi.
    //
    // Önceden koşul `_flowIntensity != null` idi: "Yok" seçen kullanıcı da
    // regl başlatıyordu, lekelenme de regl sayılacaktı.
    //
    // Yalnızca regl kaydının tutulduğu evrede: gebelikte ya da lohusalıkta
    // koruma zaten reddediyor, ama sessiz bir reddetmeye yaslanmak yerine
    // niyet burada açık.
    if (viewModel.lifeStage.recordsPeriods &&
        LogVocabulary.startsPeriod(_flowIntensity) &&
        !viewModel.isPeriodDay(today)) {
      await viewModel.startPeriodToday();
    }

    if (!mounted) return;

    // Gebelikte kanama bir tehlike işareti (Bakanlık listesi). Kayıt sessizce
    // kaydedilip geçilseydi kullanıcı bunun önemli olduğunu öğrenmezdi.
    // Lekelenme de dahil: gebelikte "az" kanama da hekime söylenmeli.
    if (viewModel.lifeStage == LifeStage.pregnancy &&
        LogVocabulary.isBleeding(_flowIntensity)) {
      final tehlikeyeGit = await _gebelikteKanamaUyarisi() ?? false;
      if (!mounted) return;
      // Diyalog kaydın tutulduğunu zaten söyledi; ayrıca bildirim yok.
      final router = tehlikeyeGit ? GoRouter.of(context) : null;
      NavigationService().pop();
      // Kayıt ekranı kapandıktan **sonra** açılıyor. Diyalogdan doğrudan
      // açıldığında yukarıdaki `pop` kayıt ekranını değil yeni açılan
      // tehlike işaretleri ekranını kapatıyordu: kullanıcı düğmeye basıyor,
      // ekran bir an görünüp kayboluyordu.
      router?.pushNamed(
        RouteNames.dangerSigns,
        queryParameters: {'period': DangerPeriod.pregnancy.name},
      );
      return;
    }

    AppSnack.show(context, context.tr('home_log_saved'));
    NavigationService().pop();
  }

  /// Tehlike işaretlerine gidilmek istenirse `true`.
  Future<bool?> _gebelikteKanamaUyarisi() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('preg_bleeding_dialog'),
      icon: Icon(Icons.health_and_safety_outlined, color: ctx.tokens.warning),
      title: Text(ctx.tr('preg_bleeding_dialog_title')),
      content: Text(ctx.tr('preg_bleeding_dialog_body')),
      actions: [
        TextButton(
          key: const Key('preg_bleeding_dialog_danger'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('preg_danger_entry_title')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('ok')),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stage = context.watch<CalendarViewModel>().lifeStage;

    return Scaffold(
      appBar: const LogEntryAppBar(),
      // Eylem çubuğu gövdenin değil `Scaffold`'un altında: içerik
      // sütununun içinde kalınca zemini geniş ekranda 600 pt'de
      // kesilip sayfanın üstünde sert kenarlı bir dikdörtgen
      // bırakıyordu. Burada tam genişlikte ve dibe sabitli — üstelik
      // gövdenin `Stack`'inin ekranı doldurmasına da bağlı değil.
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: context.tokens.surface.withAlpha(229),
          border: Border(
            top: BorderSide(color: context.tokens.surfaceAlt, width: 1),
          ),
        ),
        child: AppContentWidth(
          // Zemin tam genişlikte, düğme okunur sütunda kalıyor.
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: theme.colorScheme.primary.withAlpha(102),
              ),
              icon: const Icon(Icons.check, size: 20),
              label: Text(
                context.tr('log_save_button'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
      body: AppContentWidth(
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LogEntryHeader(),
                  FlowIntensitySection(
                    initialValue: _flowIntensity,
                    onChanged: (value) {
                      _flowIntensity = value;
                    },
                  ),
                  _buildDivider(isDark, theme),
                  SymptomsSection(
                    initialSymptoms: _symptoms,
                    codes: LogVocabulary.symptomsFor(stage),
                    // Gebelik notu seçime göre görünüp kaybolduğu için
                    // yeniden çiziliyor.
                    onChanged: (value) => setState(() => _symptoms = value),
                  ),
                  if (stage == LifeStage.pregnancy &&
                      _symptoms.any(
                        LogVocabulary.pregnancyWarningSymptoms.contains,
                      ))
                    const _GebelikBelirtiNotu(),
                  _buildDivider(isDark, theme),
                  // Ağrı, semptomlardan sonra: kullanıcı "kramp"ı
                  // işaretledikten hemen sonra şiddetini soruyoruz.
                  PainSection(
                    initialLevel: _pain.level,
                    initialLimited: _pain.limitedActivity,
                    initialLocations: _pain.locations,
                    initialContexts: _pain.contexts,
                    onChanged: (value) {
                      _pain = value;
                    },
                  ),
                  _buildDivider(isDark, theme),
                  MoodSection(
                    initialMoods: _moods,
                    onChanged: (value) {
                      _moods = value;
                    },
                  ),
                  _buildDivider(isDark, theme),
                  NotesSection(controller: _notesController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Divider(color: context.tokens.border, height: 1),
    );
  }
}

/// Gebelikte tehlike listesindeki bir maddeye karşılık gelen belirti
/// seçilince (bkz. `LogVocabulary.pregnancyWarningSymptoms`).
///
/// Teşhis değil: belirtinin kendisi değil şiddeti ya da aniden başlaması
/// önemli. Not bunu söylüyor ve listeye götürüyor.
class _GebelikBelirtiNotu extends StatelessWidget {
  const _GebelikBelirtiNotu();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        key: const Key('log_preg_symptom_note'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_outlined, size: 20, color: t.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('log_preg_symptom_note'),
                    style: TextStyle(fontSize: 13, height: 1.45, color: t.text),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                    ),
                    onPressed: () => context.pushNamed(
                      RouteNames.dangerSigns,
                      queryParameters: {'period': DangerPeriod.pregnancy.name},
                    ),
                    child: Text(context.tr('danger_signs_action')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
