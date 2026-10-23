import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/session_plan.dart';
import '../session/session_screen.dart';
import '../widgets/favorite_button.dart';
import 'widgets/yoga_video_player.dart';
import 'widgets/yoga_content_section.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

class YogaDetailScreen extends StatelessWidget {
  const YogaDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('exercise_detail_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 21,
            color: t.text,
          ),
        ),
        actions: const [FavoriteButton(contentId: 'yoga_gentle_flow')],
      ),
      // Başlatma düğmesi `Scaffold`'un altında: gövdedeki bir `Stack`e
      // konduğunda içerik ekrandan kısayken ortada havada kalıyordu.
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: t.background,
          boxShadow: AppShadows.soft(context),
        ),
        child: AppContentWidth(
          child: AppGradientButton(
            // Bu düğme eskiden yalnızca "başlıyor" bildirim çubuğu
            // gösteriyordu; hiçbir şey başlamıyordu.
            label: context.tr('exercise_start'),
            icon: Icons.play_arrow_rounded,
            height: 56,
            radius: AppRadius.pill,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SessionScreen(plan: SessionPlan.yoga),
              ),
            ),
          ),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: const [YogaCover(), YogaContentSection()],
        ),
      ),
    );
  }
}
