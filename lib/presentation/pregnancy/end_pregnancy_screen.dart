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
import 'delete_pregnancy.dart';

/// Gebeliği sonlandırma.
///
/// Bu tür uygulamaların en sık batırdığı yer (bkz. `PREGNANCY_MODE.md` §2.6):
///
/// - Sonuç listesi eksiksiz; "belirtmek istemiyorum" eşit bir seçenek.
///   Sebep hiçbir zaman zorunlu değil.
/// - Kutlama, konfeti, "tebrikler" yok — doğum seçilse bile. Ekran hangi
///   sonucun seçileceğini bilmeden açılıyor; aynı ekranı kayıp yaşayan biri
///   de görecek. Bebek görseli de yok: giriş simgesi nötr bir yaprak.
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

  Future<void> _sil() async {
    final g = context.read<PregnancyViewModel>().current;
    if (g == null) return;
    final router = GoRouter.of(context);
    if (await confirmDeletePregnancy(context, g.id)) {
      router.goNamed(RouteNames.home);
    }
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
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          context.tr('preg_end_title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          // Tembel liste değil: kısa bir form ve onay düğmesi her zaman
          // ağaçta olmalı (kaydırıp görünür kılmak için de).
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Giris(),
                const SizedBox(height: 20),
                RadioGroup<PregnancyOutcome>(
                  groupValue: _sonuc,
                  onChanged: (v) => setState(() => _sonuc = v),
                  child: Column(
                    children: [
                      for (final s in siralama)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SonucSatiri(sonuc: s, secili: _sonuc == s),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _TarihKarti(tarih: _tarih, onTap: _tarihSec),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppCard.borderColor(t)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppIconTile(
                        icon: Icons.inventory_2_outlined,
                        size: 36,
                        circle: true,
                        background: t.surface,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('preg_end_what_happens'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: t.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  key: const Key('preg_end_confirm'),
                  onPressed: _sonuc == null || _kaydediliyor ? null : _onayla,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(context.tr('preg_end_confirm')),
                ),
                const SizedBox(height: 12),
                // Yanlışlıkla eklenmiş kayıt bir sonuç değil; sonlandırmak
                // yerine silinebilmeli.
                TextButton(
                  key: const Key('preg_delete'),
                  onPressed: _kaydediliyor ? null : _sil,
                  style: TextButton.styleFrom(foregroundColor: t.danger),
                  child: Text(
                    context.tr('preg_delete_mistake'),
                    textAlign: TextAlign.center,
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

/// Sakin giriş: nötr simge ve açıklama. Kutlama da, yas da varsayılmıyor.
class _Giris extends StatelessWidget {
  const _Giris();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        gradient: AppGradients.blush(context),
        borderRadius: BorderRadius.circular(AppCard.radius),
        border: Border.all(color: AppCard.borderColor(t)),
      ),
      child: Column(
        children: [
          AppIconTile(
            icon: Icons.spa_outlined,
            size: 52,
            circle: true,
            background: t.surface,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('preg_end_intro'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: t.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir sonuç seçeneği. Hepsi aynı görünümde; hiçbiri önceden seçili değil.
class _SonucSatiri extends StatelessWidget {
  const _SonucSatiri({required this.sonuc, required this.secili});

  final PregnancyOutcome sonuc;
  final bool secili;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final kenar = BorderRadius.circular(AppRadius.lg);

    // Gölge dış kapta; döşeme rengi ve dokunma izi saydam Material'de, yani
    // gölgenin üstünde.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: kenar,
        boxShadow: secili ? null : AppCard.shadow(t),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: RadioListTile<PregnancyOutcome>(
          key: Key('preg_end_${sonuc.name}'),
          value: sonuc,
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 6, 10, 6),
          tileColor: t.surface,
          selectedTileColor: t.brandTint,
          selected: secili,
          shape: RoundedRectangleBorder(
            borderRadius: kenar,
            side: BorderSide(
              color: secili
                  ? theme.colorScheme.primary.withAlpha(90)
                  : AppCard.borderColor(t),
            ),
          ),
          title: Text(
            context.tr('preg_outcome_${sonuc.name}'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: secili ? theme.colorScheme.primary : t.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bitiş tarihi; dokununca takvim.
class _TarihKarti extends StatelessWidget {
  const _TarihKarti({required this.tarih, required this.onTap});

  final DateTime tarih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      decoration: AppCard.decoration(t),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppIconTile(
                  icon: Icons.event_outlined,
                  size: 44,
                  circle: true,
                  background: t.brandTint,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSectionLabel(context.tr('preg_end_date')),
                      const SizedBox(height: 2),
                      Text(
                        context.dayMonthYear(tarih),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_calendar_outlined,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
