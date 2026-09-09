import '../models/daily_log.dart';
import '../models/period_log.dart';
import 'clinical_summary.dart';
import 'cycle_alert.dart';
import 'insights_service.dart';

/// Kullanıcının verisini taşınabilir biçimlere çevirir.
///
/// Dışa aktarma eskiden JSON'u **panoya** kopyalıyordu. İki sorunu vardı:
/// sistem panosunu okuyabilen her uygulama sağlık verisini görebiliyordu, ve
/// binlerce satırlık JSON'u bir yere yapıştırmak pratikte kullanılamıyordu.
///
/// Biçimler saf fonksiyon: dosya sistemi ya da paylaşım sayfası olmadan
/// test edilebiliyor.
class DataExportService {
  const DataExportService._();

  /// Doktora götürülebilecek özet.
  ///
  /// CSV değil düz metin: hasta bunu muayenede telefondan okuyabilmeli.
  static String buildSummary({
    required List<PeriodLog> periodLogs,
    required List<DailyLog> dailyLogs,
    required DateTime generatedAt,
    required String Function(String key, {Map<String, String>? params})
    translate,
  }) {
    final cycles = InsightsService.cycleLengths(periodLogs, limit: 12);
    final average = InsightsService.averageLength(cycles);
    final variation = InsightsService.variation(cycles);
    final clinical = ClinicalSummary.build(
      periodLogs: periodLogs,
      dailyLogs: dailyLogs,
    );

    final buffer = StringBuffer()
      ..writeln(translate('export_title'))
      ..writeln(
        translate(
          'export_generated_at',
          params: {'date': _formatDate(generatedAt)},
        ),
      )
      ..writeln();

    // ── Muayene özeti ──
    //
    // En başta duruyor: altmış satırlık gün günlüğü muayenede kimsenin
    // okuyacağı bir şey değil. Hekimin sorduğu şey toplu.
    if (clinical.hasData) {
      buffer.writeln(translate('export_section_clinical'));

      void line(String key, Map<String, String> params) =>
          buffer.writeln('  ${translate(key, params: params)}');

      if (clinical.firstLoggedDay != null && clinical.lastLoggedDay != null) {
        line('export_clinical_range', {
          'from': _formatDate(clinical.firstLoggedDay!),
          'to': _formatDate(clinical.lastLoggedDay!),
        });
      }
      if (clinical.observedCycles > 0) {
        line('export_clinical_cycles', {'n': '${clinical.observedCycles}'});
      }
      if (clinical.shortestCycleDays != null &&
          clinical.longestCycleDays != null) {
        line('export_clinical_range_days', {
          'min': '${clinical.shortestCycleDays}',
          'max': '${clinical.longestCycleDays}',
        });
      }
      if (clinical.averagePeriodDays != null) {
        line('export_clinical_period', {
          'avg': '${clinical.averagePeriodDays}',
          'max': '${clinical.longestPeriodDays}',
        });
      }
      if (clinical.heavyFlowDays > 0) {
        line('export_clinical_heavy', {'n': '${clinical.heavyFlowDays}'});
      }
      if (clinical.painDays > 0) {
        line('export_clinical_pain', {
          'total': '${clinical.painDays}',
          'severe': '${clinical.severePainDays}',
        });
      }
      if (clinical.painLimitedDays > 0) {
        line('export_clinical_limited', {'n': '${clinical.painLimitedDays}'});
      }
      if (clinical.topSymptoms.isNotEmpty) {
        final names = clinical.topSymptoms
            .map(
              (f) =>
                  '${translate('log_symptom_${f.code}')} '
                  '(${f.dayCount})',
            )
            .join(', ');
        line('export_clinical_symptoms', {'list': names});
      }
      for (final alert in clinical.alerts) {
        buffer.writeln('  ! ${translate(CycleAlertService.titleKey(alert))}');
      }
      buffer.writeln();
    }

    // ── Döngü özeti ──
    buffer.writeln(translate('export_section_cycles'));
    if (cycles.isEmpty) {
      buffer.writeln('  ${translate('export_no_cycles')}');
    } else {
      if (average != null) {
        buffer.writeln(
          '  ${translate('export_average', params: {'days': '$average'})}',
        );
      }
      if (variation != null) {
        buffer.writeln(
          '  ${translate('export_variation', params: {'days': '$variation'})}',
        );
      }
      for (final cycle in cycles) {
        buffer.writeln(
          '  ${_formatDate(cycle.startDate)} — ${cycle.lengthInDays} '
          '${translate('export_days')}',
        );
      }
    }
    buffer.writeln();

    // ── Kayıtlı günler ──
    final logged = dailyLogs.where(_hasContent).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    buffer.writeln(translate('export_section_logs'));
    if (logged.isEmpty) {
      buffer.writeln('  ${translate('export_no_logs')}');
    } else {
      for (final log in logged) {
        buffer.writeln('  ${_formatDate(log.date)}');
        if (log.flowIntensity != null) {
          buffer.writeln(
            '    ${translate('log_flow_intensity')}: '
            '${translate('log_flow_${log.flowIntensity}')}',
          );
        }
        if (log.symptoms.isNotEmpty) {
          buffer.writeln(
            '    ${translate('log_symptoms')}: '
            '${log.symptoms.map((s) => translate('log_symptom_$s')).join(', ')}',
          );
        }
        final pain = log.painLevel;
        if (pain != null) {
          final limited = log.painLimitedActivity
              ? ' — ${translate('export_pain_limited_short')}'
              : '';
          buffer.writeln(
            '    ${translate('day_detail_pain')}: '
            '${translate('log_pain_$pain')}$limited',
          );
        }
        if (log.moods.isNotEmpty) {
          buffer.writeln(
            '    ${translate('log_mood')}: '
            '${log.moods.map((m) => translate('log_mood_$m')).join(', ')}',
          );
        }
        final notes = log.notes;
        if (notes != null && notes.isNotEmpty) {
          buffer.writeln('    ${translate('log_notes')}: $notes');
        }
      }
    }

    buffer
      ..writeln()
      ..writeln(translate('export_footer'));

    return buffer.toString();
  }

