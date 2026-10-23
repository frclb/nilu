import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/care_event.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/pregnancy_month.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../widgets/profile_avatar_button.dart';
import 'care_grouping.dart';
import 'care_text.dart';

/// İzlemler, taramalar, destekler ve kullanıcının kendi randevuları.
///
/// Uygulamanın işi takvimi **hatırlatmak**, dayatmak değil: her kalem
/// düzenlenebilir, kendi randevusu eklenebilir, ve şablonun kaynağı ekranda
/// yazılı. Kullanıcının gerçek takvimi hekiminden gelir.
class CareListScreen extends StatelessWidget {
  const CareListScreen({super.key, @visibleForTesting this.today});

  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final vm = context.watch<PregnancyViewModel>();
    final g = vm.current;
    final bugun = today ?? DateTime.now();
    // Gebelik ve lohusalıkta sekme kökü; panodan ayrı rotayla da açılıyor.
    final pushed = Navigator.of(context).canPop();

    final olaylar = g == null
        ? const <CareEvent>[]
        : CareGrouping.visible(vm.currentEvents, vm.stage);
    List<CareEvent> grup(CareGroup x) => g == null
        ? const []
        : olaylar.where((e) => CareGrouping.of(e, g, bugun) == x).toList();
    final sablonVar = olaylar.any((e) => !e.isCustom);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: AppContentWidth(
          child: Column(
            children: [
              _TopBar(
                pushed: pushed,
                hasPregnancy: g != null,
                onAdd: () => _ekle(context),
              ),
              Expanded(
                child: g == null
                    ? const SizedBox.shrink()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          _Hero(gebelik: g, stage: vm.stage, bugun: bugun),
                          if (olaylar.isEmpty)
                            _Bos(onEkle: () => _ekle(context))
                          else ...[
                            for (final x in CareGroup.values)
                              if (grup(x).isNotEmpty) ...[
                                _GrupBasligi(grup: x, sayi: grup(x).length),
                                for (final e in grup(x))
                                  _Satir(olay: e, gebelik: g, grup: x),
                              ],
                          ],
                          if (sablonVar) ...[
                            const SizedBox(height: 16),
                            _Kaynak(
                              metin: context.tr(
                                vm.stage == LifeStage.postpartum
                                    ? 'care_source_postnatal'
                                    : 'care_source_antenatal',
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ekle(BuildContext context) async {
    final vm = context.read<PregnancyViewModel>();
    final sonuc = await showModalBottomSheet<(String, DateTime?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _EkleSayfasi(),
    );
    if (sonuc == null) return;
    await vm.addCustomEvent(title: sonuc.$1, scheduledAt: sonuc.$2);
  }
}

/// Üst çubuk: serif başlık, özet ve ekle; sekme kökünde profil.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.pushed,
    required this.hasPregnancy,
    required this.onAdd,
  });

  final bool pushed;
  final bool hasPregnancy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SizedBox(
      height: 60,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(pushed ? 4 : 20, 0, 12, 0),
        child: Row(
          children: [
            if (pushed) BackButton(color: primary),
            Expanded(
              // Büyük yazıda başlık kısalıyor; düğmeler yerinde kalıyor.
              child: Text(
                context.tr('care_list_title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  color: primary,
                ),
              ),
            ),
            if (hasPregnancy) ...[
              IconButton(
                key: const Key('care_summary_open'),
                tooltip: context.tr('care_summary_title'),
                icon: Icon(Icons.summarize_outlined, color: primary),
                onPressed: () => context.pushNamed(RouteNames.careSummary),
              ),
              IconButton(
                key: const Key('care_add'),
                tooltip: context.tr('care_add'),
                icon: Icon(Icons.add_rounded, color: primary),
                onPressed: onAdd,
              ),
            ],
            if (!pushed) const ProfileAvatarButton(),
          ],
        ),
      ),
    );
  }
}

/// Neredesin: gebelik haftası ya da lohusalık günü. Randevuların hangi
/// döneme göre sıralandığını bir bakışta söylüyor.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.gebelik,
    required this.stage,
    required this.bugun,
  });

  final Pregnancy gebelik;
  final LifeStage stage;
  final DateTime bugun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;

    final String etiket;
    final String baslik;
    final String alt;
    if (stage == LifeStage.postpartum) {
      final dogum = gebelik.endedAt;
      if (dogum == null) return const SizedBox.shrink();
      final gun = bugun.daysSince(dogum);
      etiket = context.tr('pp_label');
      baslik = gun == 0
          ? context.tr('pp_day_birth')
          : context.tr('pp_day', params: {'n': '$gun'});
      alt = context.tr(
        'pp_days_total',
        params: {'n': '${LifeStage.postpartumDays}'},
      );
    } else {
      final ga = gebelik.gestationOn(bugun);
      final trimester = gebelik.trimesterOn(bugun);
      if (ga == null || trimester == null) return const SizedBox.shrink();
      etiket =
          '${context.monthLabel(PregnancyMonth.of(ga).number)} · '
          '${context.tr('preg_trimester_label', params: {'n': '${trimester.index + 1}'})}';
      baslik = context.gestationSentence(ga);
      alt = context.dueCountdown(gebelik.estimatedDueDate.daysSince(bugun));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppGradients.primary(context).colors,
            stops: const [0, 0.55, 1],
          ),
          borderRadius: BorderRadius.circular(AppCard.radius),
          boxShadow: AppShadows.floating(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: on.withAlpha(32),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                context.upper(etiket),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: on,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              baslik,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                height: 1.2,
                color: on,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              alt,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: on.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrupBasligi extends StatelessWidget {
  const _GrupBasligi({required this.grup, required this.sayi});

  final CareGroup grup;
  final int sayi;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final simdi = grup == CareGroup.now;
    final renk = simdi ? t.secondary : t.textMuted;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.upper(context.tr('care_group_${grup.name}')),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: renk,
              ),
            ),
          ),
          AppTag(
            label: '$sayi',
            background: simdi ? t.secondaryTint : t.surfaceAlt,
            foreground: simdi ? t.secondary : t.textMuted,
          ),
        ],
      ),
    );
  }
}

