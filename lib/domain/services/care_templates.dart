import '../models/calendar_day.dart';
import '../models/care_event.dart';
import '../models/pregnancy.dart';

/// Şablondaki bir kalem.
class CareTemplateItem {
  final String code;
  final CareCategory category;
  final CareAnchor anchor;

  /// Çapadan itibaren gün olarak pencere, ikisi dahil.
  final int fromDay;
  final int toDay;

  final String? conditionKey;

  /// Varsayılan olarak hatırlatılsın mı?
  final bool remindByDefault;

  const CareTemplateItem({
    required this.code,
    required this.category,
    required this.anchor,
    required this.fromDay,
    required this.toDay,
    this.conditionKey,
    this.remindByDefault = true,
  });

  /// Gebelik haftası cinsinden: `fromWeek+0` ile `toWeek+6` arası.
  const CareTemplateItem.weeks({
    required this.code,
    required this.category,
    required int fromWeek,
    required int toWeek,
    this.conditionKey,
    this.remindByDefault = true,
  }) : anchor = CareAnchor.gestation,
       fromDay = fromWeek * 7,
       toDay = toWeek * 7 + 6;

  /// Doğum gününden itibaren gün cinsinden.
  const CareTemplateItem.daysAfterBirth({
    required this.code,
    required this.category,
    required this.fromDay,
    required this.toDay,
    this.conditionKey,
    this.remindByDefault = true,
  }) : anchor = CareAnchor.postpartum;

  int? get fromWeek => anchor == CareAnchor.gestation ? fromDay ~/ 7 : null;
  int? get toWeek => anchor == CareAnchor.gestation ? toDay ~/ 7 : null;
}

/// Ülkeye göre bakım şablonları.
///
/// v1'de yalnızca Türkiye var. Diğer diller için kullanıcı "kendi
/// randevunu ekle" ile başlıyor: yanlış ülkenin takvimini göstermektense
/// boş liste göstermek daha dürüst (NHS ilk gebelikte 10 izlem, Türkiye 4,
/// ACOG ~13 — fark büyük). Bkz. `PREGNANCY_MODE.md` §2.3.
class CareTemplates {
  const CareTemplates._();

  /// T.C. Sağlık Bakanlığı, Halk Sağlığı Genel Müdürlüğü, *Doğum Öncesi
  /// Bakım Yönetim Rehberi*, Ankara 2018.
  ///
  /// Haftalar rehberden aynen. Buradaki bir sayı değişirse
  /// `care_schedule_test` düşmeli: kullanıcı bu tarihlere göre hekime gidecek.
  static const List<CareTemplateItem> turkeyAntenatal = [
    // ── İzlemler: en az dört, riske göre artırılır ──
    CareTemplateItem.weeks(
      code: 'tr_visit_1',
      category: CareCategory.visit,
      fromWeek: 0,
      toWeek: 13, // "ilk 14 hafta içerisinde"
    ),
    CareTemplateItem.weeks(
      code: 'tr_visit_2',
      category: CareCategory.visit,
      fromWeek: 18,
      toWeek: 24,
    ),
    CareTemplateItem.weeks(
      code: 'tr_visit_3',
      category: CareCategory.visit,
      fromWeek: 24,
      toWeek: 28,
    ),
    CareTemplateItem.weeks(
      code: 'tr_visit_4',
      category: CareCategory.visit,
      fromWeek: 36,
      toWeek: 38,
    ),

    // ── Taramalar: izlemlerle aynı güne düşmeyebilir ──
    CareTemplateItem.weeks(
      code: 'tr_screen_combined', // USG ense saydamlığı + kombine test
      category: CareCategory.screening,
      fromWeek: 11,
      toWeek: 14,
    ),
    CareTemplateItem.weeks(
      code: 'tr_screen_afp', // maternal serum AFP
      category: CareCategory.screening,
      fromWeek: 16,
      toWeek: 20,
    ),
    CareTemplateItem.weeks(
      code: 'tr_screen_triple', // üçlü/dörtlü test
      category: CareCategory.screening,
      fromWeek: 16,
      toWeek: 20,
      conditionKey: 'care_condition_no_combined',
    ),
    CareTemplateItem.weeks(
      code: 'tr_screen_anomaly', // USG fetal anomali taraması
      category: CareCategory.screening,
      fromWeek: 18,
      toWeek: 22,
    ),
    CareTemplateItem.weeks(
      code: 'tr_screen_ogtt', // 75 g oral glukoz tanı testi
      category: CareCategory.screening,
      fromWeek: 24,
      toWeek: 28,
    ),
    CareTemplateItem.weeks(
      // İndirekt Coombs tekrarı; negatifse anti-D. Uygulama kan grubunu
      // bilmiyor — herkese "yapılmalı" demek yanlış olur.
      code: 'tr_screen_antid',
      category: CareCategory.screening,
      fromWeek: 28,
      toWeek: 28,
      conditionKey: 'care_condition_rh_negative',
    ),

    // ── Destek ve aşılar ──
    CareTemplateItem.weeks(
      code: 'tr_supp_vitd', // 1200 IU (9 damla) günlük
      category: CareCategory.supplement,
      fromWeek: 12,
      toWeek: 40,
    ),
    CareTemplateItem.weeks(
      code: 'tr_vacc_tetanus',
      category: CareCategory.vaccine,
      fromWeek: 12,
      toWeek: 40,
      conditionKey: 'care_condition_tetanus_history',
    ),
    CareTemplateItem.weeks(
      code: 'tr_supp_iron',
      category: CareCategory.supplement,
      fromWeek: 16,
      toWeek: 40,
      conditionKey: 'care_condition_no_anemia',
    ),
  ];

