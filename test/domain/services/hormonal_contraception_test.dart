import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/phase_guide.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Hormonal doğum kontrolü (kombine hap, hormonal spiral, implant, iğne)
/// çoğunlukla yumurtlamayı baskılar. Uygulama bunu bilmiyordu ve hap kullanan
/// bir kullanıcıya da yumurtlama günü ile doğurganlık penceresi gösteriyordu.
void main() {
  final service = PredictionService();
  final start = DateTime(2026, 3, 1);
  final logs = [
    PeriodLog(id: 'p1', startDate: start, endDate: DateTime(2026, 3, 5)),
  ];

  CycleInfo build({required bool contraception}) => service.getCycleInfo(
    logs,
    userCycleLength: 28,
    userPeriodLength: 5,
    settingsUpdatedAt: DateTime(2000),
    hormonalContraception: contraception,
  );

  group('hormonal doğum kontrolü kapalıyken', () {
    test('yumurtlama ve doğurganlık penceresi üretilir', () {
      final info = build(contraception: false);
      expect(info.fertilityTracked, isTrue);
      expect(info.ovulationDay, isNotNull);
      expect(info.fertileWindowStart, isNotNull);
      expect(info.fertileWindowEnd, isNotNull);
      expect(info.isFertile(info.ovulationDay!), isTrue);
    });

    test('ileri tahminlerde de doğurganlık vardır', () {
      final info = build(contraception: false);
      expect(info.futurePredictions, isNotEmpty);
      for (final p in info.futurePredictions) {
        expect(p.ovulationDay, isNotNull);
        expect(p.fertileStart, isNotNull);
      }
    });
  });

  group('hormonal doğum kontrolü açıkken', () {
    test('yumurtlama günü hiç hesaplanmaz', () {
      final info = build(contraception: true);
      expect(info.fertilityTracked, isFalse);
      expect(info.ovulationDay, isNull);
      expect(info.fertileWindowStart, isNull);
      expect(info.fertileWindowEnd, isNull);
    });

    test('ileri tahminlerde de doğurganlık üretilmez', () {
      final info = build(contraception: true);
      expect(info.futurePredictions, isNotEmpty);
      for (final p in info.futurePredictions) {
        expect(p.ovulationDay, isNull, reason: '${p.startDate}');
        expect(p.fertileStart, isNull, reason: '${p.startDate}');
        expect(p.fertileEnd, isNull, reason: '${p.startDate}');
      }
    });

    test('hiçbir gün doğurgan işaretlenmez', () {
      final info = build(contraception: true);
      for (var i = 0; i < 60; i++) {
        expect(
          info.isFertile(start.add(Duration(days: i))),
          isFalse,
          reason: '${i + 1}. gün',
        );
      }
    });

    test('hiçbir gün yumurtlama günü işaretlenmez', () {
      // `ovulationDay` null olduğu için doğal olarak false dönüyor; bu
      // testin işi o davranışın sessizce bozulmasını engellemek.
      final info = build(contraception: true);
      for (var i = 0; i < 60; i++) {
        expect(
          info.isOvulationDay(start.add(Duration(days: i))),
          isFalse,
          reason: '${i + 1}. gün',
        );
      }
    });

    test('regl günleri hâlâ regl olarak gösterilir', () {
      // Kanama takibi anlamını yitirmiyor; yalnızca doğurganlık yitiriyor.
      final info = build(contraception: true);
      expect(info.getPhaseForDay(1), CyclePhase.menstruation);
      expect(info.getPhaseForDay(5), CyclePhase.menstruation);
    });

    test('kanama dışı günler yumurtlama ya da luteal denmez', () {
      final info = build(contraception: true);
      for (var day = 6; day <= 28; day++) {
        expect(
          info.getPhaseForDay(day),
          CyclePhase.suppressed,
          reason: '$day. gün',
        );
      }
    });

    test('regl tahmini çalışmaya devam eder', () {
      // Hap kullanımında da kanama zamanı öngörülebilir; kaldırılan tek şey
      // doğurganlık.
      final info = build(contraception: true);
      expect(info.predictedNextPeriod, DateTime(2026, 3, 29));
    });
  });

  test('baskılanmış evrenin de içeriği var', () {
    final guidance = PhaseGuide.forPhase(CyclePhase.suppressed);
    expect(guidance.titleKey, isNotEmpty);
    expect(guidance.bodyKey, isNotEmpty);
    expect(guidance.tipKey, isNotEmpty);
  });
}
