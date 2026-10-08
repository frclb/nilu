import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import 'cycle_summary_screen.dart';
import 'widgets/insights_app_bar.dart';
import 'widgets/cycle_alert_card.dart';
import 'widgets/cycle_history_card.dart';
import 'widgets/cycle_trend_card.dart';
import 'widgets/symptom_analysis_card.dart';
import '../../design_system/app_layout.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: const InsightsAppBar(),
      body: AppContentWidth(
        // İki analiz kartı geniş ekranda yan yana geliyor; tek sütunun
        // okunur genişliğinde kalsalardı grafikler yarı yarıya daralırdı.
        maxWidth: AppLayout.wideContentMaxWidth,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: 100,
          ),
          child: Column(
            children: const [
              // Uyarı varsa en üstte; yoksa hiç çizilmiyor. Tam genişlikte
              // kalıyor: bu bir kart değil, ekranın tamamına seslenen bir
              // uyarı şeridi.
              CycleAlertCard(),
              AppColumns(
                spacing: 24,
                children: [CycleTrendCard(), SymptomAnalysisCard()],
              ),
              SizedBox(height: 24),
              // Döngülerin listesi herkese açık; tam genişlikte, çünkü uzun
              // geçmişte satır satır okunuyor.
              CycleHistoryCard(),
              SizedBox(height: 16),
              // Muayenede gösterilecek özet: ekranda ücretsiz.
              CycleSummaryLink(),
            ],
          ),
        ),
      ),
    );
  }
}
