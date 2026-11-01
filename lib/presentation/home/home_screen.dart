import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/view_models/user_view_model.dart';
import '../calendar/view_models/calendar_view_model.dart';
import 'widgets/home_header.dart';
import 'widgets/cycle_masthead.dart';
import 'widgets/period_toggle_button.dart';
import 'widgets/daily_suggestion_card.dart';
import 'widgets/two_column_widgets.dart';
import 'widgets/intimacy_section.dart';
import 'widgets/log_entry_fab.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../tour/app_tour.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Partner modunda kayıt girilmiyor: ne "+" düğmesi ne de yakınlık
    // bölümü gösteriliyor. İkisi aynı koşuldan besleniyor ama ayrı isimle
    // duruyorlar; biri değişirse diğeri sessizce peşinden gitmesin.
    final isOwner = !context.watch<UserViewModel>().isPartner;
    final showFab = isOwner;

    final screen = Scaffold(
      // FAB elle `Positioned` ile yerleştiriliyordu: güvenli alanı ve
      // klavyeyi hesaba katmıyordu. Scaffold'un kendi yuvası ikisini de
      // yapıyor.
      // Düğme ekranın sağ kenarına değil içerik sütununa hizalanıyor;
      // geniş ekranda aradaki boşlukta yapayalnız kalıyordu.
      floatingActionButtonLocation: const ContentEndFloatFab(),
      floatingActionButton: showFab
          ? const TourAnchor(id: 'log_fab', child: LogEntryFab())
          : null,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: AppContentWidth(
            child: RefreshIndicator(
              onRefresh: () => context.read<CalendarViewModel>().refreshData(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: HomeBrandBar()),
                  const SliverToBoxAdapter(
                    child: HomeHeader(trailing: HomePhasePill()),
                  ),
                  SliverPadding(
                    // Listenin sonu FAB'ın altında kalmasın.
                    padding: EdgeInsets.only(bottom: showFab ? 104 : 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const TourAnchor(
                          id: 'masthead',
                          child: CycleMasthead(),
                        ),
                        const TourAnchor(
                          id: 'period',
                          child: PeriodToggleButton(),
                        ),
                        DailySuggestionCard(reserveFabSpace: showFab),
                        const TwoColumnWidgets(),
                        if (isOwner) const IntimacySection(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // İlk girişte neyin nerede olduğunu anlatan tur (bkz. `AppTour`).
    // Partnerin ana ekranında kayıt yok; tur onun için değil.
    return isOwner ? HomeTourLauncher(child: screen) : screen;
  }
}
