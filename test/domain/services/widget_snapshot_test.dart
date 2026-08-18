import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';
import 'package:period_tracker/domain/services/widget_snapshot.dart';

void main() {
  test('kayıt yokken widget veri yok der', () {
    // Boş bir daire göstermek anlamsız; widget "kayıt ekle" demeli.
    final info = PredictionService().getCycleInfo(const []);
    final snapshot = WidgetSnapshot.from(info);

    expect(snapshot.hasData, isFalse);
    expect(snapshot.cycleDay, isNull);
    expect(snapshot.phaseKey, 'unknown');
  });

  test('kayıt varken döngü günü ve faz taşınır', () {
    final start = DateTime.now().subtract(const Duration(days: 2));
    final info = PredictionService().getCycleInfo([
      PeriodLog(id: '1', startDate: start),
    ]);
    final snapshot = WidgetSnapshot.from(info);

    expect(snapshot.hasData, isTrue);
    expect(snapshot.cycleDay, 3);
    expect(snapshot.phaseKey, 'menstruation');
  });

  test('haritada yalnızca özet alanlar var', () {
    // Ham sağlık kaydı paylaşılan depoya yazılmamalı: orası uygulamanın
    // şifreli deposu kadar korumalı değil.
    final info = PredictionService().getCycleInfo([
      PeriodLog(id: '1', startDate: DateTime.now()),
    ]);

    expect(WidgetSnapshot.from(info).toMap().keys.toSet(), {
      'cycleDay',
      'daysUntilPeriod',
      'phaseKey',
      'hasData',
    });
  });
}
