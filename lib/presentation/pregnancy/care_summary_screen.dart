import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/models/log_vocabulary.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/vitals.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/services/pregnancy_summary.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../domain/view_models/subscription_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../calendar/view_models/calendar_view_model.dart';
import 'care_text.dart';

/// Randevuya götürülecek özet (Faz 2).
///
/// Ekranda görmek herkese açık: muayenede telefondan okunuyor ve içinde
/// güvenlikle ilgili bilgi var (gebelikte kanamalar, yüksek tansiyonlar).
/// Dosya olarak paylaşmak, mevcut hekim raporu gibi Premium
/// (`PremiumGate.canExportReports`; bkz. PREGNANCY_MODE.md §3).
///
/// Ekran ve paylaşılan metin aynı bölüm listesinden üretiliyor: ayrı
/// yazılsaydı ekranda görülenle hekime giden dosya zamanla ayrışırdı.
///
/// [pregnancyId] verilince biten o gebeliğin kaydı (geçmiş gebelikler):
/// aynı bölümler, gebeliğin kendi döneminden (bkz. `PregnancySummary.past`).
class CareSummaryScreen extends StatelessWidget {
  const CareSummaryScreen({
    super.key,
    this.pregnancyId,
    @visibleForTesting this.today,
  });

  /// Biten bir gebeliğin kimliği; `null` ise o anki gebelik ya da
  /// lohusalık için randevu özeti.
  final String? pregnancyId;

  final DateTime? today;

  /// Paylaşım. Testte sistem paylaşım sayfası yerine konuyor.
  static Future<void> Function(String metin, String dosyaAdi) share = _paylas;

