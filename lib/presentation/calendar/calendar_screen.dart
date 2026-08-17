import 'package:flutter/material.dart';
import 'widgets/calendar_app_bar.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/calendar_summary_section.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/navigation/route_names.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CalendarAppBar(),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Calendar Grid (White background natively rounded)
              SliverToBoxAdapter(child: CalendarGrid()),
              // Summary Section below
              SliverPadding(
                padding: const EdgeInsets.only(
                  bottom: 120,
                ), // padding for FAB & BottomNav
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const CalendarSummarySection(),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              heroTag: 'calendar_fab',
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
