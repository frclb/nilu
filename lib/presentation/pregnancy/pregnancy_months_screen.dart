import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
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
        centerTitle: false,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          context.tr('preg_months_title'),
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
          child: g == null || !g.isActive
              ? const SizedBox.shrink()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (ga != null && suanki != null)
                      _Ozet(gebelik: g, ga: ga, ay: suanki),
                    for (final ay in PregnancyMonth.all) ...[
                      if (ay.number == 1 || ay.number == 4 || ay.number == 7)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 24,
                            bottom: 10,
                            left: 4,
                          ),
                          child: Text(
                            context.upper(
                              context.tr(
                                'preg_trimester_label',
                                params: {'n': '${ay.trimester.index + 1}'},
                              ),
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                              color: suanki?.trimester == ay.trimester
                                  ? t.secondary
                                  : t.textMuted,
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
                    const SizedBox(height: 14),
                    _DogumKarti(gebelik: g, bugun: bugun),
                  ],
                ),
        ),
      ),
    );
  }
}

enum _Durum { gecti, simdi, yaklasan }

/// Üstteki özet: hangi ay, kaçıncı hafta, yolun ne kadarı geride.
class _Ozet extends StatelessWidget {
  const _Ozet({required this.gebelik, required this.ga, required this.ay});

  final Pregnancy gebelik;
  final GestationalAge ga;
  final PregnancyMonth ay;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final ilerleme = (ga.totalDays / Pregnancy.termDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: AppGradients.blush(context),
        borderRadius: BorderRadius.circular(AppCard.radius),
        border: Border.all(color: AppCard.borderColor(t)),
        boxShadow: AppCard.shadow(t),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppTag(
                    label: context.upper(
                      '${context.monthLabel(ay.number)} · '
                      '${context.tr('preg_trimester_label', params: {'n': '${ay.trimester.index + 1}'})}',
                    ),
                    dotColor: t.secondary,
                    background: t.surface,
                    foreground: t.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                // Hekimin kullandığı gösterim: tamamlanan hafta + gün.
                '${ga.weeks}+${ga.days}',
                semanticsLabel: context.gestationSentence(ga),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: t.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.gestationSentence(ga),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              height: 1.15,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          // İlerleme: 280 günün ne kadarı geçti. Süs; sayısı yukarıda yazılı.
          ExcludeSemantics(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: ilerleme,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final bas = ay.startIn(gebelik);
    final son = ay.endIn(gebelik);
    String tarih(DateTime d) => '${d.day} ${context.monthName(d.month)}';
    final haftalar = context.tr(
      'preg_month_weeks',
      params: {'a': '${ay.fromWeek}', 'b': '${ay.toWeek}'},
    );
    final tarihler = '${tarih(bas)} – ${tarih(son)}';

    if (durum == _Durum.simdi) {
      return _SimdikiAy(
        ay: ay,
        haftalar: haftalar,
        tarihler: tarihler,
        kalemler: kalemler,
      );
    }

    final gecti = durum == _Durum.gecti;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        key: Key('preg_month_${ay.number}'),
        padding: const EdgeInsets.all(16),
        decoration: AppCard.decoration(t),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconTile(
              icon: gecti ? Icons.check_rounded : Icons.schedule_rounded,
              size: 36,
              circle: true,
              background: gecti ? t.secondaryTint : t.surfaceAlt,
              color: gecti ? t.secondary : t.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          context.monthLabel(ay.number),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: gecti ? t.textMuted : t.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sağa yaslı; büyük yazıda sığmazsa alt satıra iner.
                      Flexible(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            haftalar,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: t.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tarihler,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Kalemler(kalemler: kalemler, soluk: gecti),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İçinde bulunulan ay: üstte degrade şerit, büyük başlık, kontroller
/// tül bir kutuda.
class _SimdikiAy extends StatelessWidget {
  const _SimdikiAy({
    required this.ay,
    required this.haftalar,
    required this.tarihler,
    required this.kalemler,
  });

  final PregnancyMonth ay;
  final String haftalar;
  final String tarihler;
  final List<CareEvent> kalemler;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Container(
        key: Key('preg_month_${ay.number}'),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppCard.radius),
          border: Border.all(color: t.secondary.withAlpha(70)),
          boxShadow: AppShadows.floating(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: AppGradients.primary(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppTag(
                        label: context.upper(context.tr('care_group_now')),
                        background: t.secondaryTint,
                        foreground: t.secondary,
                      ),
                      Text(
                        haftalar,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.monthLabel(ay.number),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      height: 1.15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tarihler,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    decoration: BoxDecoration(
                      color: t.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: _Kalemler(kalemler: kalemler, soluk: false),
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

/// Ayın kontrolleri; yapılanlar işaretli.
class _Kalemler extends StatelessWidget {
  const _Kalemler({required this.kalemler, required this.soluk});

  final List<CareEvent> kalemler;

  /// Geçen ay: yapılmamış kalemler sönük.
  final bool soluk;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    if (kalemler.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          context.tr('preg_month_empty'),
          style: theme.textTheme.bodySmall?.copyWith(color: t.textFaint),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in kalemler)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  e.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: e.done ? t.secondary : t.textFaint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.careTitle(e),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      color: soluk && !e.done ? t.textMuted : t.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tahmini doğum tarihi ve kalan gün.
class _DogumKarti extends StatelessWidget {
  const _DogumKarti({required this.gebelik, required this.bugun});

  final Pregnancy gebelik;
  final DateTime bugun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    final edd = gebelik.estimatedDueDate;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: on.withAlpha(36),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_outlined, size: 22, color: on),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(
                    'preg_due_caption',
                    params: {
                      'date':
                          '${edd.day} ${context.monthName(edd.month)} '
                          '${edd.year}',
                    },
                  ),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    height: 1.2,
                    color: on,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.dueCountdown(edd.daysSince(bugun)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: on.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