IconData _ikon(CareCategory c) => switch (c) {
  CareCategory.visit => Icons.medical_services_outlined,
  CareCategory.screening => Icons.biotech_outlined,
  CareCategory.supplement => Icons.medication_outlined,
  CareCategory.vaccine => Icons.vaccines_outlined,
};

/// Kalem türünün tülü ve rengi.
(Color, Color) _ton(AppTokens t, CareCategory c) => switch (c) {
  CareCategory.visit => (t.secondaryTint, t.secondary),
  CareCategory.screening => (t.ovulationTint, t.ovulationText),
  CareCategory.supplement => (t.accentTint, t.accent),
  CareCategory.vaccine => (t.flowTint, t.flowText),
};

class _Satir extends StatelessWidget {
  const _Satir({required this.olay, required this.gebelik, required this.grup});

  final CareEvent olay;
  final Pregnancy gebelik;
  final CareGroup grup;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final kosul = olay.conditionKey;
    final soluk = grup == CareGroup.past;
    final simdi = grup == CareGroup.now;
    final (tul, renk) = _ton(t, olay.category);

    final Widget simge;
    if (olay.done) {
      simge = AppIconTile(
        icon: Icons.check_rounded,
        size: 44,
        circle: true,
        background: t.success.withAlpha(30),
        color: t.success,
      );
    } else if (soluk) {
      simge = AppIconTile(
        icon: _ikon(olay.category),
        size: 44,
        background: t.surfaceAlt,
        color: t.textFaint,
      );
    } else {
      simge = AppIconTile(
        icon: _ikon(olay.category),
        size: 44,
        background: tul,
        color: renk,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: AppCard.decoration(t),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => CareEventSheet(olay: olay, gebelik: gebelik),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  simge,
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.careTitle(olay),
                          style: soluk
                              ? theme.textTheme.titleMedium?.copyWith(
                                  color: t.textMuted,
                                )
                              : theme.textTheme.headlineSmall?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  color: t.text,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.careWhen(olay, gebelik),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: simdi ? t.secondary : t.textMuted,
                          ),
                        ),
                        if (kosul != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.tr(kosul),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (olay.scheduledAt != null && !olay.done) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.event_available_outlined,
                      size: 20,
                      color: t.secondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bos extends StatelessWidget {
  const _Bos({required this.onEkle});

  final VoidCallback onEkle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            AppIconTile(
              icon: Icons.event_note_outlined,
              size: 64,
              circle: true,
              background: t.brandTint,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('care_empty'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onEkle,
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('care_add')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Şablonun kaynağı: kullanıcı takvimin nereden geldiğini görebilmeli.
class _Kaynak extends StatelessWidget {
  const _Kaynak({required this.metin});

  final String metin;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppCard.borderColor(t)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kaynak simgesi; "onaylı" rozeti değil: Bakanlık uygulamayı
          // onaylamadı, takvim onun rehberine göre hazırlandı.
          Icon(Icons.menu_book_outlined, size: 20, color: t.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              metin,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.5, color: t.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir kalemin düzenlenmesi: yapıldı, randevu tarihi/saati, not, hatırlatma.
class CareEventSheet extends StatefulWidget {
  const CareEventSheet({super.key, required this.olay, required this.gebelik});

  final CareEvent olay;
  final Pregnancy gebelik;

  @override
  State<CareEventSheet> createState() => _CareEventSheetState();
}

class _CareEventSheetState extends State<CareEventSheet> {
  late bool _yapildi = widget.olay.done;
  late bool _hatirlat = widget.olay.reminderOn;
  late DateTime? _randevu = widget.olay.scheduledAt;
  late final TextEditingController _not = TextEditingController(
    text: widget.olay.note ?? '',
  );

  @override
  void dispose() {
    _not.dispose();
    super.dispose();
  }

  Future<void> _randevuSec() async {
    final simdi = DateTime.now();
    final gun = await showDatePicker(
      context: context,
      initialDate: _randevu ?? simdi,
      firstDate: simdi.subtract(const Duration(days: 365)),
      lastDate: simdi.add(const Duration(days: 400)),
    );
    if (gun == null || !mounted) return;
    final saat = await showTimePicker(
      context: context,
      initialTime: _randevu == null
          ? const TimeOfDay(hour: 10, minute: 0)
          : TimeOfDay.fromDateTime(_randevu!),
    );
    if (saat == null) return;
    setState(
      () => _randevu = DateTime(
        gun.year,
        gun.month,
        gun.day,
        saat.hour,
        saat.minute,
      ),
    );
  }

  Future<void> _kaydet() async {
    final vm = context.read<PregnancyViewModel>();
    final not = _not.text.trim();
    await vm.saveEvent(
      widget.olay.copyWith(
        done: _yapildi,
        reminderOn: _hatirlat,
        scheduledAt: _randevu,
        clearScheduledAt: _randevu == null,
        note: not,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _sil() async {
    final vm = context.read<PregnancyViewModel>();
    await vm.removeEvent(widget.olay.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final kosul = widget.olay.conditionKey;
    final (tul, renk) = _ton(t, widget.olay.category);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconTile(
                    icon: _ikon(widget.olay.category),
                    size: 48,
                    background: tul,
                    color: renk,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.careTitle(widget.olay),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 24,
                            height: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.careWhen(widget.olay, widget.gebelik),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: t.secondary,
                          ),
                        ),
                        if (kosul != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.tr(kosul),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('care_done')),
                value: _yapildi,
                onChanged: (v) => setState(() => _yapildi = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(
                  _randevu == null
                      ? context.tr('care_set_appointment')
                      : context.careWhen(
                          widget.olay.copyWith(scheduledAt: _randevu),
                          widget.gebelik,
                        ),
                ),
                trailing: _randevu == null
                    ? null
                    : IconButton(
                        tooltip: context.tr('care_clear_appointment'),
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() => _randevu = null),
                      ),
                onTap: _randevuSec,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('care_remind')),
                value: _hatirlat,
                onChanged: (v) => setState(() => _hatirlat = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _not,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: context.tr('care_note'),
                  hintText: context.tr('care_note_hint'),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _kaydet,
                child: Text(context.tr('care_save')),
              ),
              if (widget.olay.isCustom) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _sil,
                  style: TextButton.styleFrom(
                    foregroundColor: t.danger,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(context.tr('care_delete')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EkleSayfasi extends StatefulWidget {
  const _EkleSayfasi();

  @override
  State<_EkleSayfasi> createState() => _EkleSayfasiState();
}

class _EkleSayfasiState extends State<_EkleSayfasi> {
  final _baslik = TextEditingController();
  DateTime? _randevu;

  @override
  void dispose() {
    _baslik.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final simdi = DateTime.now();
    final gun = await showDatePicker(
      context: context,
      initialDate: _randevu ?? simdi,
      firstDate: simdi.subtract(const Duration(days: 30)),
      lastDate: simdi.add(const Duration(days: 400)),
    );
    if (gun == null || !mounted) return;
    final saat = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (saat == null) return;
    setState(
      () => _randevu = DateTime(
        gun.year,
        gun.month,
        gun.day,
        saat.hour,
        saat.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _randevu;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('care_add'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('care_add_title'),
                controller: _baslik,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr('care_add_title_label'),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _tarihSec,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  r == null
                      ? context.tr('care_set_appointment')
                      : '${r.day}.${r.month}.${r.year} · '
                            '${r.hour.toString().padLeft(2, '0')}:'
                            '${r.minute.toString().padLeft(2, '0')}',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('care_add_save'),
                onPressed: _baslik.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop((_baslik.text.trim(), _randevu)),
                child: Text(context.tr('care_save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