  /// T.C. Sağlık Bakanlığı, *Doğum Sonu Bakım Yönetim Rehberi*, Ankara 2018.
  ///
  /// Altı izlemin ilk üçü doğumdan sonraki ilk 24 saatte, hastanede; o sırada
  /// uygulamanın yapacağı bir şey yok. Hatırlatılacak olanlar evde ya da
  /// sağlık kuruluşunda yapılan son üçü — unutulabilir olanlar bunlar.
  static const List<CareTemplateItem> turkeyPostnatal = [
    CareTemplateItem.daysAfterBirth(
      code: 'tr_pp_visit_4',
      category: CareCategory.visit,
      fromDay: 2,
      toDay: 5,
    ),
    CareTemplateItem.daysAfterBirth(
      code: 'tr_pp_visit_5',
      category: CareCategory.visit,
      fromDay: 13,
      toDay: 17,
    ),
    CareTemplateItem.daysAfterBirth(
      code: 'tr_pp_visit_6',
      category: CareCategory.visit,
      fromDay: 30,
      toDay: 42,
    ),
    // Rehber §5.11: lohusalıkta demir ve D vitamini desteği sürüyor.
    // Doğum gününe bildirim düşmesin diye varsayılan olarak hatırlatılmıyor.
    CareTemplateItem.daysAfterBirth(
      code: 'tr_pp_supplements',
      category: CareCategory.supplement,
      fromDay: 2,
      toDay: 42,
      remindByDefault: false,
    ),
  ];

  /// Şablondan gebeliğe bağlı olaylar üretir.
  ///
  /// İlk izlem için rehberin özel kuralı uygulanıyor: *"14. gebelik
  /// haftasından sonraki gebe tespitleri, gebelik haftasına bakılmaksızın İlk
  /// İzlem olarak değerlendirilir."* Gebeliğini 20. haftada işaretleyen
  /// kullanıcıya birinci izlem "kaçırıldı" diye gösterilmiyor; pencere
  /// işaretleme gününden başlıyor ve bir hafta sürüyor.
  ///
  /// Penceresi geçmiş taramalar **atılmıyor**: kullanıcı onları yaptırmış
  /// olabilir, "yapıldı" diye işaretleyebilmeli.
  static List<CareEvent> generate(
    Pregnancy pregnancy,
    List<CareTemplateItem> template,
  ) {
    final onayGunu = pregnancy.confirmedAt.daysSince(pregnancy.gestationStart);

    return [
      for (final k in template)
        () {
          var from = k.fromDay;
          var to = k.toDay;
          if (k.code == 'tr_visit_1' && onayGunu > k.toDay) {
            from = onayGunu;
            to = onayGunu + 6;
          }
          return CareEvent(
            id: '${pregnancy.id}_${k.code}',
            pregnancyId: pregnancy.id,
            code: k.code,
            category: k.category,
            anchor: k.anchor,
            fromDay: from,
            toDay: to,
            conditionKey: k.conditionKey,
            reminderOn: k.remindByDefault,
          );
        }(),
    ];
  }
}
