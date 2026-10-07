import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/insights_service.dart';
import 'package:period_tracker/domain/services/premium_gate.dart';

void main() {
  List<CycleLengthPoint> cycles(int n) => [
    for (var i = 0; i < n; i++)
      CycleLengthPoint(
        startDate: DateTime(2026, 1, 1).add(Duration(days: i * 28)),
        lengthInDays: 28,
      ),
  ];

  group('geçmiş derinliği', () {
    test('ücretsiz sürüm son üç döngüyü gösterir', () {
      final visible = PremiumGate.visibleCycles(cycles(8), isPremium: false);

      expect(visible, hasLength(3));
      // En yenileri kalmalı: kullanıcı en güncel döngülerini görmeli.
      expect(visible.last.startDate, cycles(8).last.startDate);
    });

    test('premium daha uzun geçmiş gösterir', () {
      expect(
        PremiumGate.visibleCycles(cycles(8), isPremium: true),
        hasLength(8),
      );
    });

    test('premiumda sınır yok', () {
      // Ödeme ekranı "geçmişin tamamı" diyordu, burada 12'de kesiliyordu.
      expect(PremiumGate.cycleHistoryLimit(isPremium: true), isNull);
      expect(
        PremiumGate.visibleCycles(cycles(40), isPremium: true),
        hasLength(40),
      );
    });

    test('sınırın altındaki geçmiş kırpılmaz', () {
      expect(
        PremiumGate.visibleCycles(cycles(2), isPremium: false),
        hasLength(2),
      );
    });

    test('kırpılma yalnızca gerçekten veri varken bildirilir', () {
      // Ekran "daha fazlası var" derken elinde olmayan veriyi ima etmemeli.
      expect(
        PremiumGate.historyIsTrimmed(isPremium: false, observedCycles: 2),
        isFalse,
      );
      expect(
        PremiumGate.historyIsTrimmed(isPremium: false, observedCycles: 5),
        isTrue,
      );
      expect(
        PremiumGate.historyIsTrimmed(isPremium: true, observedCycles: 20),
        isFalse,
      );
    });
  });

  group('özellik kapıları', () {
    test('evre kırılımı premium gerektirir', () {
      expect(PremiumGate.canSeePhaseBreakdown(isPremium: false), isFalse);
      expect(PremiumGate.canSeePhaseBreakdown(isPremium: true), isTrue);
    });

    test('dışa aktarma premium gerektirir', () {
      // Yedek herkese açık: makine-okunur kopya almak bir hak, ücrete
      // bağlanamaz. Üstelik veri cihazda duruyor — yedek alamayan
      // kullanıcı telefonunu kaybettiğinde her şeyini kaybederdi.
      expect(PremiumGate.canExportBackup(), isTrue);

      // Hekim özeti ve tablo kolaylık; onlar premium'da.
      expect(PremiumGate.canExportReports(isPremium: false), isFalse);
      expect(PremiumGate.canExportReports(isPremium: true), isTrue);
    });

    test('trend için iki döngü yeterlidir, abonelik şart değil', () {
      // Ücretsiz sürüm de işe yaramalı: temel trend herkese açık.
      expect(
        PremiumGate.hasEnoughForTrend(isPremium: false, observedCycles: 2),
        isTrue,
      );
      expect(
        PremiumGate.hasEnoughForTrend(isPremium: false, observedCycles: 1),
        isFalse,
      );
    });
  });

  group('reklam', () {
    test('ücretsiz kullanıcıya gösterilir', () {
      expect(PremiumGate.showsAds(isPremium: false), isTrue);
    });

    test('premium kullanıcıya gösterilmez', () {
      expect(PremiumGate.showsAds(isPremium: true), isFalse);
    });
  });
}
