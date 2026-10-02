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

/// Gebeliği sonlandırma.
///
/// Bu tür uygulamaların en sık batırdığı yer (bkz. `PREGNANCY_MODE.md` §2.6):
///
/// - Sonuç listesi eksiksiz; "belirtmek istemiyorum" eşit bir seçenek.
///   Sebep hiçbir zaman zorunlu değil.
/// - Kutlama, konfeti, "tebrikler" yok — doğum seçilse bile. Ekran hangi
///   sonucun seçileceğini bilmeden açılıyor; aynı ekranı kayıp yaşayan biri
///   de görecek.
/// - Partner paylaşımı açıksa bitiş otomatik bildirilmiyor (v1'de partner
///   gebeliğe dair hiçbir şey görmüyor).
class EndPregnancyScreen extends StatefulWidget {
  const EndPregnancyScreen({super.key});

  @override
  State<EndPregnancyScreen> createState() => _EndPregnancyScreenState();
}

class _EndPregnancyScreenState extends State<EndPregnancyScreen> {
  PregnancyOutcome? _sonuc;
  DateTime _tarih = DateTime.now();
  bool _kaydediliyor = false;

  /// Ekrandaki sıra. "Belirtmek istemiyorum" en sonda ama ayrılmış değil —
  /// diğerleriyle aynı görünümde.
  static const List<PregnancyOutcome> siralama = [
    PregnancyOutcome.birth,
    PregnancyOutcome.miscarriage,
    PregnancyOutcome.stillbirth,
    PregnancyOutcome.ectopic,
    PregnancyOutcome.termination,
    PregnancyOutcome.undisclosed,
  ];

  Future<void> _tarihSec() async {
    final g = context.read<PregnancyViewModel>().current;
    final simdi = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: g?.gestationStart ?? simdi.subtract(const Duration(days: 300)),
      lastDate: simdi,
    );
    if (secilen != null) setState(() => _tarih = secilen);
  }

  Future<void> _onayla() async {
    final sonuc = _sonuc;
    if (sonuc == null || _kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    await context.read<PregnancyViewModel>().end(sonuc, at: _tarih);
    if (!mounted) return;
    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(context.tr('preg_end_title')),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                context.tr('preg_end_intro'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 1.6,
                  color: t.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              RadioGroup<PregnancyOutcome>(
                groupValue: _sonuc,
                onChanged: (v) => setState(() => _sonuc = v),
                child: Column(
                  children: [
                    for (final s in siralama)
                      RadioListTile<PregnancyOutcome>(
                        key: Key('preg_end_${s.name}'),
                        contentPadding: EdgeInsets.zero,
                        value: s,
                        title: Text(context.tr('preg_outcome_${s.name}')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(context.tr('preg_end_date')),
                subtitle: Text(
                  '${_tarih.day} ${context.monthName(_tarih.month)} '
                  '${_tarih.year}',
                ),
                onTap: _tarihSec,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('preg_end_what_happens'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  height: 1.55,
                  color: t.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('preg_end_confirm'),
                onPressed: _sonuc == null || _kaydediliyor ? null : _onayla,
                child: Text(context.tr('preg_end_confirm')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
