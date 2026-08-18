import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../domain/services/widget_snapshot.dart';

/// Ana ekran widget'ına veri yazar.
///
/// Widget ayrı bir süreçte çalışıyor; uygulamanın belleğine erişemiyor.
/// Paylaşım App Group üzerinden.
class WidgetDatasource {
  /// iOS entitlement'larındaki grup kimliğiyle **aynı** olmalı.
  static const String appGroupId = 'group.com.furkan.rcperiodtracker';

  /// `WidgetKit`'teki `kind` değeriyle aynı.
  static const String iOSWidgetName = 'CycleWidget';

  const WidgetDatasource();

  /// Özeti paylaşılan depoya yazar ve widget'ı yeniler.
  ///
  /// Sessizce başarısız olur: widget güncellenemezse uygulamanın kendisi
  /// çalışmaya devam etmeli.
  Future<void> publish(WidgetSnapshot snapshot) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);

      for (final entry in snapshot.toMap().entries) {
        await HomeWidget.saveWidgetData(entry.key, entry.value);
      }

      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    } on Exception catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
