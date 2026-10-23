import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../calendar/view_models/calendar_view_model.dart';
import 'care_text.dart';

/// Gebeliği işaretleme.
///
/// Tek sayfa, üç bölüm: tarih, bakım takvimi, ne değişecek. Çok adımlı bir
/// sihirbaz daha fazla durum ve daha fazla yarım kalma noktası demek.
///
/// "Ne değişecek" bölümü bilerek var: tahminlerin durması ve kanamanın artık
/// regl sayılmaması kullanıcıya sürpriz olmamalı.
class PregnancySetupScreen extends StatefulWidget {
  const PregnancySetupScreen({
    super.key,
    this.fromOnboarding = false,
    @visibleForTesting this.today,
  });

  /// İlk kurulumdan, "Hamileyim" seçilerek açıldı.
  ///
  /// Bitince ana ekrana değil kurulumun son ekranına gidiliyor (kurulumu o
  /// tamamlıyor). "Ne değişecek" bölümü de yok: uygulama yeni, değişecek bir
  /// tahmin yok; yerine aynı uyarıların "bilmen gerekenler" hâli var.
  final bool fromOnboarding;

  final DateTime? today;

  @override
  State<PregnancySetupScreen> createState() => _PregnancySetupScreenState();
}

enum _Kaynak { lmp, clinician }

class _PregnancySetupScreenState extends State<PregnancySetupScreen> {
  _Kaynak _kaynak = _Kaynak.lmp;

  /// Kullanıcının seçtiği son adet tarihi. Seçmediyse takvimdeki son regl
  /// başlangıcı kullanılıyor (bkz. [_sat]).
  DateTime? _satSecilen;
  DateTime? _edd;
  bool? _turkiyeSablonu;
  bool _kaydediliyor = false;

  DateTime get _bugun {
    final n = widget.today ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Uygulama son adet tarihini zaten biliyor: ön dolu gelsin.
  ///
  /// Açılışta bir kez okunup saklanmıyor. Takvim o sırada henüz
  /// yüklenmemişse değer boş kalıyor ve bir daha dolmuyordu: başlat düğmesi
  /// kapalı, kullanıcı uygulamanın bildiği tarihi kendisi aramak zorunda.
  DateTime? get _sat =>
      _satSecilen ??
      context.read<CalendarViewModel>().cycleInfo.lastPeriodStart;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bakım şablonu yalnızca Türkçe'de var (bkz. `CareTemplates`); diğer
    // dillerde "kendi randevularım" varsayılan, yanlış ülkenin takvimini
    // göstermektense boş liste daha dürüst.
    _turkiyeSablonu ??= Localizations.localeOf(context).languageCode == 'tr';
  }

  int get _donguUzunlugu =>
      context.read<CalendarViewModel>().cycleInfo.averageCycleLength;

  /// Döngü uzunluğu kullanıcının mı, varsayılan mı?
  ///
  /// Kurulumda gebelik yolunu seçen kullanıcıya döngüsü hiç sorulmadı; hesap
  /// 28 günle yapılıyor ve metin bunu "28 günlük döngüne göre" diye değil
  /// varsayım olarak söylüyor.
  bool get _donguBiliniyor =>
      context.read<CalendarViewModel>().cycleLengthKnown;

  /// Seçimlere göre oluşacak gebelik; eksikse `null`.
  Pregnancy? get _onizleme {
    switch (_kaynak) {
      case _Kaynak.lmp:
        final s = _sat;
        if (s == null) return null;
        return Pregnancy.fromLmp(
          lmp: s,
          cycleLength: _donguUzunlugu,
          confirmedAt: _bugun,
        );
      case _Kaynak.clinician:
        final e = _edd;
        if (e == null) return null;
        return Pregnancy.fromDueDate(
          dueDate: e,
          lmp: _sat,
          confirmedAt: _bugun,
        );
    }
  }

  /// Tahmini doğum tarihi geçmişse kurulum anlamsız.
  bool get _gecerli {
    final g = _onizleme;
    return g != null && !g.estimatedDueDate.isBefore(_bugun);
  }

