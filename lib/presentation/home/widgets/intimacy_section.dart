import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

/// Ana ekrandaki duygusal yakınlık bölümü — iki küçük kompakt kart.
/// Tıklandığında BottomSheet ile detaylı seçim yapılır.
class IntimacySection extends StatelessWidget {
  const IntimacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IntimacyViewModel>();

    if (!viewModel.isLoaded) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Kart 1 — Cinsel İstek
          Expanded(child: _MiniDesireCard(viewModel: viewModel)),
          const SizedBox(width: 12),
          // Kart 2 — Sevgi İhtiyacı
          Expanded(child: _MiniAffectionCard(viewModel: viewModel)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MİNİ KART 1 — Cinsel İstek
// ══════════════════════════════════════════════════════════════

class _MiniDesireCard extends StatelessWidget {
  final IntimacyViewModel viewModel;
  const _MiniDesireCard({required this.viewModel});

  static const _desireIcons = {
    'no_interest': Icons.do_not_disturb_on_outlined,
    'slight_closeness': Icons.sentiment_neutral_outlined,
    'feel_closer': Icons.favorite_border_rounded,
    'passionate': Icons.local_fire_department_rounded,
  };

  String _getDesireLabel(BuildContext context, String? key) {
    if (key == null) return context.tr('intimacy_desire_no_interest');
    final map = {
      'no_interest': context.tr('intimacy_desire_no_interest'),
      'slight_closeness': context.tr('intimacy_desire_slight'),
      'feel_closer': context.tr('intimacy_desire_closer'),
      'passionate': context.tr('intimacy_desire_passionate'),
    };
    return map[key] ?? context.tr('intimacy_desire_no_interest');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = viewModel.selectedSexualDesire;
    final icon = _desireIcons[selected] ?? Icons.favorite_border_rounded;
    final hasSelection = selected != null;

    return GestureDetector(
      onTap: () => _showDesireSheet(context),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelection
                ? theme.colorScheme.primary.withAlpha(60)
                : theme.colorScheme.outline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Arka plan dekoratif ikon
            Positioned(
              right: -6,
              bottom: -6,
              child: Icon(
                Icons.favorite_rounded,
                size: 48,
                color: theme.colorScheme.primary.withAlpha(12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('intimacy_sexual_desire_title'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  hasSelection
                      ? _getDesireLabel(context, selected)
                      : context.tr('intimacy_pick'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 12,
                      color: theme.textTheme.labelLarge?.color?.withAlpha(120),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.tr('intimacy_change'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.textTheme.labelLarge?.color?.withAlpha(
                          120,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDesireSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final options = [
      _Option(
        'no_interest',
        context.tr('intimacy_desire_no_interest'),
        Icons.do_not_disturb_on_outlined,
      ),
      _Option(
        'slight_closeness',
        context.tr('intimacy_desire_slight'),
        Icons.sentiment_neutral_outlined,
      ),
      _Option(
        'feel_closer',
        context.tr('intimacy_desire_closer'),
        Icons.favorite_border_rounded,
      ),
      _Option(
        'passionate',
        context.tr('intimacy_desire_passionate'),
        Icons.local_fire_department_rounded,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceWarmDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('intimacy_sexual_desire_title'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = viewModel.selectedSexualDesire == opt.key;
                return _OptionTile(
                  option: opt,
                  isSelected: isSelected,
                  onTap: () {
                    viewModel.selectSexualDesire(opt.key);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MİNİ KART 2 — Sevgi İhtiyacı
// ══════════════════════════════════════════════════════════════

class _MiniAffectionCard extends StatelessWidget {
  final IntimacyViewModel viewModel;
  const _MiniAffectionCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needs = viewModel.selectedAffectionNeeds;
    final hasSelection = needs.isNotEmpty;

    String summaryText;
    if (!hasSelection) {
      summaryText = context.tr('intimacy_pick');
    } else if (needs.length == 1) {
      summaryText = _getNeedLabel(context, needs.first);
    } else {
      summaryText =
          '${_getNeedLabel(context, needs.first)} +${needs.length - 1}';
    }

    return GestureDetector(
      onTap: () => _showAffectionSheet(context),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelection
                ? theme.colorScheme.primary.withAlpha(60)
                : theme.colorScheme.outline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Arka plan dekoratif ikon
            Positioned(
              right: -6,
              bottom: -6,
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 48,
                color: theme.colorScheme.primary.withAlpha(12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('intimacy_affection_title'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  summaryText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 12,
                      color: theme.textTheme.labelLarge?.color?.withAlpha(120),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasSelection
                          ? '${needs.length} seçili'
                          : context.tr('intimacy_change'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.textTheme.labelLarge?.color?.withAlpha(
                          120,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getNeedLabel(BuildContext context, String key) {
    final map = {
      'hug': context.tr('intimacy_need_hug'),
      'kiss': context.tr('intimacy_need_kiss'),
      'be_together': context.tr('intimacy_need_together'),
      'hear_voice': context.tr('intimacy_need_voice'),
      'text': context.tr('intimacy_need_text'),
      'spend_time': context.tr('intimacy_need_spend_time'),
      'attention': context.tr('intimacy_need_attention'),
      'alone_time': context.tr('intimacy_need_alone'),
    };
    return map[key] ?? key;
  }

  void _showAffectionSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final options = [
      _Option(
        'hug',
        context.tr('intimacy_need_hug'),
        Icons.accessibility_new_rounded,
      ),
      _Option(
        'kiss',
        context.tr('intimacy_need_kiss'),
        Icons.emoji_emotions_outlined,
      ),
      _Option(
        'be_together',
        context.tr('intimacy_need_together'),
        Icons.people_outline_rounded,
      ),
      _Option(
        'hear_voice',
        context.tr('intimacy_need_voice'),
        Icons.phone_in_talk_outlined,
      ),
      _Option(
        'text',
        context.tr('intimacy_need_text'),
        Icons.chat_bubble_outline_rounded,
      ),
      _Option(
        'spend_time',
        context.tr('intimacy_need_spend_time'),
        Icons.coffee_outlined,
      ),
      _Option(
        'attention',
        context.tr('intimacy_need_attention'),
        Icons.visibility_outlined,
      ),
      _Option(
        'alone_time',
        context.tr('intimacy_need_alone'),
        Icons.self_improvement_rounded,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceWarmDark : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(80),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('intimacy_affection_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('intimacy_multi_select_hint'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.textTheme.labelLarge?.color?.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: options.map((opt) {
                      final isSelected = viewModel.selectedAffectionNeeds
                          .contains(opt.key);
                      return GestureDetector(
                        onTap: () {
                          viewModel.toggleAffectionNeed(opt.key);
                          setSheetState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(20)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary.withAlpha(160)
                                  : theme.colorScheme.outline,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                opt.icon,
                                size: 16,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.textTheme.labelLarge?.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Tamam Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        context.tr('ok'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
// YARDIMCI MODELLER
// ══════════════════════════════════════════════════════════════

class _Option {
  final String key;
  final String label;
  final IconData icon;
  const _Option(this.key, this.label, this.icon);
}

class _OptionTile extends StatelessWidget {
  final _Option option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withAlpha(15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withAlpha(120)
                  : theme.colorScheme.outline,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                option.icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.labelLarge?.color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
