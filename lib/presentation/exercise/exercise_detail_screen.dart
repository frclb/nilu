import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/session_plan.dart';
import '../session/session_screen.dart';
import '../../../localization/app_localizations.dart';
import 'widgets/exercise_hero_header.dart';
import 'widgets/exercise_content_section.dart';
import '../../design_system/app_layout.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bottomBarBg = context.tokens.surface; // gradient base

    return Scaffold(
      backgroundColor: context.tokens.background,
      body: AppContentWidth(
        // `Scaffold` gövdeye **gevşek** kısıt veriyor; `Stack` de en uzun
        // konumlandırılmamış çocuğuna göre büzülüyor. İçerik ekrandan
        // kısaysa `Positioned(bottom: 0)` ekranın dibine değil içeriğin
        // dibine yapışıyor ve eylem çubuğu ortada havada kalıyordu.
        // Telefonda içerik ekranı doldurduğu için görünmüyordu.
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Main Scrollable Area
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const ExerciseHeroHeader(),
                    Transform.translate(
                      offset: const Offset(0, -32), // Pull up to overlap header
                      child: const ExerciseContentSection(),
                    ),
                  ],
                ),
              ),

              // Sticky Bottom Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        bottomBarBg,
                        bottomBarBg,
                        bottomBarBg.withAlpha(0),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                  child: ElevatedButton.icon(
                    // Bu düğme yoga detay ekranına atıyordu; kullanıcı orada
                    // ikinci bir "Başlat"a basmak zorunda kalıyordu. İki ekran da
                    // aynı akışı anlatıyor, seans doğrudan buradan başlıyor.
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const SessionScreen(plan: SessionPlan.yoga),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: theme.colorScheme.primary.withAlpha(127),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      context.tr('exercise_start_button'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
