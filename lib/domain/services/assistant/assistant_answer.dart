import '../../models/cycle_info.dart';
import '../../models/daily_log.dart';
import '../../models/period_log.dart';
import '../insights_service.dart';
import 'assistant_parser.dart';

/// Bir cevabın parçaları.
///
/// Ekran metni doğrudan alır; hangi anahtarın hangi parametreyle
/// çevrildiğini burada bilmek gerekmiyor.
class AssistantAnswer {
  /// Lokalizasyon anahtarı.
  final String key;
  final Map<String, String> params;

  /// Uygulamanın cevaplayacak verisi yoksa true — ekran kullanıcıyı kayıt
  /// girmeye yönlendirir.
  final bool needsData;

  const AssistantAnswer(
    this.key, {
    this.params = const {},
    this.needsData = false,
  });
}

/// Soruları uygulamanın kendi verisinden cevaplar.
///
/// Hiçbir hesap burada yeniden yazılmadı: `PredictionService` ve
/// `InsightsService` zaten bu sayıları üretiyor. Tek iş, hangi sorunun hangi
/// hesaba karşılık geldiğini bilmek.
///
/// Veri yetmiyorsa **tahmin üretilmez**; sağlık uygulamasında "makul görünen"
/// bir cevap, cevapsızlıktan kötüdür.
class AssistantAnswerBuilder {
  const AssistantAnswerBuilder._();

  static AssistantAnswer build(
    AssistantQuery query, {
    required CycleInfo cycleInfo,
    required List<PeriodLog> periodLogs,
    required List<DailyLog> dailyLogs,
    required DateTime now,
  }) {
    return switch (query.intent) {
      AssistantIntent.nextPeriod => _nextPeriod(cycleInfo, now),
      AssistantIntent.currentPhase => _currentPhase(cycleInfo),
      AssistantIntent.fertileWindow => _fertileWindow(cycleInfo),
      AssistantIntent.cycleLength => _cycleLength(periodLogs),
      AssistantIntent.periodLength => _periodLength(cycleInfo, periodLogs),
      AssistantIntent.regularity => _regularity(periodLogs),
      AssistantIntent.symptomFrequency => _symptomFrequency(
        query.symptomCode,
        dailyLogs,
        periodLogs,
        cycleInfo,
      ),
      AssistantIntent.lastSymptom => _lastSymptom(query.symptomCode, dailyLogs),
      AssistantIntent.unknown => const AssistantAnswer('assistant_unknown'),
    };
  }

  static AssistantAnswer _nextPeriod(CycleInfo info, DateTime now) {
    final next = info.predictedNextPeriod;
    if (next == null) {
      return const AssistantAnswer('assistant_no_data', needsData: true);
    }

    // `info.daysUntilNextPeriod` içeride `DateTime.now()` okuyor; burada
    // kullanılsaydı çağıranın verdiği [now] sessizce yok sayılırdı. Testte
    // sabit bir tarih enjekte edilmesine rağmen cevap duvar saatine göre
    // değişiyordu.
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(next.year, next.month, next.day);
    final days = target.difference(today).inDays;

    // Gecikme kendi cümlesini hak ediyor.
    //
    // Fark sıfıra kırpılıyordu: gecikmenin her gününde "bugün başlıyor"
    // deniyordu. Kırk gün gecikmiş birine bunu söylemek yalnızca yanlış
    // değil, endişe verici bir durumu görmezden gelmek. Ana ekran aynı
    // anda "40 gün gecikti" diyordu; çarkta düzeltilen bu hata asistana
    // taşınmamıştı.
    if (days < 0) {
      return AssistantAnswer(
        'assistant_late',
        params: {'days': '${-days}', 'date': _format(next)},
      );
    }

    return AssistantAnswer(
      days == 0 ? 'assistant_next_period_today' : 'assistant_next_period',
      params: {'days': '$days', 'date': _format(next)},
    );
  }

  static AssistantAnswer _currentPhase(CycleInfo info) {
    final day = info.currentCycleDay;
    if (day == null) {
      return const AssistantAnswer('assistant_no_data', needsData: true);
    }
    return AssistantAnswer(
      'assistant_current_phase',
      params: {'day': '$day', 'phase': _phaseKey(info.currentPhase)},
    );
  }

