import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../domain/models/home_widget_entry.dart';

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

  /// Önceki sürümün yazdığı anahtarlar. Yeni widget onları okumuyor;
  /// paylaşılan depoda sağlık bilgisi gereksiz yere kalmasın.
  static const List<String> _eskiAnahtarlar = [
    'cycleDay',
    'daysUntilPeriod',
    'phaseKey',
    'hasData',
  ];

  /// Önümüzdeki günlerin girdilerini yazar ve widget'ı yeniler.
  ///
  /// [staleText]: girdiler bittiğinde (uygulama uzun süre açılmadıysa)
  /// widget'ın göstereceği metin. Anahtar adları `CycleWidget.swift` ile
  /// aynı olmalı.
  ///
  /// Sessizce başarısız olur: widget güncellenemezse uygulamanın kendisi
  /// çalışmaya devam etmeli.
  Future<void> publish(
    List<HomeWidgetEntry> entries, {
    required String staleText,
  }) async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      await HomeWidget.saveWidgetData(
        'entries',
        jsonEncode([for (final e in entries) e.toJson()]),
      );
      await HomeWidget.saveWidgetData('staleText', staleText);
      for (final k in _eskiAnahtarlar) {
        // `null` anahtarı siliyor.
        await HomeWidget.saveWidgetData<Object>(k, null);
      }
      await HomeWidget.updateWidget(iOSName: iOSWidgetName);
    } on Exception catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
