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
import 'widgets/measurements_section.dart';
import '../../domain/models/vitals.dart';
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

  // Ölçümler (gebelik ve lohusalık). Doğrulama kaydederken (bkz. `_olcum`).
  final TextEditingController _kilo = TextEditingController();
  final TextEditingController _buyuk = TextEditingController();
  final TextEditingController _kucuk = TextEditingController();

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
    final kilo = _mevcut.weightKg;
    if (kilo != null) _kilo.text = _kiloMetni(kilo);
    if (_mevcut.systolic != null) _buyuk.text = '${_mevcut.systolic}';
    if (_mevcut.diastolic != null) _kucuk.text = '${_mevcut.diastolic}';
  }

  /// 64.0 → "64", 64.5 → "64,5" (alan virgülü de kabul ediyor).
  static String _kiloMetni(double kg) => kg == kg.roundToDouble()
      ? '${kg.round()}'
      : kg.toStringAsFixed(1).replaceAll('.', ',');

  /// Ölçüm alanlarını okur. Boş alan "yok" demek; dolu ama geçersiz alan
  /// `null` döndürür ve kayıt yapılmaz — "1205" ya da tek başına büyük
  /// tansiyon hekime giden özete girmemeli.
  ({double? kilo, int? buyuk, int? kucuk})? _olcum() {
    double? kilo;
    final k = _kilo.text.trim();
    if (k.isNotEmpty) {
      kilo = Vitals.parseDecimal(k);
      if (kilo == null || !Vitals.isPlausibleWeight(kilo)) return null;
    }

    final b = _buyuk.text.trim();
    final c = _kucuk.text.trim();
    if (b.isEmpty && c.isEmpty) return (kilo: kilo, buyuk: null, kucuk: null);
    final buyuk = int.tryParse(b);
    final kucuk = int.tryParse(c);
    if (buyuk == null ||
        kucuk == null ||
        !Vitals.isPlausibleBloodPressure(buyuk, kucuk)) {
      return null;
    }
    return (kilo: kilo, buyuk: buyuk, kucuk: kucuk);
  }

  @override
  void dispose() {
    _kilo.dispose();
    _buyuk.dispose();
    _kucuk.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    final viewModel = context.read<CalendarViewModel>();
    final today = DateTime.now();
    final stage = viewModel.lifeStage;

    // Ölçümler yalnızca gebelik ve lohusalıkta soruluyor; döngüde bölüm
    // yok ve kayıttaki değerlere dokunulmuyor.
    final olcumVar = stage != LifeStage.cycle;
    final olcum = olcumVar ? _olcum() : null;
    if (olcumVar && olcum == null) {
      AppSnack.error(context, context.tr('log_measure_invalid'));
      return;
    }

    final not = _notesController.text.isNotEmpty ? _notesController.text : null;
    // `copyWith`: bu ekranda sorulmayan alanlar (cinsel aktivite; döngüde
    // ölçümler) günün kaydından olduğu gibi korunuyor.
    final log = _mevcut.copyWith(
      flowIntensity: _flowIntensity,
      clearFlow: _flowIntensity == null,
      symptoms: _symptoms,
      moods: _moods,
      notes: not,
      clearNotes: not == null,
      painLevel: _pain.level,
      clearPain: _pain.level == null,
      painLimitedActivity: _pain.limitedActivity,
      painLocations: _pain.locations,
      painContexts: _pain.contexts,
      weightKg: olcum?.kilo,
      clearWeight: olcum != null && olcum.kilo == null,
      systolic: olcum?.buyuk,
      diastolic: olcum?.kucuk,
      clearBloodPressure: olcum != null && olcum.buyuk == null,
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
    if (stage.recordsPeriods &&
        LogVocabulary.startsPeriod(_flowIntensity) &&
        !viewModel.isPeriodDay(today)) {
      await viewModel.startPeriodToday();
    }

    if (!mounted) return;

    final uyari = _uyari(stage, log);
    if (uyari != null) {
      final tehlikeyeGit = await _uyariGoster(uyari, log) ?? false;
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
        queryParameters: {
          'period': stage == LifeStage.postpartum
              ? DangerPeriod.postpartum.name
              : DangerPeriod.pregnancy.name,
        },
      );
      return;
    }

    AppSnack.show(context, context.tr('home_log_saved'));
    NavigationService().pop();
  }

  /// Kayıttan sonra gösterilecek uyarı; yoksa `null`.
  ///
  /// Yalnızca bu kayıtta **değişen** değer için. Ekran günün kaydıyla
  /// açıldığından, sabah lekelenme girip akşam yalnızca ruh hâli ekleyen
  /// gebe kullanıcı aynı uyarıyı her kayıtta yeniden görürdü.
  ///
  /// Öncelik: ağır tansiyon (acil) > gebelikte kanama > yüksek tansiyon.
  _Uyari? _uyari(LifeStage stage, DailyLog log) {
    if (stage == LifeStage.cycle) return null;

    final buyuk = log.systolic;
    final kucuk = log.diastolic;
    final tansiyonYeni =
        buyuk != null &&
        kucuk != null &&
        (buyuk != _mevcut.systolic || kucuk != _mevcut.diastolic);
    final seviye = tansiyonYeni
        ? Vitals.classify(buyuk, kucuk)
        : BloodPressureLevel.normal;

    if (seviye == BloodPressureLevel.severe) return _Uyari.tansiyonAgir;
    if (stage == LifeStage.pregnancy &&
        LogVocabulary.isBleeding(log.flowIntensity) &&
        log.flowIntensity != _mevcut.flowIntensity) {
      return _Uyari.kanama;
    }
    if (seviye == BloodPressureLevel.high) return _Uyari.tansiyonYuksek;
    return null;
  }

  /// Tehlike işaretlerine gidilmek istenirse `true`.
  Future<bool?> _uyariGoster(_Uyari uyari, DailyLog log) {
    final deger = {'s': '${log.systolic}', 'd': '${log.diastolic}'};
    final (anahtar, baslik, govde) = switch (uyari) {
      _Uyari.kanama => (
        'preg_bleeding_dialog',
        'preg_bleeding_dialog_title',
        'preg_bleeding_dialog_body',
      ),
      _Uyari.tansiyonYuksek => (
        'bp_high_dialog',
        'bp_high_title',
        'bp_high_body',
      ),
      _Uyari.tansiyonAgir => (
        'bp_severe_dialog',
        'bp_severe_title',
        'bp_severe_body',
      ),
    };
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: Key(anahtar),
        icon: Icon(Icons.health_and_safety_outlined, color: ctx.tokens.warning),
        title: Text(ctx.tr(baslik)),
        content: Text(ctx.tr(govde, params: deger)),
        actions: [
          TextButton(
            key: const Key('warning_dialog_danger'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('danger_signs_action')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('ok')),
          ),
        ],
      ),
    );
  }

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
                  if (stage != LifeStage.cycle) ...[
                    MeasurementsSection(
                      weight: _kilo,
                      systolic: _buyuk,
                      diastolic: _kucuk,
                    ),
                    _buildDivider(isDark, theme),
                  ],
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

enum _Uyari { kanama, tansiyonYuksek, tansiyonAgir }