  /// Tablo programlarında açılabilen satırlar.
  ///
  /// Alanlar tırnaklanır ve içerideki tırnak ikilenir: kullanıcı notuna
  /// yazdığı bir virgül sütunları kaydırmasın.
  static String buildCsv({
    required List<DailyLog> dailyLogs,
    required List<PeriodLog> periodLogs,
  }) {
    final periodDays = <String>{};
    for (final log in periodLogs) {
      // Devam eden dönemin kaydı bugüne kadar uzanır; `endDate ?? startDate`
      // yalnızca ilk günü dışa aktarıyordu.
      final end = log.lastRecordedDay();
      for (
        var day = _dateOnly(log.startDate);
        !day.isAfter(_dateOnly(end));
        day = day.add(const Duration(days: 1))
      ) {
        periodDays.add(_formatDate(day));
      }
    }

    final rows = <String>[
      'date,is_period,flow,symptoms,moods,sexual_activity,notes',
    ];

    final logged = dailyLogs.where(_hasContent).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final log in logged) {
      final date = _formatDate(log.date);
      rows.add(
        [
          date,
          periodDays.contains(date) ? 'yes' : 'no',
          log.flowIntensity ?? '',
          log.symptoms.join('; '),
          log.moods.join('; '),
          log.sexualActivity ?? '',
          log.notes ?? '',
        ].map(_csvField).join(','),
      );
    }

    return rows.join('\n');
  }

  static String _csvField(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static bool _hasContent(DailyLog log) =>
      log.symptoms.isNotEmpty ||
      log.moods.isNotEmpty ||
      log.flowIntensity != null ||
      log.sexualActivity != null ||
      (log.notes != null && log.notes!.isNotEmpty);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// ISO 8601 (YYYY-MM-DD): dile göre değişmez, tablo programları anlar.
  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