  Future<void> _tarihSec() async {
    final sat = _kaynak == _Kaynak.lmp;
    final secilen = await showDatePicker(
      context: context,
      initialDate: sat ? (_sat ?? _bugun) : (_edd ?? _bugun),
      firstDate: sat ? _bugun.subtract(const Duration(days: 300)) : _bugun,
      lastDate: sat ? _bugun : _bugun.add(const Duration(days: 300)),
    );
    if (secilen == null) return;
    setState(() => sat ? _satSecilen = secilen : _edd = secilen);
  }

  Future<void> _baslat() async {
    if (!_gecerli || _kaydediliyor) return;
    setState(() => _kaydediliyor = true);

    final vm = context.read<PregnancyViewModel>();
    final sablon = (_turkiyeSablonu ?? false) ? 'tr' : null;
    // Gebelik başlamadan: başladıktan sonra takvimde regl kaydı
    // değiştirilemiyor (bkz. `CalendarViewModel._canRecordPeriods`).
    await context.read<CalendarViewModel>().closeOngoingPeriods();
    if (!mounted) return;
    if (_kaynak == _Kaynak.lmp) {
      await vm.startFromLmp(
        lmp: _sat!,
        cycleLength: _donguUzunlugu,
        careTemplate: sablon,
      );
    } else {
      await vm.startFromDueDate(
        dueDate: _edd!,
        lmp: _sat,
        careTemplate: sablon,
      );
    }
    if (!mounted) return;
    context.goNamed(
      widget.fromOnboarding ? RouteNames.onboardingSuccess : RouteNames.home,
    );
  }

  String _tarih(DateTime d) =>
      '${d.day} ${context.monthName(d.month)} ${d.year}';

