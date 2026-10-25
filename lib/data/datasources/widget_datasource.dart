import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/platform/app_platform.dart';
import '../../domain/models/home_widget_entry.dart';

/// Ana ekran widget'ına veri yazar.
///
/// Widget ayrı bir süreçte çalışıyor; uygulamanın belleğine erişemiyor.
/// Paylaşım iOS'ta App Group, Android'de `home_widget`'ın paylaşılan
/// tercihleri üzerinden; iki tarafta da anahtarlar aynı.
class WidgetDatasource {
  /// iOS entitlement'larındaki grup kimliğiyle **aynı** olmalı.
  static const String appGroupId = 'group.com.furkan.rcperiodtracker';

  /// `WidgetKit`'teki `kind` değeriyle aynı.
  static const String iOSWidgetName = 'CycleWidget';

  /// Android'de her boy ayrı sağlayıcı (`NiluWidget.kt`); tam sınıf adları.
  static const String androidSmall =
      'com.furkan.rcperiodtracker.NiluWidgetSmall';
  static const String androidMedium =
      'com.furkan.rcperiodtracker.NiluWidgetMedium';

  const WidgetDatasource();

  /// Android: başlatıcı widget'ın uygulamanın içinden eklenmesine izin
  /// veriyor mu (Android 8+, başlatıcıya bağlı).
  Future<bool> canPin() async {
    if (!AppPlatform.isAndroid) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } on Exception catch (e) {
      debugPrint('Widget pin support check failed: $e');
      return false;
    }
  }

  /// Sistemin "ana ekrana ekle" penceresini açar; yerini kullanıcı seçiyor.
  Future<void> pin({required bool medium}) async {
    try {
      await HomeWidget.requestPinWidget(
        qualifiedAndroidName: medium ? androidMedium : androidSmall,
      );
    } on Exception catch (e) {
      debugPrint('Widget pin request failed: $e');
    }
  }

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
      if (AppPlatform.isAndroid) {
        await HomeWidget.updateWidget(qualifiedAndroidName: androidSmall);
        await HomeWidget.updateWidget(qualifiedAndroidName: androidMedium);
      } else {
        await HomeWidget.updateWidget(iOSName: iOSWidgetName);
      }
    } on Exception catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
