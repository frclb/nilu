import 'package:flutter/material.dart';

import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import 'cycle_summary_screen.dart';
import 'widgets/cycle_alert_card.dart';
import 'widgets/cycle_history_card.dart';
import 'widgets/cycle_trend_card.dart';
import 'widgets/insights_app_bar.dart';
import 'widgets/symptom_analysis_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      body: AmbientBackground(
        child: Column(
          children: [
            const InsightsAppBar(),
            Expanded(
              child: AppContentWidth(
                // İki analiz kartı geniş ekranda yan yana geliyor; tek
                // sütunun okunur genişliğinde kalsalardı grafikler yarı
                // yarıya daralırdı.
                maxWidth: AppLayout.wideContentMaxWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: InsightsHeader(),
                      ),
                      SizedBox(height: 16),
                      // Uyarı varsa en üstte; yoksa hiç çizilmiyor. Tam
                      // genişlikte kalıyor: bu bir kart değil, ekranın
                      // tamamına seslenen bir uyarı.
                      CycleAlertCard(),
                      AppColumns(
                        children: [CycleTrendCard(), SymptomAnalysisCard()],
                      ),
                      SizedBox(height: 16),
                      // Döngülerin listesi herkese açık; tam genişlikte,
                      // çünkü uzun geçmişte satır satır okunuyor.
                      CycleHistoryCard(),
                      SizedBox(height: 16),
                      // Muayenede gösterilecek özet: ekranda ücretsiz.
                      CycleSummaryLink(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
