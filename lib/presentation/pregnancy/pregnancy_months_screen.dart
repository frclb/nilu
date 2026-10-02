import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/care_event.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/pregnancy_month.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import 'care_text.dart';

/// Gebeliğin dokuz ayı: hangi ay hangi haftalar, takvimde hangi tarihler,
/// o ayda hangi kontroller var ve hangileri yapıldı.
///
/// Editoryal içerik ("bu ay bebeğin…") yok; v1'de bilinçli olarak dışarıda
/// (bkz. PREGNANCY_MODE.md §6). Ekran yalnızca yapısal bilgi gösteriyor:
/// aylar uzun bir süreç ve kullanıcı nerede olduğunu, sırada ne olduğunu
/// ay ay görebilmeli.
class PregnancyMonthsScreen extends StatelessWidget {
  const PregnancyMonthsScreen({super.key, @visibleForTesting this.today});

  final DateTime? today;

  /// [e] gebeliğin hangi ayına düşüyor? Randevusu varsa randevusu, yoksa
  /// penceresinin başı. Lohusa kalemleri ve tarihsiz kendi kalemleri hiçbir
  /// aya düşmüyor.
  static PregnancyMonth? monthOf(CareEvent e, Pregnancy p) {
    if (e.anchor == CareAnchor.postpartum && e.scheduledAt == null) {
      return null;
    }
    final tarih = e.scheduledAt ?? e.windowStart(p);
    if (tarih == null) return null;
    for (final ay in PregnancyMonth.all) {
      if (ay.contains(p, tarih)) return ay;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final vm = context.watch<PregnancyViewModel>();
    final g = vm.current;
    final bugun = today ?? DateTime.now();
    final ga = g?.gestationOn(bugun);
    final suanki = ga == null ? null : PregnancyMonth.of(ga);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(context.tr('preg_months_title')),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: g == null || !g.isActive
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    for (final ay in PregnancyMonth.all) ...[
                      if (ay.number == 1 || ay.number == 4 || ay.number == 7)
                        Padding(
                          padding: EdgeInsets.only(
                            top: ay.number == 1 ? 4 : 20,
                            bottom: 8,
                          ),
                          child: Text(
                            context.upper(
                              context.tr(
                                'preg_trimester_label',
                                params: {'n': '${ay.trimester.index + 1}'},
                              ),
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 12,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                              color: t.textMuted,
                            ),
                          ),
                        ),
                      _AyKarti(
                        ay: ay,
                        gebelik: g,
                        kalemler: [
                          for (final e in vm.currentEvents)
                            if (monthOf(e, g)?.number == ay.number) e,
                        ],
                        durum: suanki == null
                            ? _Durum.yaklasan
                            : ay.number < suanki.number
                            ? _Durum.gecti
                            : ay.number == suanki.number
                            ? _Durum.simdi
                            : _Durum.yaklasan,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

enum _Durum { gecti, simdi, yaklasan }

class _AyKarti extends StatelessWidget {
  const _AyKarti({
    required this.ay,
    required this.gebelik,
    required this.kalemler,
    required this.durum,
  });

  final PregnancyMonth ay;
  final Pregnancy gebelik;
  final List<CareEvent> kalemler;
  final _Durum durum;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final simdi = durum == _Durum.simdi;
    final bas = ay.startIn(gebelik);
    final son = ay.endIn(gebelik);
    String tarih(DateTime d) => '${d.day} ${context.monthName(d.month)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: Key('preg_month_${ay.number}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: simdi ? theme.colorScheme.primary : t.border,
            width: simdi ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: durum == _Durum.yaklasan
                    ? Colors.transparent
                    : theme.colorScheme.primary.withAlpha(simdi ? 255 : 90),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Text(
                '${ay.number}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: durum == _Durum.yaklasan
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.monthLabel(ay.number),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: durum == _Durum.gecti ? t.textMuted : t.text,
                          ),
                        ),
                      ),
                      if (simdi)
                        Text(
                          context.upper(context.tr('care_group_now')),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${context.tr('preg_month_weeks', params: {'a': '${ay.fromWeek}', 'b': '${ay.toWeek}'})}'
                    ' · ${tarih(bas)} – ${tarih(son)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (kalemler.isEmpty)
                    Text(
                      context.tr('preg_month_empty'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        color: t.textFaint,
                      ),
                    )
                  else
                    for (final e in kalemler)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              e.done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: e.done ? t.success : t.textFaint,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.careTitle(e),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: durum == _Durum.gecti && !e.done
                                      ? t.textMuted
                                      : t.text,
                                ),
                              ),
                            ),
                          ],
                        ),
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
