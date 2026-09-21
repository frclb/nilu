import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../domain/services/phase_guide.dart';
import '../../calendar/view_models/calendar_view_model.dart';

class DailySuggestionCard extends StatelessWidget {
  /// Ana ekranın "+" düğmesi için sağda yer bırakılsın mı?
  ///
  /// Bu, kaydırma alanındaki **tek sağa yaslı dokunulabilir** öğe; FAB da
  /// sağa yaslı. İkisi aynı sütunda olduğu için "Tümünü Gör" düğmenin altında
  /// kalıyor ve okunmuyordu. Kartların üstünden geçmesi sorun değil — onlar
  /// köşeye yaslı bağlantı değil.
  final bool reserveFabSpace;

  const DailySuggestionCard({super.key, this.reserveFabSpace = false});

  /// FAB'ın kapladığı genişlik: 56 çap + 24 kenar boşluğu + 8 pay.
  static const double _fabClearance = 88;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();
    final phase = viewModel.cycleInfo.currentPhase;
    final guidance = PhaseGuide.forPhase(phase);
    final phaseColor = phase.color(context.tokens);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: reserveFabSpace ? _fabClearance : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  context.tr('home_daily_suggestion_title'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
                // Dokunma hedefi 10 piksellik bir yazıydı — parmakla
                // isabet ettirmek zordu. `TextButton` en az 48 piksellik bir
                // alan veriyor.
                TextButton(
                  onPressed: () =>
                      NavigationService().push(RouteNames.healthLibrary),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    context.tr('home_see_all'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Faz renginde gradient banner.
                //
                // Renk artık fazdan türetiliyor; öncesinde her öneri kendi
                // sabit rengini taşıyordu (yumurtlama önerisi açık maviydi)
                // ve kart paletin dışına düşüyordu.
                Container(
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        phaseColor.withAlpha(64),
                        phaseColor.withAlpha(18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _iconFor(guidance.activity),
                      size: 40,
                      color: phaseColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              context.tr(guidance.activityTitleKey),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: theme.colorScheme.onSurface.withAlpha(
                                  153,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                context.tr(
                                  'duration_minutes',
                                  params: {'n': '${guidance.activityMinutes}'},
                                ),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(guidance.activityDescKey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            NavigationService().push(
                              detailRouteFor(guidance.activity),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            context.tr('home_start_button'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Aktivite türünü ikona çevirir.
  ///
  /// İkon seçimi sunum katmanının işi; [PhaseGuide] `material` içe aktarmadan
  /// saf kalsın diye eşleme burada.
  IconData _iconFor(PhaseActivity activity) => switch (activity) {
    PhaseActivity.yinYoga => Icons.self_improvement,
    PhaseActivity.strength => Icons.fitness_center,
    PhaseActivity.cardio => Icons.directions_run,
    PhaseActivity.meditation => Icons.spa,
    PhaseActivity.gentle => Icons.favorite_border,
  };
}

/// Önerinin açacağı detay ekranı.
///
/// Düğme, öneri ne olursa olsun yoga ekranını açıyordu: kullanıcı "Kardiyo"
/// okuyup "Başla"ya bastığında karşısına yoga çıkıyordu. Güç ve kardiyo
/// egzersiz ekranına, yumuşak hareket türleri yogaya gidiyor.
///
/// Meditasyon da yogaya gidiyor: elde ayrı bir meditasyon içeriği yok ve
/// yoga ekranı gevşeme odaklı. Uydurma bir ekrana yönlendirmektense en
/// yakın gerçek içerik.
String detailRouteFor(PhaseActivity activity) => switch (activity) {
  PhaseActivity.strength || PhaseActivity.cardio => RouteNames.exerciseDetail,
  PhaseActivity.yinYoga ||
  PhaseActivity.gentle ||
  PhaseActivity.meditation => RouteNames.yogaDetail,
};
