import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
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
  const PregnancySetupScreen({super.key, @visibleForTesting this.today});

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
    context.goNamed(RouteNames.home);
  }

  String _tarih(DateTime d) =>
      '${d.day} ${context.monthName(d.month)} ${d.year}';

  @override
  Widget build(BuildContext context) {
    // Takvim yüklenince ön dolu tarih ve döngü uzunluğu güncellensin.
    context.watch<CalendarViewModel>();
    final t = context.tokens;
    final theme = Theme.of(context);
    final g = _onizleme;
    final ga = g?.gestationOn(_bugun);
    final secili = _kaynak == _Kaynak.lmp ? _sat : _edd;

    TextStyle? baslik() => theme.textTheme.labelLarge?.copyWith(
      fontSize: 12,
      letterSpacing: 1.4,
      fontWeight: FontWeight.w700,
      color: t.textMuted,
    );
    TextStyle? govde([Color? c]) => theme.textTheme.labelLarge?.copyWith(
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              // ── 1. Tarih ──
              Text(
                context.upper(context.tr('preg_setup_date_section')),
                style: baslik(),
              ),
              const SizedBox(height: 10),
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
                onSelectionChanged: (s) => setState(() => _kaynak = s.first),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('preg_setup_pick_date'),
                onPressed: _tarihSec,
                icon: const Icon(Icons.event_outlined, size: 20),
                label: Text(
                  secili == null
                      ? context.tr(
                          _kaynak == _Kaynak.lmp
                              ? 'preg_setup_pick_lmp'
                              : 'preg_setup_pick_due',
                        )
                      : _tarih(secili),
                ),
              ),
              const SizedBox(height: 12),

              if (g != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'preg_setup_due_result',
                          params: {'date': _tarih(g.estimatedDueDate)},
                        ),
                        style: govde()?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (ga != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.gestationSentence(ga),
                          style: govde(t.textMuted),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          _kaynak == _Kaynak.lmp
                              ? 'preg_setup_due_method_lmp'
                              : 'preg_setup_due_method_clinician',
                          params: {'n': '$_donguUzunlugu'},
                        ),
                        style: govde(t.textMuted),
                      ),
                    ],
                  ),
                ),
                if (!_gecerli) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.tr('preg_setup_due_passed'),
                    style: govde(t.warning),
                  ),
                ],
              ],

              const SizedBox(height: 28),

              // ── 2. Bakım takvimi ──
              Text(
                context.upper(context.tr('preg_setup_care_section')),
                style: baslik(),
              ),
              const SizedBox(height: 6),
              RadioGroup<bool>(
                groupValue: _turkiyeSablonu,
                onChanged: (v) => setState(() => _turkiyeSablonu = v),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: true,
                      title: Text(
                        context.tr('preg_setup_care_tr'),
                        style: govde(),
                      ),
                      subtitle: Text(
                        context.tr('preg_setup_care_tr_body'),
                        style: govde(t.textMuted),
                      ),
                    ),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      value: false,
                      title: Text(
                        context.tr('preg_setup_care_own'),
                        style: govde(),
                      ),
                      subtitle: Text(
                        context.tr('preg_setup_care_own_body'),
                        style: govde(t.textMuted),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 3. Ne değişecek ──
              Text(
                context.upper(context.tr('preg_setup_changes_section')),
                style: baslik(),
              ),
              const SizedBox(height: 10),
              for (final k in const [
                'preg_setup_change_predictions',
                'preg_setup_change_bleeding',
                'preg_setup_change_reminders',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: t.textMuted),
                      const SizedBox(width: 10),
                      Expanded(child: Text(context.tr(k), style: govde())),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              FilledButton(
                key: const Key('preg_setup_start'),
                onPressed: _gecerli && !_kaydediliyor ? _baslat : null,
                child: Text(context.tr('preg_setup_start')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