  @override
  Widget build(BuildContext context) {
    // Takvim yüklenince ön dolu tarih ve döngü uzunluğu güncellensin.
    context.watch<CalendarViewModel>();
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final g = _onizleme;
    final ga = g?.gestationOn(_bugun);
    final secili = _kaynak == _Kaynak.lmp ? _sat : _edd;
    final etkin = _gecerli && !_kaydediliyor;

    TextStyle? govde([Color? c]) => theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.5,
      color: c ?? t.text,
    );

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(context.tr('preg_setup_title')),
      ),
      body: AppContentWidth(
        child: SafeArea(
          // Tek sütun, hepsi bir arada kuruluyor: kartlar uzadığında tembel
          // bir liste alttaki "başlat" düğmesini ekran dışındayken hiç
          // kurmuyordu.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 1. Tarih ──
                _Bolum(context.tr('preg_setup_date_section')),
                SegmentedButton<_Kaynak>(
                  segments: [
                    ButtonSegment(
                      value: _Kaynak.lmp,
                      label: Text(context.tr('preg_setup_from_lmp')),
                    ),
                    ButtonSegment(
                      value: _Kaynak.clinician,
                      label: Text(context.tr('preg_setup_from_clinician')),
                    ),
                  ],
                  selected: {_kaynak},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _kaynak = s.first),
                ),
                const SizedBox(height: AppSpacing.md),

                // Tarih seçici: kart, hangi tarihin sorulduğunu ve seçileni
                // birlikte gösteriyor.
                Container(
                  decoration: AppCard.decoration(t),
                  child: Material(
                    type: MaterialType.transparency,
                    borderRadius: BorderRadius.circular(AppCard.radius),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: const Key('preg_setup_pick_date'),
                      onTap: _tarihSec,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            AppIconTile(
                              icon: Icons.event_outlined,
                              size: 44,
                              circle: true,
                              background: t.brandTint,
                              color: primary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr(
                                      _kaynak == _Kaynak.lmp
                                          ? 'preg_setup_pick_lmp'
                                          : 'preg_setup_pick_due',
                                    ),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: t.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  if (secili != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _tarih(secili),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: t.text,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.edit_calendar_outlined,
                              color: t.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (g != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  // Hesaplanan tarih: kartın en önemli sonucu, serif başlıkla.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl - 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppCard.radius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [t.brandTint, t.surface],
                      ),
                      border: Border.all(color: AppCard.borderColor(t)),
                      boxShadow: AppCard.shadow(t),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            'preg_setup_due_result',
                            params: {'date': _tarih(g.estimatedDueDate)},
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 21,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                        if (ga != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            context.gestationSentence(ga),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: t.text,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.info_outline,
                                size: 17,
                                color: t.secondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                context.tr(
                                  _kaynak == _Kaynak.clinician
                                      ? 'preg_setup_due_method_clinician'
                                      : _donguBiliniyor
                                      ? 'preg_setup_due_method_lmp'
                                      : 'preg_setup_due_method_lmp_assumed',
                                  params: {'n': '$_donguUzunlugu'},
                                ),
                                style: govde(
                                  t.textMuted,
                                )?.copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!_gecerli) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.tr('preg_setup_due_passed'),
                      style: govde(t.warning),
                    ),
                  ],
                ],

                const SizedBox(height: AppSpacing.xxl - 4),

                // ── 2. Bakım takvimi ──
                _Bolum(context.tr('preg_setup_care_section')),
                RadioGroup<bool>(
                  groupValue: _turkiyeSablonu,
                  onChanged: (v) => setState(() => _turkiyeSablonu = v),
                  child: Column(
                    children: [
                      _SablonKarti(
                        value: true,
                        selected: _turkiyeSablonu == true,
                        title: context.tr('preg_setup_care_tr'),
                        body: context.tr('preg_setup_care_tr_body'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SablonKarti(
                        value: false,
                        selected: _turkiyeSablonu == false,
                        title: context.tr('preg_setup_care_own'),
                        body: context.tr('preg_setup_care_own_body'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl - 4),

                // ── 3. Ne değişecek ──
                _Bolum(
                  context.tr(
                    widget.fromOnboarding
                        ? 'preg_setup_good_to_know'
                        : 'preg_setup_changes_section',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: AppCard.decoration(t),
                  child: Column(
                    children: [
                      for (final (i, (k, icon, renk, zemin)) in [
                        if (!widget.fromOnboarding)
                          (
                            'preg_setup_change_predictions',
                            Icons.water_drop_outlined,
                            t.flow,
                            t.flowTint,
                          ),
                        (
                          'preg_setup_change_bleeding',
                          Icons.healing_outlined,
                          t.danger,
                          t.flowTint,
                        ),
                        (
                          'preg_setup_change_reminders',
                          Icons.schedule,
                          primary,
                          t.brandTint,
                        ),
                      ].indexed) ...[
                        if (i > 0)
                          Divider(height: 1, color: AppCard.dividerColor(t)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppIconTile(
                                icon: icon,
                                size: 36,
                                circle: true,
                                background: zemin,
                                color: renk,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(context.tr(k), style: govde()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                // Degrade dolgu yalnızca düğme etkinken: kapalı düğme temanın
                // soluk görünümünde kalsın, "basılabilir" sanılmasın.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: etkin ? AppGradients.primary(context) : null,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: etkin ? AppShadows.floating(context) : null,
                  ),
                  child: FilledButton(
                    key: const Key('preg_setup_start'),
                    onPressed: etkin ? _baslat : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: etkin ? Colors.transparent : null,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(context.tr('preg_setup_start')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bölüm etiketi ("TARİH").
class _Bolum extends StatelessWidget {
  const _Bolum(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm + 2),
    child: AppSectionLabel(text),
  );
}

/// Bakım takvimi seçeneği: kart içinde radyo satırı. Seçili kart erik
/// çerçeveyle ayrışıyor.
class _SablonKarti extends StatelessWidget {
  const _SablonKarti({
    required this.value,
    required this.selected,
    required this.title,
    required this.body,
  });

  final bool value;
  final bool selected;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: AppCard.decoration(t).copyWith(
        border: Border.all(
          color: selected ? primary : AppCard.borderColor(t),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppCard.radius),
        clipBehavior: Clip.antiAlias,
        child: RadioListTile<bool>(
          value: value,
          contentPadding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? primary : t.text,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.45,
                color: t.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
