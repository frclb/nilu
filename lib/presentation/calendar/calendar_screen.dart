import 'package:flutter/material.dart';
import 'widgets/calendar_app_bar.dart';
import 'widgets/calendar_day_header.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/calendar_summary_section.dart';

/// Takvim ekranı.
///
/// Ekran üç parçadan oluşur ve sıraları bilinçlidir:
///
/// 1. [CalendarGrid] — ay ızgarası ve renk açıklamaları.
/// 2. [CalendarDayHeader] — seçili günün tarihi, durumu ve o güne uygulanan
///    eylemler ("Regl işaretle", "Not ekle").
/// 3. [CalendarSummarySection] — o güne girilmiş kayıtların özeti.
///
/// Önceki düzende iki sorun vardı: eylem düğmeleri, üzerinde çalıştıkları
/// günün bilgisinden **önce** geliyordu; tarih ve döngü günü ise arka arkaya
/// **iki kez** yazılıyordu (ızgaranın altındaki kutu ve özet başlığı).
///
/// Ayrıca burada bir FAB vardı; `logEntry` ekranını (her zaman bugünün kaydı)
/// açıyor, hem "Not ekle" düğmesinin üstüne biniyor hem de seçili günle
/// çakışıyordu. Kaldırıldı — "bugüne kayıt ekle" ana ekrandaki FAB'ın işi.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CalendarAppBar(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: CalendarGrid()),
          const SliverToBoxAdapter(child: CalendarDayHeader()),
          SliverPadding(
            // Alt menü çubuğunun altında kalan içerik olmasın.
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const CalendarSummarySection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