  static Future<void> _paylas(String metin, String dosyaAdi) async {
    // Geçici dizin: paylaşım bittikten sonra sistem temizliyor, sağlık
    // verisi cihazda kalıcı bir yerde birikmiyor.
    final dizin = await getTemporaryDirectory();
    final dosya = File('${dizin.path}/$dosyaAdi');
    await dosya.writeAsString(metin);
    await SharePlus.instance.share(ShareParams(files: [XFile(dosya.path)]));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final vm = context.watch<PregnancyViewModel>();
    final takvim = context.watch<CalendarViewModel>();
    final premium = context.watch<SubscriptionViewModel>().isPremium;
    final bugun = today ?? DateTime.now();
    final gecmis = pregnancyId != null;

    final PregnancySummary? ozet;
    if (gecmis) {
      final g = vm.pastPregnancies
          .where((p) => p.id == pregnancyId)
          .firstOrNull;
      ozet = g == null
          ? null
          : PregnancySummary.past(
              pregnancy: g,
              events: vm.eventsOf(g),
              logs: takvim.dailyLogs,
            );
    } else {
      final g = vm.current;
      ozet = g == null
          ? null
          : PregnancySummary.build(
              pregnancy: g,
              stage: vm.stage,
              events: vm.currentEvents,
              logs: takvim.dailyLogs,
              today: bugun,
            );
    }
    // Geçmiş kaydın dosyası gebeliğin bittiği günle adlanıyor: birden fazla
    // gebeliğin dosyası birbirine karışmasın.
    final dosyaGunu = (gecmis ? ozet?.pregnancy.endedAt : null) ?? bugun;
    final bolumler = ozet == null
        ? const <SummarySection>[]
        : sections(context, ozet);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(
          context.tr(gecmis ? 'past_preg_record_title' : 'care_summary_title'),
        ),
        actions: [
          if (ozet != null)
            IconButton(
              key: const Key('care_summary_share'),
              tooltip: context.tr('care_summary_share'),
              icon: const Icon(Icons.ios_share),
              onPressed: () {
                if (!PremiumGate.canExportReports(isPremium: premium)) {
                  context.pushNamed(RouteNames.premium);
                  return;
                }
                final d = dosyaGunu;
                share(
                  plainText(context, bolumler, bugun, past: gecmis),
                  '${gecmis ? 'gebelik-kaydi' : 'randevu-ozeti'}-${d.year}'
                  '${d.month.toString().padLeft(2, '0')}'
                  '${d.day.toString().padLeft(2, '0')}.txt',
                );
              },
            ),
        ],
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                context.tr(gecmis ? 'past_preg_intro' : 'care_summary_intro'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: t.textMuted,
                ),
              ),
              for (final b in bolumler) ...[
                const SizedBox(height: 20),
                Text(
                  context.upper(b.title),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                    color: t.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                for (final s in b.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (s.flagged) ...[
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: t.warning,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            s.text,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: s.flagged
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: s.muted ? t.textMuted : t.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bölümler ───

  /// Ekranda ve paylaşılan metinde aynı içerik.
  @visibleForTesting
  static List<SummarySection> sections(
    BuildContext context,
    PregnancySummary o,
  ) {
    String tamTarih(DateTime d) =>
        '${d.day} ${context.monthName(d.month)} ${d.year}';
    // Geçmiş kayıt yıllar sonra okunabilir ve gebelik iki takvim yılına
    // yayılıyor: yılsız "12 Mart" hangi yılın olduğunu söylemez.
    String tarih(DateTime d) =>
        o.past ? tamTarih(d) : '${d.day} ${context.monthName(d.month)}';
    final yok = SummaryLine(context.tr('care_summary_none'), muted: true);
    final g = o.pregnancy;
    final lohusa = o.stage == LifeStage.postpartum;

    // Gebelik ya da doğum.
    final ga = o.gestation;
    final dogum = g.endedAt;
    final gunSonra = o.daysSinceBirth;
    final sonHafta = g.gestationAtEnd;
    final kimlik = SummarySection(
      context.tr(
        lohusa
            ? 'care_summary_section_postpartum'
            : 'care_summary_section_pregnancy',
      ),
      [
        if (o.past) ...[
          SummaryLine(
            context.tr(
              'care_summary_due',
              params: {'date': tamTarih(g.estimatedDueDate)},
            ),
          ),
          SummaryLine(
            context.tr(
              g.dueDateFromClinician
                  ? 'care_summary_due_clinician'
                  : 'care_summary_due_lmp',
            ),
            muted: true,
          ),
          if (g.lmp != null)
            SummaryLine(
              context.tr(
                'care_summary_lmp',
                params: {'date': tamTarih(g.lmp!)},
              ),
            ),
          if (dogum != null) SummaryLine(_bitis(context, g, tamTarih(dogum))),
          if (sonHafta != null)
            SummaryLine(
              context.tr(
                'past_preg_weeks_at_end',
                params: {'ga': '${sonHafta.weeks}+${sonHafta.days}'},
              ),
            ),
        ] else if (lohusa && dogum != null) ...[
          SummaryLine(
            context.tr('care_summary_birth', params: {'date': tamTarih(dogum)}),
          ),
          if (gunSonra != null)
            SummaryLine(
              context.tr('care_summary_pp_day', params: {'n': '$gunSonra'}),
            ),
        ] else ...[
          if (ga != null) SummaryLine(context.gestationSentence(ga)),
          SummaryLine(
            context.tr(
              'care_summary_due',
              params: {'date': tamTarih(g.estimatedDueDate)},
            ),
          ),
          SummaryLine(
            context.tr(
              g.dueDateFromClinician
                  ? 'care_summary_due_clinician'
                  : 'care_summary_due_lmp',
            ),
            muted: true,
          ),
          if (g.lmp != null)
            SummaryLine(
              context.tr(
                'care_summary_lmp',
                params: {'date': tamTarih(g.lmp!)},
              ),
            ),
        ],
      ],
    );

    final tansiyon = SummarySection(context.tr('care_summary_section_bp'), [
      if (o.bloodPressures.isEmpty)
        yok
      else ...[
        SummaryLine(
          context.tr(
            'care_summary_bp_high_count',
            params: {
              'high': '${o.highBloodPressureCount}',
              'total': '${o.bloodPressureCount}',
            },
          ),
          flagged: o.highBloodPressureCount > 0,
        ),
        for (final r in o.bloodPressures)
          SummaryLine(
            '${tarih(r.date)} — ${r.systolic}/${r.diastolic} mmHg',
            flagged: r.level != BloodPressureLevel.normal,
          ),
      ],
    ]);

    final ilk = o.firstWeight;
    final son = o.lastWeight;
    final degisim = o.weightChange;
    final kilo = SummarySection(context.tr('care_summary_section_weight'), [
      if (son == null)
        yok
      else ...[
        if (ilk != null && degisim != null)
          SummaryLine(
            context.tr(
              'care_summary_weight_first',
              params: {'kg': _sayi(context, ilk.kg), 'date': tarih(ilk.date)},
            ),
          ),
        SummaryLine(
          context.tr(
            'care_summary_weight_last',
            params: {'kg': _sayi(context, son.kg), 'date': tarih(son.date)},
          ),
        ),
        if (degisim != null)
          SummaryLine(
            context.tr(
              'care_summary_weight_change',
              params: {
                'kg': '${degisim > 0 ? '+' : ''}${_sayi(context, degisim)}',
              },
            ),
          ),
      ],
    ]);

    final kanama = SummarySection(
      context.tr(
        lohusa
            ? 'care_summary_section_lochia'
            : 'care_summary_section_bleeding',
      ),
      [
        if (o.flowDays.isEmpty)
          yok
        else
          for (final f in o.flowDays)
            SummaryLine(
              '${tarih(f.date)} — ${context.tr(LogVocabulary.flowKey(f.flow))}',
              // Gebelikte her kanama hekime söylenmeli (Bakanlık listesi).
              flagged: !lohusa,
            ),
      ],
    );

    final belirtiler = SummarySection(
      context.tr(
        o.past ? 'past_preg_section_symptoms' : 'care_summary_section_symptoms',
      ),
      [
        if (o.recentSymptoms.isEmpty)
          yok
        else
          SummaryLine(
            o.recentSymptoms
                .map(
                  (b) =>
                      '${context.tr(LogVocabulary.symptomKey(b.code))} '
                      '(${b.days})',
                )
                .join(', '),
          ),
      ],
    );

    final kontroller = SummarySection(context.tr('care_summary_section_care'), [
      if (o.doneCare.isEmpty && o.upcomingCare.isEmpty)
        yok
      else ...[
        if (o.doneCare.isNotEmpty) ...[
          SummaryLine(context.tr('care_summary_done'), muted: true),
          for (final e in o.doneCare) SummaryLine('✓ ${context.careTitle(e)}'),
        ],
        if (o.upcomingCare.isNotEmpty) ...[
          SummaryLine(context.tr('care_summary_upcoming'), muted: true),
          for (final e in o.upcomingCare)
            SummaryLine('${context.careTitle(e)} — ${context.careWhen(e, g)}'),
        ],
      ],
    ]);

    final notlar = SummarySection(context.tr('care_summary_section_notes'), [
      if (o.notedCare.isEmpty)
        yok
      else
        for (final e in o.notedCare)
          SummaryLine('${context.careTitle(e)}: ${e.note!.trim()}'),
    ]);

    final gunluk = SummarySection(context.tr('past_preg_section_daily_notes'), [
      if (o.dailyNotes.isEmpty)
        yok
      else
        for (final n in o.dailyNotes)
          SummaryLine('${tarih(n.date)} — ${n.text}'),
    ]);

    return [
      kimlik,
      tansiyon,
      kilo,
      kanama,
      belirtiler,
      kontroller,
      notlar,
      if (o.past) gunluk,
    ];
  }

  /// Geçmiş kayıtta gebeliğin nasıl ve ne zaman bittiği. Sonuç yalnızca
  /// kullanıcı belirttiyse yazılıyor.
  static String _bitis(BuildContext context, Pregnancy g, String tarih) =>
      switch (g.outcome) {
        PregnancyOutcome.birth => context.tr(
          'care_summary_birth',
          params: {'date': tarih},
        ),
        null || PregnancyOutcome.undisclosed => context.tr(
          'past_preg_ended',
          params: {'date': tarih},
        ),
        final sonuc => context.tr(
          'past_preg_ended_with',
          params: {
            'outcome': context.tr('preg_outcome_${sonuc.name}'),
            'date': tarih,
          },
        ),
      };

  /// Paylaşılan düz metin. Muayenede telefondan okunacak; CSV değil.
  @visibleForTesting
  static String plainText(
    BuildContext context,
    List<SummarySection> bolumler,
    DateTime bugun, {
    bool past = false,
  }) {
    final b = StringBuffer()
      ..writeln(
        context.tr(past ? 'past_preg_record_title' : 'care_summary_title'),
      )
      ..writeln(
        context.tr(
          'care_summary_generated',
          params: {
            'date':
                '${bugun.day} ${context.monthName(bugun.month)} '
                '${bugun.year}',
          },
        ),
      )
      ..writeln()
      ..writeln(context.tr(past ? 'past_preg_intro' : 'care_summary_intro'));
    for (final bolum in bolumler) {
      b
        ..writeln()
        ..writeln(context.upper(bolum.title));
      for (final s in bolum.lines) {
        b.writeln('  ${s.flagged ? '! ' : ''}${s.text}');
      }
    }
    return b.toString();
  }

  /// 64.5 → "64,5" (İngilizce dışında virgül), 64.0 → "64".
  static String _sayi(BuildContext context, double x) {
    final yuvarlak = (x * 10).round() / 10;
    final metin = yuvarlak == yuvarlak.roundToDouble()
        ? '${yuvarlak.round()}'
        : yuvarlak.toStringAsFixed(1);
    final dil = Localizations.localeOf(context).languageCode;
    return dil == 'en' ? metin : metin.replaceAll('.', ',');
  }
}

/// Özetin bir bölümü.
class SummarySection {
  final String title;
  final List<SummaryLine> lines;

  const SummarySection(this.title, this.lines);
}

/// Bölümdeki bir satır.
class SummaryLine {
  final String text;

  /// Hekimin dikkatine: 140/90 ve üstü, gebelikte kanama.
  final bool flagged;

  /// İkincil bilgi ("Kayıt yok", alt başlık).
  final bool muted;

  const SummaryLine(this.text, {this.flagged = false, this.muted = false});
}
