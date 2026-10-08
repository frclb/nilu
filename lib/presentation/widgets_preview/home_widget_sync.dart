import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/widget_datasource.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../calendar/view_models/calendar_view_model.dart';
import 'home_widget_plan.dart';

/// Ana ekran widget'ının içeriğini güncel tutar.
///
/// Önceden takvim ViewModel'i yayımlıyordu; orada ne dil ne gebelik bilgisi
/// var, widget da metni kendisi Türkçe kuruyordu. Burada ikisi de var:
/// girdiler kullanıcının dilinde ve evresine göre hazırlanıyor.
///
/// Yalnızca içerik değiştiğinde yazılıyor; uygulama öne gelince de yeniden
/// hesaplanıyor (gece yarısı geçmiş olabilir).
class HomeWidgetSync extends StatefulWidget {
  const HomeWidgetSync({
    super.key,
    required this.child,
    @visibleForTesting this.datasource,
    @visibleForTesting this.clock,
  });

  final Widget child;
  final WidgetDatasource? datasource;
  final DateTime Function()? clock;

  @override
  State<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends State<HomeWidgetSync>
    with WidgetsBindingObserver {
  late final WidgetDatasource _ds =
      widget.datasource ?? const WidgetDatasource();
  String? _sonYazilan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final takvim = context.watch<CalendarViewModel>();
    final gebelik = context.watch<PregnancyViewModel>();

    // İkisi de yüklenmeden yazma: gebe kullanıcının widget'ına bir an için
    // döngü girdisi yazılırdı.
    if (!takvim.isLoading && gebelik.loaded) {
      final girdiler = HomeWidgetPlan.build(
        context,
        cycle: takvim.cycleInfo,
        pregnancies: gebelik.pregnancies,
        today: (widget.clock ?? DateTime.now)(),
        afterPregnancy: takvim.cycleBreaks.isNotEmpty,
      );
      final eskimis = context.tr('widget_open_app');
      final imza = jsonEncode([for (final g in girdiler) g.toJson(), eskimis]);
      if (imza != _sonYazilan) {
        _sonYazilan = imza;
        _ds.publish(girdiler, staleText: eskimis);
      }
    }
    return widget.child;
  }
}
