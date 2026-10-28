import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Gün sayısı çarkı: başlıklı kartın içinde, seçili satır dolu bir hap.
///
/// Regl süresi ve döngü süresi ekranları aynı çarkı kullanıyor. Çark
/// dikey kalıyor: yatay bir şerit 25 seçenekte (21–45) parmağın altında
/// kayboluyor, dikey çark iOS'un saat seçicisiyle aynı alışkanlık.
class OnboardingDayWheel extends StatelessWidget {
  const OnboardingDayWheel({
    super.key,
    required this.controller,
    required this.min,
    required this.max,
    required this.selected,
    required this.onSelected,
    required this.label,
    required this.icon,
    this.highlight,
  });

  final FixedExtentScrollController controller;
  final int min;
  final int max;
  final int selected;
  final ValueChanged<int> onSelected;

  /// Kartın başlığı ("Kanama Süresi").
  final String label;
  final IconData icon;

  /// Seçili hapın dolgusu. Verilmezse markanın ana degradesi.
  final Gradient? highlight;

  /// Çarkın satır yüksekliği. Testler sürüklemeyi buna göre ölçüyor.
  static const double itemExtent = 60;

  /// Görünen yükseklik: seçili satırın üstünde ve altında ikişer satır.
  static const double _height = 240;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: AppCard.decoration(t),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIconTile(
                icon: icon,
                size: 32,
                circle: true,
                background: t.brandTint,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(child: AppSectionLabel(label, color: scheme.primary)),
              const SizedBox(width: 8),
              AppTag(
                label: context.tr(
                  'cycle_settings_days',
                  params: {'n': '$min–$max'},
                ),
                background: t.surfaceAlt,
                foreground: t.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Seçili satırın hapı. Çarkın arkasında: rakam üstünde
                // kayarken hap yerinde duruyor.
                Container(
                  height: itemExtent - 4,
                  decoration: BoxDecoration(
                    gradient: highlight ?? AppGradients.primary(context),
                    borderRadius: BorderRadius.circular(AppRadius.md + 2),
                    boxShadow: AppShadows.floating(context),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: itemExtent,
                  perspective: 0.005,
                  diameterRatio: 2.0,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) => onSelected(index + min),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: max - min + 1,
                    builder: (context, index) {
                      final days = index + min;
                      // Hapın altındaki satır çarkın **anlık konumundan**,
                      // ekranın tuttuğu `selected`'tan değil. Önceden
                      // `selected` esas alınıyordu; TestFlight'ta (iPhone,
                      // iOS 27) ortada 28 dururken hap koyu ve rakam soluk
                      // çizildi: iki değer ayrışınca seçili gün hapın
                      // içinde görünmüyordu. `selected` yalnızca çark
                      // yerleşmeden önceki ilk kare için.
                      return ListenableBuilder(
                        listenable: controller,
                        builder: (context, _) {
                          final center = controller.hasClients
                              ? controller.selectedItem
                              : selected - min;
                          final isSelected = index == center;
                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style:
                                  (theme.textTheme.titleLarge ??
                                          const TextStyle())
                                      .copyWith(
                                        fontSize: isSelected ? 26 : 20,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? scheme.onPrimary
                                            : t.textMuted.withAlpha(150),
                                      ),
                              child: Text(
                                context.tr(
                                  'onb_days_count',
                                  params: {'n': '$days'},
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bilmiyorum": varsayılana dönen sessiz düğme.
class OnboardingDontKnowButton extends StatelessWidget {
  const OnboardingDontKnowButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: t.textMuted,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: const Icon(Icons.help_outline, size: 18),
        label: Text(context.tr('onb_dont_know')),
      ),
    );
  }
}
