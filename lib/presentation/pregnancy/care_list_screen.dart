import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/care_event.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
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
    final theme = Theme.of(context);
    final vm = context.watch<PregnancyViewModel>();
    final g = vm.current;
    final bugun = today ?? DateTime.now();

    final olaylar = g == null
        ? const <CareEvent>[]
        : CareGrouping.visible(vm.currentEvents, vm.stage);
    List<CareEvent> grup(CareGroup x) => g == null
        ? const []
        : olaylar.where((e) => CareGrouping.of(e, g, bugun) == x).toList();
    final sablonVar = olaylar.any((e) => !e.isCustom);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: Text(context.tr('care_list_title')),
        actions: [
          if (g != null)
            IconButton(
              key: const Key('care_add'),
              tooltip: context.tr('care_add'),
              icon: const Icon(Icons.add),
              onPressed: () => _ekle(context),
            ),
        ],
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: g == null
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    if (olaylar.isEmpty)
                      _Bos(onEkle: () => _ekle(context))
                    else ...[
                      for (final x in CareGroup.values)
                        if (grup(x).isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Text(
                              context.upper(context.tr('care_group_${x.name}')),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 12,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                                color: t.textMuted,
                              ),
                            ),
                          ),
                          for (final e in grup(x))
                            _Satir(
                              olay: e,
                              gebelik: g,
                              soluk: x == CareGroup.past,
                            ),
                        ],
                    ],
                    if (sablonVar) ...[
                      const SizedBox(height: 20),
                      Text(
                        context.tr(
                          vm.stage == LifeStage.postpartum
                              ? 'care_source_postnatal'
                              : 'care_source_antenatal',
                        ),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          height: 1.5,
                          color: t.textFaint,
                        ),
                      ),
                    ],
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
      builder: (_) => const _EkleSayfasi(),
    );
    if (sonuc == null) return;
    await vm.addCustomEvent(title: sonuc.$1, scheduledAt: sonuc.$2);
  }
}

IconData _ikon(CareCategory c) => switch (c) {
  CareCategory.visit => Icons.medical_services_outlined,
  CareCategory.screening => Icons.biotech_outlined,
  CareCategory.supplement => Icons.medication_outlined,
  CareCategory.vaccine => Icons.vaccines_outlined,
};

class _Satir extends StatelessWidget {
  const _Satir({
    required this.olay,
    required this.gebelik,
    required this.soluk,
  });

  final CareEvent olay;
  final Pregnancy gebelik;
  final bool soluk;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final kosul = olay.conditionKey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => CareEventSheet(olay: olay, gebelik: gebelik),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                olay.done ? Icons.check_circle : _ikon(olay.category),
                size: 22,
                color: olay.done
                    ? t.success
                    : soluk
                    ? t.textFaint
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.careTitle(olay),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: soluk ? t.textMuted : t.text,
                        decoration: olay.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.careWhen(olay, gebelik),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        color: t.textMuted,
                      ),
                    ),
                    if (kosul != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.tr(kosul),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: t.textFaint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (olay.scheduledAt != null && !olay.done)
                Icon(Icons.event_available, size: 18, color: t.textMuted),
            ],
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
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(Icons.event_note_outlined, size: 40, color: t.textFaint),
          const SizedBox(height: 12),
          Text(
            context.tr('care_empty'),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 14,
              height: 1.5,
              color: t.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onEkle,
            icon: const Icon(Icons.add),
            label: Text(context.tr('care_add')),
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.careTitle(widget.olay),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.careWhen(widget.olay, widget.gebelik),
                style: TextStyle(color: t.textMuted),
              ),
              if (kosul != null) ...[
                const SizedBox(height: 4),
                Text(
                  context.tr(kosul),
                  style: TextStyle(
                    color: t.textFaint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
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
                        icon: const Icon(Icons.close),
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
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _kaydet,
                child: Text(context.tr('care_save')),
              ),
              if (widget.olay.isCustom)
                TextButton(
                  onPressed: _sil,
                  child: Text(
                    context.tr('care_delete'),
                    style: TextStyle(color: t.danger),
                  ),
                ),
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
    final r = _randevu;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('care_add_title'),
                controller: _baslik,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr('care_add_title_label'),
                  border: const OutlineInputBorder(),
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
