import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/view_models/user_view_model.dart';
import '../calendar/view_models/calendar_view_model.dart';
import 'widgets/home_header.dart';
import 'widgets/cycle_widget.dart';
import 'widgets/daily_suggestion_card.dart';
import 'widgets/two_column_widgets.dart';
import 'widgets/intimacy_section.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/navigation/route_names.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => context.read<CalendarViewModel>().refreshData(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: HomeHeader()),
                SliverPadding(
                  padding: const EdgeInsets.only(
                    bottom: 120,
                  ), // padding for FAB
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const CycleWidget(),
                      const DailySuggestionCard(),
                      const TwoColumnWidgets(),
                      if (!context.watch<UserViewModel>().isPartner)
                        const IntimacySection(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (!context.watch<UserViewModel>().isPartner)
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton(
                heroTag: 'home_fab',
                onPressed: () {
                  NavigationService().push(RouteNames.logEntry);
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                elevation: 4,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 32),
              ),
            ),
        ],
      ),
    );
  }
}
