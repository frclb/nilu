import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';

/// Türkiye doğum öncesi ve doğum sonu bakım şeması.
///
/// Kaynak: T.C. Sağlık Bakanlığı, Doğum Öncesi Bakım Yönetim Rehberi ve
/// Doğum Sonu Bakım Yönetim Rehberi (Ankara 2018). Ayrıntı:
/// `PREGNANCY_MODE.md` §2.7, `LIFE_STAGES.md` §2.
///
/// Haftalar rehberden **aynen** alınıyor; burada bir sayı değişirse testin
/// düşmesi gerekiyor, çünkü kullanıcı bu tarihlere göre hekime gidecek.
void main() {
  final sat = DateTime(2026, 1, 1);
  Pregnancy gebelik({DateTime? onay}) => Pregnancy.fromLmp(
    lmp: sat,
    cycleLength: 28,
    confirmedAt: onay ?? DateTime(2026, 2, 10),
    id: 'g1',
  );

  CareTemplateItem kalem(List<CareTemplateItem> liste, String kod) =>
      liste.singleWhere((k) => k.code == kod);

  group('doğum öncesi şablon — rehberle birebir', () {
    const t = CareTemplates.turkeyAntenatal;

    test('dört izlem, rehberdeki haftalarda', () {
      final izlemler = t.where((k) => k.category == CareCategory.visit);
      expect(izlemler, hasLength(4), reason: 'Bakanlık: en az dört izlem');

      expect(kalem(t, 'tr_visit_1').fromWeek, 0);
      expect(kalem(t, 'tr_visit_1').toWeek, 13, reason: 'ilk 14 hafta');
      expect(
        (kalem(t, 'tr_visit_2').fromWeek, kalem(t, 'tr_visit_2').toWeek),
        (18, 24),
      );
      expect(
        (kalem(t, 'tr_visit_3').fromWeek, kalem(t, 'tr_visit_3').toWeek),
        (24, 28),
      );
      expect(
        (kalem(t, 'tr_visit_4').fromWeek, kalem(t, 'tr_visit_4').toWeek),
        (36, 38),
      );
    });

    test('tarama pencereleri', () {
      (int, int) h(String kod) =>
          (kalem(t, kod).fromWeek!, kalem(t, kod).toWeek!);

      expect(h('tr_screen_combined'), (11, 14), reason: 'ense saydamlığı');
      expect(h('tr_screen_afp'), (16, 20));
      expect(h('tr_screen_triple'), (16, 20));
      expect(h('tr_screen_anomaly'), (18, 22));
      expect(h('tr_screen_ogtt'), (24, 28), reason: '75 g OGTT');
      expect(h('tr_screen_antid'), (28, 28));
    });

    test('koşullu kalemler koşulunu taşıyor', () {
      // Uygulama kan grubunu bilmiyor; anti-D'yi herkese "yapılmalı" diye
      // göstermek yanlış olur.
      expect(kalem(t, 'tr_screen_antid').conditionKey, isNotNull);
      expect(
        kalem(t, 'tr_screen_triple').conditionKey,
        isNotNull,
        reason: 'Yalnızca kombine test yapılmadıysa',
      );
      expect(kalem(t, 'tr_visit_2').conditionKey, isNull);
    });

    test('destek ve aşılar', () {
      expect(kalem(t, 'tr_supp_vitd').fromWeek, 12, reason: '1200 IU/gün');
      expect(kalem(t, 'tr_vacc_tetanus').fromWeek, 12);
      expect(kalem(t, 'tr_supp_iron').fromWeek, 16, reason: 'anemi yoksa');
    });

    test('hepsi gebelik haftasına bağlı', () {
      expect(t.every((k) => k.anchor == CareAnchor.gestation), isTrue);
    });
  });

  group('doğum sonu şablon — rehberle birebir', () {
    const t = CareTemplates.turkeyPostnatal;

    test('evde ya da sağlık kuruluşunda yapılan üç izlem', () {
      // İlk üç izlem doğumdan sonraki ilk 24 saatte, hastanede. O sırada
      // kimse regl uygulaması açmıyor; hatırlatılacak olanlar bu üçü.
      (int, int) g(String kod) => (kalem(t, kod).fromDay, kalem(t, kod).toDay);

      expect(g('tr_pp_visit_4'), (2, 5));
      expect(g('tr_pp_visit_5'), (13, 17));
      expect(g('tr_pp_visit_6'), (30, 42));
    });

    test('hepsi doğum gününe bağlı', () {
      expect(t.every((k) => k.anchor == CareAnchor.postpartum), isTrue);
    });
  });

  group('şablondan üretim', () {
    test('her kalem gebeliğe bağlı tek bir olay üretiyor', () {
      final olaylar = CareTemplates.generate(
        gebelik(),
        CareTemplates.turkeyAntenatal,
      );

      expect(olaylar, hasLength(CareTemplates.turkeyAntenatal.length));
      expect(olaylar.every((o) => o.pregnancyId == 'g1'), isTrue);
      expect(
        olaylar.map((o) => o.id).toSet(),
        hasLength(olaylar.length),
        reason: 'Kimlikler benzersiz olmalı',
      );
    });

    test('pencere tarihleri gebelik başlangıcından hesaplanıyor', () {
      final g = gebelik();
      final anomali = CareTemplates.generate(
        g,
        CareTemplates.turkeyAntenatal,
      ).singleWhere((o) => o.code == 'tr_screen_anomaly');

      expect(anomali.windowStart(g), sat.plusDays(18 * 7));
      expect(
        anomali.windowEnd(g),
        sat.plusDays(22 * 7 + 6),
        reason: '22. haftanın son günü',
      );
    });

    test('hekim tarihi düzeltince pencereler de kayıyor', () {
      // Pencere SAT'tan değil gebelik başlangıcından (EDD − 280) sayılıyor;
      // hekim tarihi 7 gün öteledi ise taramalar da 7 gün ötelenmeli.
      final hekim = Pregnancy.fromDueDate(
        dueDate: sat.plusDays(287),
        lmp: sat,
        id: 'g1',
      );
      final anomali = CareTemplates.generate(
        hekim,
        CareTemplates.turkeyAntenatal,
      ).singleWhere((o) => o.code == 'tr_screen_anomaly');

      expect(anomali.windowStart(hekim), sat.plusDays(18 * 7 + 7));
    });

    test(
      '14. haftadan sonra işaretlenirse ilk izlem kaçırılmış sayılmıyor',
      () {
        // Rehber: "14. gebelik haftasından sonraki gebe tespitleri, gebelik
        // haftasına bakılmaksızın İlk İzlem olarak değerlendirilir."
        final gec = gebelik(onay: sat.plusDays(20 * 7));
        final ilk = CareTemplates.generate(
          gec,
          CareTemplates.turkeyAntenatal,
        ).singleWhere((o) => o.code == 'tr_visit_1');

        expect(
          ilk.windowStart(gec),
          DateTime(2026, 5, 21),
          reason: 'Pencere işaretleme gününden başlamalı',
        );
        expect(
          ilk.windowEnd(gec)!.difference(ilk.windowStart(gec)!).inDays,
          6,
          reason: 'Bir hafta içinde',
        );
      },
    );

    test('zamanında işaretlenirse ilk izlem rehberdeki pencerede', () {
      final g = gebelik(onay: sat.plusDays(6 * 7));
      final ilk = CareTemplates.generate(
        g,
        CareTemplates.turkeyAntenatal,
      ).singleWhere((o) => o.code == 'tr_visit_1');

      expect(ilk.windowStart(g), sat);
      expect(ilk.windowEnd(g), sat.plusDays(13 * 7 + 6));
    });

    test('doğum sonu kalemleri doğum gününden sayılıyor', () {
      final dogum = DateTime(2026, 10, 5);
      final g = gebelik().ended(outcome: PregnancyOutcome.birth, at: dogum);
      final ziyaret = CareTemplates.generate(
        g,
        CareTemplates.turkeyPostnatal,
      ).singleWhere((o) => o.code == 'tr_pp_visit_5');

      expect(ziyaret.windowStart(g), DateTime(2026, 10, 18));
      expect(ziyaret.windowEnd(g), DateTime(2026, 10, 22));
    });

    test('süren gebelikte doğum sonu penceresi henüz yok', () {
      final g = gebelik();
      final ziyaret = CareTemplates.generate(
        g,
        CareTemplates.turkeyPostnatal,
      ).first;
      expect(
        ziyaret.windowStart(g),
        isNull,
        reason: 'Doğum tarihi bilinmeden pencere uydurulmamalı',
      );
    });
  });

  group('kullanıcının kendi randevusu', () {
    test('şablon dışı kalem eklenebiliyor', () {
      final o = CareEvent.custom(
        pregnancyId: 'g1',
        title: 'Diş hekimi',
        scheduledAt: DateTime(2026, 4, 3, 14, 30),
      );
      expect(o.code, isNull);
      expect(o.title, 'Diş hekimi');
      expect(o.isCustom, isTrue);
    });
  });

  group('json yuvarlak gidip gelir', () {
    test('şablondan gelen', () {
      final o = CareTemplates.generate(gebelik(), CareTemplates.turkeyAntenatal)
          .first
          .copyWith(
            scheduledAt: DateTime(2026, 3, 1, 10, 15),
            done: true,
            note: 'Hekime sor: bulantı',
            reminderOn: false,
          );
      final geri = CareEvent.fromMap(o.toMap());

      expect(geri.id, o.id);
      expect(geri.code, o.code);
      expect(geri.category, o.category);
      expect(geri.anchor, o.anchor);
      expect((geri.fromDay, geri.toDay), (o.fromDay, o.toDay));
      expect(
        geri.scheduledAt,
        DateTime(2026, 3, 1, 10, 15),
        reason: 'Randevunun saati de korunmalı',
      );
      expect(geri.done, isTrue);
      expect(geri.note, 'Hekime sor: bulantı');
      expect(geri.reminderOn, isFalse);
    });

    test('tanınmayan kategori kaydı düşürmüyor', () {
      final geri = CareEvent.fromMap({
        'id': 'x',
        'pregnancyId': 'g1',
        'title': 'Bir şey',
        'category': 'gelecekte_eklenen',
        'anchor': 'gestation',
        'fromDay': 10,
        'toDay': 20,
      });
      expect(geri.id, 'x');
      expect(geri.category, CareCategory.visit);
    });
  });
}
