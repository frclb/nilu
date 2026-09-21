import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/domain/services/phase_guide.dart';
import 'package:period_tracker/presentation/home/widgets/daily_suggestion_card.dart';

/// Günün önerisindeki "Başla" düğmesi doğru ekranı açmalı.
///
/// Düğme, öneri ne olursa olsun yoga ekranını açıyordu: kullanıcı "Kardiyo"
/// okuyup "Başla"ya basınca karşısına yoga çıkıyordu. Egzersiz ekranı
/// yazılmıştı ama ona giden yol hiç kurulmamıştı — rota tabloda duruyor,
/// kapısı yok.
void main() {
  test('hareket türü egzersiz ekranını açıyor', () {
    for (final activity in [PhaseActivity.strength, PhaseActivity.cardio]) {
      expect(detailRouteFor(activity), RouteNames.exerciseDetail,
          reason: '${activity.name} için yoga ekranı açılıyordu.');
    }
  });

  test('yumuşak türler yoga ekranını açıyor', () {
    for (final activity in [
      PhaseActivity.yinYoga,
      PhaseActivity.gentle,
      PhaseActivity.meditation,
    ]) {
      expect(detailRouteFor(activity), RouteNames.yogaDetail);
    }
  });

  test('her etkinlik türünün bir karşılığı var', () {
    // `switch` tüm değerleri kapsıyor; yeni bir tür eklenirse burada da
    // görünsün diye sayı kontrol ediliyor.
    expect(PhaseActivity.values, hasLength(5));
    for (final activity in PhaseActivity.values) {
      expect(detailRouteFor(activity), isNotEmpty);
    }
  });
}
