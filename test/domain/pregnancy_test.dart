import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';

/// Gebelik haftası ve tahmini doğum tarihi hesabı.
///
/// Klinik kaynaklar (bkz. `PREGNANCY_MODE.md`):
///
/// - Gebelik haftası **son adet tarihinden** sayılır, döllenmeden değil.
///   İkisi arasında ~2 hafta var ve kullanıcılar bunu karıştırıyor.
/// - Naegele kuralı SAT + 280 gün, ama 28 günlük döngü varsayıyor.
///   Uygulama döngü uzunluğunu zaten biliyor, o yüzden düzeltebiliyor.
/// - ACOG CO 700 ve T.C. Sağlık Bakanlığı rehberi: SAT şüpheliyse ya da
///   ilk trimester ultrasonu varsa gebelik yaşı **ona göre** belirlenir.
///   Yani hekimin verdiği tarih uygulamanınkini ezer; EDD kaynağı
///   değiştiğinde hafta hesabı da onunla birlikte kayar.
void main() {
  final sat = DateTime(2026, 1, 1);

  group('tahmini doğum tarihi', () {
    test('28 günlük döngüde Naegele: SAT + 280 gün', () {
      final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 28);
      expect(g.estimatedDueDate, DateTime(2026, 10, 8));
      expect(
        g.estimatedDueDate.daysSince(sat),
        280,
        reason: 'Naegele kuralı 280 gün',
      );
    });

    test('uzun döngüde geç, kısa döngüde erken', () {
      final uzun = Pregnancy.fromLmp(lmp: sat, cycleLength: 35);
      final kisa = Pregnancy.fromLmp(lmp: sat, cycleLength: 21);

      expect(
        uzun.estimatedDueDate.daysSince(sat),
        287,
        reason:
            '35 günlük döngüde yumurtlama bir hafta geç; düz Naegele bir '
            'hafta erken tarih verirdi',
      );
      expect(kisa.estimatedDueDate.daysSince(sat), 273);
    });

    test('döngü uzunluğu sınırların dışındaysa 28 varsayılır', () {
      // Bozuk ya da uçuk bir ayar tahmini saçmalaştırmamalı.
      for (final uzunluk in [0, 1, 200, -5]) {
        final g = Pregnancy.fromLmp(lmp: sat, cycleLength: uzunluk);
        expect(
          g.estimatedDueDate.daysSince(sat),
          280,
          reason: '$uzunluk günlük döngü güvenilir değil',
        );
      }
    });

    test('hekimin verdiği tarih hesaplananı ezer', () {
      final hekim = DateTime(2026, 10, 1);
      final g = Pregnancy.fromDueDate(dueDate: hekim);

      expect(g.estimatedDueDate, hekim);
      expect(
        g.dueDateFromClinician,
        isTrue,
        reason:
            'Kaynağın hekim olduğu saklanmalı: ilk trimester ultrasonu '
            'uygulamanın hesabını geçersiz kılar (ACOG CO 700)',
      );
    });

    test('SAT\'tan kurulan gebelikte kaynak hekim değildir', () {
      final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 28);
      expect(g.dueDateFromClinician, isFalse);
    });
  });

  group('gebelik haftası', () {
    final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 28);

    test('SAT günü 0 hafta 0 gün', () {
      final ga = g.gestationOn(sat)!;
      expect(ga.weeks, 0);
      expect(ga.days, 0);
      expect(ga.totalDays, 0);
    });

    test('haftalar ve günler ayrı sayılır', () {
      expect(g.gestationOn(sat.add(const Duration(days: 6)))!.weeks, 0);
      expect(g.gestationOn(sat.add(const Duration(days: 6)))!.days, 6);
      expect(g.gestationOn(sat.add(const Duration(days: 7)))!.weeks, 1);
      expect(g.gestationOn(sat.add(const Duration(days: 7)))!.days, 0);
      expect(g.gestationOn(sat.add(const Duration(days: 100)))!.weeks, 14);
      expect(g.gestationOn(sat.add(const Duration(days: 100)))!.days, 2);
    });

    test('SAT öncesi için hafta yok', () {
      expect(
        g.gestationOn(sat.subtract(const Duration(days: 1))),
        isNull,
        reason: 'Gebelik başlamadan önce hafta göstermek anlamsız',
      );
    });

    test('tahmini tarih 40+0 haftaya denk gelir', () {
      final ga = g.gestationOn(g.estimatedDueDate)!;
      expect(ga.weeks, 40);
      expect(ga.days, 0);
    });

    test('tarih geçince hafta saymaya devam eder', () {
      // 41. haftada da izlem var; sayaç durmamalı.
      final ga = g.gestationOn(
        g.estimatedDueDate.add(const Duration(days: 8)),
      )!;
      expect(ga.weeks, 41);
      expect(ga.days, 1);
    });

    test('SAT dururken hekim tarihi hafta hesabını belirler', () {
      // Gerçek akış: kullanıcı SAT'ı giriyor, uygulama tarih hesaplıyor,
      // sonra hekim ilk trimester ultrasonuyla tarihi düzeltiyor. SAT
      // referans olarak kalıyor ama **hafta artık EDD'den** sayılmalı
      // (ACOG CO 700). İkisi kayıtta birlikte durduğu için hesabın hangisine
      // bakacağı burada ayrışıyor.
      final hekim = Pregnancy.fromDueDate(
        dueDate: DateTime(2026, 10, 15), // uygulamanınkinden 7 gün geç
        lmp: sat,
      );

      expect(hekim.lmp, sat, reason: 'SAT referans olarak kalmalı');

      final gun = DateTime(2026, 5, 1);
      final satTan = gun.daysSince(sat);
      final hesap = hekim.gestationOn(gun)!.totalDays;

      expect(
        hesap,
        satTan - 7,
        reason:
            'Hekim tarihi 7 gün geç; aynı günde gebelik 7 gün daha geride '
            'olmalı. SAT\'tan sayılırsa ekranda hekimin söylediğinden bir '
            'hafta ileri bir sayı görünür.',
      );
    });

    test('hekim tarihi girildiğinde hafta ona göre kayar', () {
      // Hekim uygulamanın hesabından 7 gün erken bir tarih verdi: aynı
      // takvim gününde gebelik bir hafta daha ileride olmalı.
      final hekim = Pregnancy.fromDueDate(
        dueDate: DateTime(2026, 10, 1), // 7 gün erken
      );
      final sat28 = Pregnancy.fromLmp(lmp: sat, cycleLength: 28);
      final gun = DateTime(2026, 5, 1);

      expect(
        hekim.gestationOn(gun)!.totalDays - sat28.gestationOn(gun)!.totalDays,
        7,
        reason:
            'Yeniden tarihlendirme hafta hesabını da kaydırmalı; yoksa '
            'ekranda hekimin söylediğinden farklı bir hafta görünür',
      );
    });
  });

  group('trimester', () {
    final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 28);
    Trimester? on(int gun) => g.trimesterOn(sat.add(Duration(days: gun)));

    // ACOG sınırları: T1 0+0–13+6, T2 14+0–27+6, T3 28+0–.
    test('sınırlar ACOG\'a göre', () {
      expect(on(0), Trimester.first);
      expect(on(13 * 7 + 6), Trimester.first, reason: '13+6 hâlâ birinci');
      expect(on(14 * 7), Trimester.second, reason: '14+0 ikinciye geçer');
      expect(on(27 * 7 + 6), Trimester.second, reason: '27+6 hâlâ ikinci');
      expect(on(28 * 7), Trimester.third, reason: '28+0 üçüncüye geçer');
      expect(on(42 * 7), Trimester.third);
    });

    test('SAT öncesi trimester yok', () {
      expect(g.trimesterOn(sat.subtract(const Duration(days: 1))), isNull);
    });
  });

  group('bitmiş gebelik', () {
    test('bittiğinde artık sürmüyor sayılır', () {
      final g = Pregnancy.fromLmp(
        lmp: sat,
        cycleLength: 28,
      ).ended(outcome: PregnancyOutcome.birth, at: DateTime(2026, 10, 5));

      expect(g.isActive, isFalse);
      expect(g.outcome, PregnancyOutcome.birth);
      expect(g.endedAt, DateTime(2026, 10, 5));
    });

    test('sebep belirtmeden de bitirilebilir', () {
      // Kayıp yaşayan kullanıcıdan sebep istemek kabul edilemez.
      final g = Pregnancy.fromLmp(
        lmp: sat,
        cycleLength: 28,
      ).ended(outcome: PregnancyOutcome.undisclosed, at: DateTime(2026, 3, 1));

      expect(g.isActive, isFalse);
      expect(g.outcome, PregnancyOutcome.undisclosed);
    });

    test('bittikten sonra hafta hesaplanmaz', () {
      final g = Pregnancy.fromLmp(
        lmp: sat,
        cycleLength: 28,
      ).ended(outcome: PregnancyOutcome.miscarriage, at: DateTime(2026, 3, 1));

      expect(
        g.gestationOn(DateTime(2026, 6, 1)),
        isNull,
        reason:
            'Biten bir gebelikte hafta saymaya devam etmek, kullanıcıya '
            'olmayan bir gebeliği hatırlatmak olur',
      );
    });

    test('yeni kurulan gebelik sürüyor', () {
      expect(Pregnancy.fromLmp(lmp: sat, cycleLength: 28).isActive, isTrue);
    });
  });

  group('json yuvarlak gidip gelir', () {
    test('SAT ile kurulan', () {
      final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 35);
      final geri = Pregnancy.fromMap(g.toMap());

      expect(geri.lmp, g.lmp);
      expect(geri.estimatedDueDate, g.estimatedDueDate);
      expect(geri.dueDateFromClinician, g.dueDateFromClinician);
      expect(geri.id, g.id);
      expect(geri.isActive, isTrue);
    });

    test('bitmiş olan', () {
      final g = Pregnancy.fromDueDate(
        dueDate: DateTime(2026, 10, 1),
      ).ended(outcome: PregnancyOutcome.stillbirth, at: DateTime(2026, 9, 20));
      final geri = Pregnancy.fromMap(g.toMap());

      expect(geri.outcome, PregnancyOutcome.stillbirth);
      expect(geri.endedAt, g.endedAt);
      expect(geri.lmp, isNull);
      expect(geri.isActive, isFalse);
    });

    test('tanınmayan sonuç kaydı düşürmez', () {
      // İleri sürümde yeni bir sonuç eklenirse eski sürüm kaydı
      // okuyamayıp atmamalı.
      final ham = {
        'id': 'x',
        'estimatedDueDate': '2026-10-08',
        'dueDateFromClinician': false,
        'confirmedAt': '2026-01-01',
        'outcome': 'gelecekte_eklenen_bir_sey',
        'endedAt': '2026-05-01',
      };
      final geri = Pregnancy.fromMap(ham);

      expect(geri.id, 'x');
      expect(
        geri.outcome,
        PregnancyOutcome.undisclosed,
        reason: 'Tanınmayan sonuç "belirtilmedi" sayılmalı, kayıt atılmamalı',
      );
      expect(geri.isActive, isFalse);
    });
  });
}
