import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/presentation/home/widgets/custom_bottom_nav.dart';

/// Alt menü hedefleri ve bunların `StatefulShellRoute` dallarına eşlenmesi.
///
/// Eşleme sessizce bozulabilecek türden: yanlış dal indeksi derleme hatası
/// vermez, kullanıcı sekmeye basınca başka bir ekrana düşer.
void main() {
  group('standart mod', () {
    test('beş sekme, dal sırasıyla aynı', () {
      final destinations = navDestinations(isPartner: false);

      expect(destinations.length, 5);
      expect(
        destinations.map((d) => d.branchIndex).toList(),
        [0, 1, 2, 3, 4],
        reason: 'router dalları: home, calendar, insights, library, profile',
      );
    });

    test('İçgörüler sekmesi vardır', () {
      // Regresyon: /insights rotası tanımlıydı ama hiçbir yerden bağlantısı
      // yoktu; ekran kullanıcı için erişilemez durumdaydı.
      final labels = navDestinations(
        isPartner: false,
      ).map((d) => d.labelKey).toList();

      expect(labels, contains('nav_insights'));
    });

    test('kütüphane sekmesi kısa etiket kullanır', () {
      // `health_library_title` ("Sağlık Kütüphanesi") ekran başlığıdır ve
      // sekmede iki satıra taşıyordu.
      final library = navDestinations(
        isPartner: false,
      ).firstWhere((d) => d.branchIndex == 3);

      expect(library.labelKey, 'nav_library');
    });
  });

  group('gebelik ve lohusalık', () {
    // Aynı dal gebelikte randevuları gösteriyor (bkz. `app_router.dart`);
    // etiket "İçgörüler" kalsaydı kullanıcı sekmeye basıp başka bir ekran
    // bulurdu.
    for (final stage in [LifeStage.pregnancy, LifeStage.postpartum]) {
      test('${stage.name}: 3. sekme randevular, dallar aynı sırada', () {
        final d = navDestinations(isPartner: false, stage: stage);
        expect(d.map((x) => x.branchIndex).toList(), [0, 1, 2, 3, 4]);
        expect(d.firstWhere((x) => x.branchIndex == 2).labelKey, 'nav_care');
      });
    }

    test('döngüde 3. sekme içgörüler', () {
      expect(
        navDestinations(
          isPartner: false,
        ).firstWhere((x) => x.branchIndex == 2).labelKey,
        'nav_insights',
      );
    });

    test('partner modunda evre hiçbir şeyi değiştirmiyor', () {
      // v1'de partner gebeliğe dair hiçbir şey görmüyor.
      final temel = navDestinations(isPartner: true).map((d) => d.labelKey);
      for (final stage in LifeStage.values) {
        expect(
          navDestinations(isPartner: true, stage: stage).map((d) => d.labelKey),
          temel,
        );
      }
    });
  });

  group('partner modu', () {
    test('üç sekme gösterilir', () {
      expect(navDestinations(isPartner: true).length, 3);
    });

    test('takvim ve İçgörüler dalları atlanır', () {
      // Partnerin cihazında gösterilecek kendi döngü verisi yok, takip
      // edilen kişininki de partnere hiç gitmiyor: paylaşım kanalı
      // yalnızca yakınlık durumunu taşıyor. Takvim sekmesi bu yüzden
      // sabit tarihler gösteren bir maket ekrana bağlıydı.
      final branches = navDestinations(
        isPartner: true,
      ).map((d) => d.branchIndex).toList();

      expect(branches, [0, 3, 4]);
      expect(branches, isNot(contains(1)));
      expect(branches, isNot(contains(2)));
    });

    test('destek sekmesi kütüphane dalına gider', () {
      // 3 numaralı dal partner modunda PartnerSupportScreen döndürüyor;
      // etiket ile dal birbirinden ayrı olduğu için bu kolayca kayabilir.
      final support = navDestinations(
        isPartner: true,
      ).firstWhere((d) => d.labelKey == 'partner_nav_support');

      expect(support.branchIndex, 3);
    });
  });

  test('her sekme farklı bir dala gider', () {
    for (final isPartner in [false, true]) {
      final branches = navDestinations(
        isPartner: isPartner,
      ).map((d) => d.branchIndex).toList();

      expect(
        branches.toSet().length,
        branches.length,
        reason: 'isPartner=$isPartner için yinelenen dal var',
      );
    }
  });

  test('seçili ve seçili olmayan simgeler farklıdır', () {
    // Seçiliyi yalnızca renkle göstermek renk körlüğünde ayırt edilemiyor.
    for (final isPartner in [false, true]) {
      for (final destination in navDestinations(isPartner: isPartner)) {
        expect(
          destination.activeIcon,
          isNot(destination.icon),
          reason: destination.labelKey,
        );
      }
    }
  });

  test('etiket anahtarları altı dilde tanımlıdır', () {
    // Etiketler `context.tr('literal')` yerine değişkenle çözülüyor;
    // `tool/check_localization.dart` regex'i bu anahtarları göremiyor.
    // Kullanımdan düşmüş sanılıp silinmelerini bu test engelliyor.
    final keys = {
      for (final isPartner in [false, true])
        for (final stage in LifeStage.values)
          ...navDestinations(
            isPartner: isPartner,
            stage: stage,
          ).map((d) => d.labelKey),
    };

    for (final language in ['tr', 'en', 'de', 'fr', 'es', 'pt']) {
      final raw = File('lib/localization/$language.json').readAsStringSync();
      final defined = (jsonDecode(raw) as Map<String, dynamic>).keys.toSet();

      expect(
        defined.containsAll(keys),
        isTrue,
        reason: '$language.json eksik: ${keys.difference(defined)}',
      );
    }
  });
}
