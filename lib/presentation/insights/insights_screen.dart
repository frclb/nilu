import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import 'widgets/insights_app_bar.dart';
import 'widgets/cycle_alert_card.dart';
import 'widgets/cycle_trend_card.dart';
import 'widgets/symptom_analysis_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: const InsightsAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: 100,
        ),
        child: Column(
          children: const [
            // Uyarı varsa en üstte; yoksa hiç çizilmiyor.
            CycleAlertCard(),
            CycleTrendCard(),
            SizedBox(height: 24),
            SymptomAnalysisCard(),
          ],
        ),
      ),
    );
  }
}
