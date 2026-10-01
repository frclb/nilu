import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';

/// Gebelikte kanama **regl değildir**.
///
/// Bu, gebelik modunun en olası ve en ağır hatası (bkz. `PREGNANCY_MODE.md`
/// §7.2). Kanama bir `PeriodLog` açarsa iki şey birden bozulur:
///
/// 1. `lastPeriodStart` kayar → gebelik haftası, tahminler ve bütün döngü
///    geçmişi yanlışlanır.
/// 2. Uygulama, hekime götürülmesi gereken bir bulguyu sıradan bir regl
///    günü gibi kaydeder. T.C. Sağlık Bakanlığı rehberinde "vajinal kanama"
///    tehlike işaretleri listesinde.
///
/// Bu oturumda düzelttiğimiz halka/takvim hatalarının hepsi aynı sınıftandı
/// — aynı veriden iki ayrı cevap — ama burada sonucu çok daha ağır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bugun = DateTime(2026, 6, 1);

  Future<CalendarViewModel> gebeModel() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    // Gebelikten önceki gerçek regl geçmişi dursun: korumanın bunlara
    // dokunmadığını da görmek istiyoruz.
    await const PeriodRepository().savePeriodLogs([
      PeriodLog(
        id: 'eski',
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2026, 1, 9),
      ),
    ]);
    await const PregnancyRepository().upsert(
      Pregnancy.fromLmp(
        lmp: DateTime(2026, 1, 5),
        cycleLength: 28,
        confirmedAt: DateTime(2026, 2, 10),
      ),
    );

    final vm = CalendarViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return vm;
  }

  test('gebeyken gün işaretlemek regl kaydı açmıyor', () async {
    final vm = await gebeModel();
    final once = vm.periodLogs.length;
    final ilkBaslangic = vm.cycleInfo.lastPeriodStart;

    final sonuc = await vm.togglePeriodDay(bugun);

    expect(
      sonuc,
      isFalse,
      reason: 'İşlem reddedilmeli ki arayüz kullanıcıya sebebini söyleyebilsin',
    );
    expect(vm.periodLogs, hasLength(once), reason: 'Yeni kayıt açılmamalı');
    expect(
      vm.cycleInfo.lastPeriodStart,
      ilkBaslangic,
      reason:
          'lastPeriodStart kayarsa gebelik haftası ve bütün tahminler '
          'yanlışlanır',
    );
  });

  test('gebeyken regl başlatma ve bitirme reddediliyor', () async {
    final vm = await gebeModel();
    final once = vm.periodLogs.map((l) => l.toJson()).toList();

    expect(await vm.startPeriodToday(), isFalse);
    expect(await vm.endPeriodToday(), isFalse);
    expect(await vm.undoPeriodStart(), isFalse);
    expect(await vm.reopenPeriodToday(), isFalse);

    expect(
      vm.periodLogs.map((l) => l.toJson()).toList(),
      once,
      reason: 'Hiçbir giriş noktası kayıtlara dokunmamalı',
    );
  });

  test('gebelik bittiğinde kayıt yeniden açılabiliyor', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    const repo = PregnancyRepository();
    final g = Pregnancy.fromLmp(
      lmp: DateTime(2026, 1, 5),
      cycleLength: 28,
      confirmedAt: DateTime(2026, 2, 10),
    );
    await repo.upsert(
      g.ended(outcome: PregnancyOutcome.birth, at: DateTime(2026, 5, 1)),
    );

    final vm = CalendarViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(
      await vm.togglePeriodDay(bugun),
      isTrue,
      reason:
          'Gebelik bittikten sonra kullanıcı yine kendi döngüsünü tutuyor; '
          'koruma kalıcı olursa uygulama kullanılamaz hâle gelir',
    );
  });

  test('gebelik yokken davranış değişmiyor', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});

    final vm = CalendarViewModel();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(await vm.togglePeriodDay(bugun), isTrue);
  });

  /// Regl kayıtlarını değiştiren her giriş noktası korumadan geçmeli.
  ///
  /// Yukarıdaki davranış testleri bugünkü beş metodu sayıyor. Yarın altıncısı
  /// eklenirse onlar sessizce yetersiz kalır — bu tarama o boşluğu kapatıyor.
  test('kayıtları değiştiren her metot korumalı', () {
    final kaynak = File(
      'lib/presentation/calendar/view_models/calendar_view_model.dart',
    ).readAsStringSync();

    // `_periodLogs = ...` atamasını içeren metotları bul.
    final satirlar = kaynak.split('\n');
    final metotDeseni = RegExp(r'^\s{2}(?:Future<[^>]+>|void|bool)\s+(\w+)\(');

    String? suAnkiMetot;
    final mutasyonYapanlar = <String>{};
    for (final satir in satirlar) {
      final m = metotDeseni.firstMatch(satir);
      if (m != null) suAnkiMetot = m.group(1);
      if (satir.contains('_periodLogs =') && suAnkiMetot != null) {
        mutasyonYapanlar.add(suAnkiMetot);
      }
    }

    // Korumayı taşıyan ya da taşıması gerekmeyen metotlar.
    const beklenen = {
      'togglePeriodDay',
      'startPeriodToday',
      'endPeriodToday',
      'undoPeriodStart',
      'reopenPeriodToday',
      '_loadData', // yükleme: depodan okuyor, kullanıcı girişi değil
    };

    expect(
      mutasyonYapanlar.difference(beklenen),
      isEmpty,
      reason:
          'Regl kayıtlarını değiştiren yeni bir metot eklenmiş ve gebelik '
          'koruması listesine girmemiş. Gebelikte kanama regl kaydı açarsa '
          'lastPeriodStart kayar ve bütün tahminler bozulur.',
    );
    expect(
      mutasyonYapanlar,
      contains('togglePeriodDay'),
      reason: 'Tarama hiçbir şey bulamadıysa desen bozulmuş demektir',
    );
  });
}