  static AssistantAnswer _fertileWindow(CycleInfo info) {
    // Hormonal doğum kontrolünde doğurganlık **bilerek** hesaplanmıyor.
    //
    // Bu durumda "kayıt yok" demek yanlış yönlendirme: kullanıcının
    // verisi var ve takvimde sonsuza kadar gün işaretlese de cevap
    // gelmeyecek. Sebebi söylemek gerekiyor.
    if (!info.fertilityTracked) {
      return const AssistantAnswer('assistant_fertility_off');
    }

    final start = info.fertileWindowStart;
    final end = info.fertileWindowEnd;
    final ovulation = info.ovulationDay;
    if (start == null || end == null || ovulation == null) {
      return const AssistantAnswer('assistant_no_data', needsData: true);
    }
    return AssistantAnswer(
      'assistant_fertile_window',
      params: {
        'start': _format(start),
        'end': _format(end),
        'ovulation': _format(ovulation),
      },
    );
  }

  static AssistantAnswer _cycleLength(List<PeriodLog> logs) {
    final cycles = InsightsService.cycleLengths(logs);
    final average = InsightsService.averageLength(cycles);
    if (average == null) {
      return const AssistantAnswer(
        'assistant_need_two_cycles',
        needsData: true,
      );
    }
    return AssistantAnswer(
      'assistant_cycle_length',
      params: {
        'days': '$average',
        'count': '${cycles.length}',
        'last': '${cycles.last.lengthInDays}',
      },
    );
  }

  static AssistantAnswer _periodLength(CycleInfo info, List<PeriodLog> logs) {
    final completed = logs.map((l) => l.completedLength).whereType<int>();
    if (completed.isEmpty) {
      return const AssistantAnswer('assistant_no_data', needsData: true);
    }
    return AssistantAnswer(
      'assistant_period_length',
      params: {'days': '${info.averagePeriodLength}'},
    );
  }

  static AssistantAnswer _regularity(List<PeriodLog> logs) {
    final cycles = InsightsService.cycleLengths(logs);
    final regularity = InsightsService.regularity(cycles);
    final spread = InsightsService.variation(cycles);
    if (regularity == null || spread == null) {
      return const AssistantAnswer(
        'assistant_need_two_cycles',
        needsData: true,
      );
    }

    return AssistantAnswer(
      switch (regularity) {
        CycleRegularity.steady => 'assistant_regular_steady',
        CycleRegularity.typical => 'assistant_regular_typical',
        CycleRegularity.irregular => 'assistant_regular_irregular',
      },
      params: {'days': '$spread'},
    );
  }

  static AssistantAnswer _symptomFrequency(
    String? code,
    List<DailyLog> dailyLogs,
    List<PeriodLog> periodLogs,
    CycleInfo info,
  ) {
    if (code == null) return const AssistantAnswer('assistant_unknown');

    final dominant = InsightsService.dominantPhase(
      code,
      dailyLogs: dailyLogs,
      periodLogs: periodLogs,
      periodLength: info.averagePeriodLength,
    );

    if (dominant == null) {
      // Baskın evre çıkarılamadı; en azından toplam sayıyı verelim.
      final count = dailyLogs.where((l) => l.symptoms.contains(code)).length;
      if (count == 0) {
        return AssistantAnswer(
          'assistant_symptom_none',
          params: {'symptom': code},
          needsData: true,
        );
      }
      return AssistantAnswer(
        'assistant_symptom_count_only',
        params: {'symptom': code, 'count': '$count'},
      );
    }

    return AssistantAnswer(
      'assistant_symptom_phase',
      params: {
        'symptom': code,
        'phase': _phaseKey(dominant.phase),
        'count': '${dominant.count}',
        'total': '${dominant.total}',
      },
    );
  }

  static AssistantAnswer _lastSymptom(String? code, List<DailyLog> logs) {
    if (code == null) return const AssistantAnswer('assistant_unknown');

    final matching = logs.where((l) => l.symptoms.contains(code)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (matching.isEmpty) {
      return AssistantAnswer(
        'assistant_symptom_none',
        params: {'symptom': code},
        needsData: true,
      );
    }

    return AssistantAnswer(
      'assistant_last_symptom',
      params: {'symptom': code, 'date': _format(matching.first.date)},
    );
  }

  static String _phaseKey(CyclePhase phase) => switch (phase) {
    CyclePhase.menstruation => 'phase_menstruation',
    CyclePhase.follicular => 'phase_follicular',
    CyclePhase.ovulation => 'phase_ovulation',
    CyclePhase.luteal => 'phase_luteal',
    CyclePhase.suppressed => 'phase_suppressed',
    CyclePhase.unknown => 'phase_unknown',
  };

  /// ISO tarih — ekran bunu kullanıcının diline çevirir.
  static String _format(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
