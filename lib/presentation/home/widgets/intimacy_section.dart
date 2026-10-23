import '../../../design_system/app_tappable.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import 'package:provider/provider.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/relative_time.dart';

/// Ana ekrandaki duygusal yakınlık bölümü — iki küçük kompakt kart.
/// Tıklandığında BottomSheet ile detaylı seçim yapılır.
///
/// Yalnızca onaylanmış bir partner varken ve paylaşıma açık rıza
/// verilmişken görünüyor. Önceden herkesin ana ekranında "Cinsel İstek"
/// kartı duruyordu: partneri olmayan kullanıcı için anlamsız, telefona göz
/// atan biri için de fazla açık.
class IntimacySection extends StatelessWidget {
  const IntimacySection({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<IntimacyViewModel>();

    if (!viewModel.isLoaded || !viewModel.hasPartner || !viewModel.sharingOn) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // İki kart aynı boyda; büyük yazıda birlikte uzuyorlar.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kart 1 — Cinsel İstek
                Expanded(child: _MiniDesireCard(viewModel: viewModel)),
                const SizedBox(width: 12),
                // Kart 2 — Sevgi İhtiyacı
                Expanded(child: _MiniAffectionCard(viewModel: viewModel)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ShareControls(viewModel: viewModel),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAYLAŞIM KONTROLLERİ
//
// Bu bölüm eksikti: kullanıcı seçimlerini yapıyor ama partnerine hiç
// gönderilmiyordu. Otomatik paylaşım varsayılan olarak kapalıydı ve açacak
// bir arayüz yoktu; manuel gönderme düğmesi de yoktu. ViewModel tarafındaki
// manualShare / isSharing / shareError / remainingShares hiçbir yerde
// kullanılmıyordu.
// ══════════════════════════════════════════════════════════════

class _ShareControls extends StatelessWidget {
  final IntimacyViewModel viewModel;

  const _ShareControls({required this.viewModel});

  bool get _hasSelection =>
      viewModel.selectedSexualDesire != null ||
      viewModel.selectedAffectionNeeds.isNotEmpty;

  String? _errorMessage(BuildContext context) {
    switch (viewModel.shareError) {
      case 'rate_limit_exceeded':
        return context.tr('intimacy_rate_limit_msg');
      case 'share_failed':
        return context.tr('intimacy_share_failed_msg');
      case 'sharing_disabled':
        return context.tr('intimacy_sharing_disabled_msg');
      case 'no_partner':
        return context.tr('intimacy_no_partner_desc');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _errorMessage(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(context.tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Otomatik paylaşım
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('intimacy_auto_share_label'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('intimacy_auto_share_desc'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: viewModel.isAutoShareEnabled,
                onChanged: viewModel.setAutoShareEnabled,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Manuel paylaşım
          FilledButton.icon(
            onPressed: (viewModel.isSharing || !_hasSelection)
                ? null
                : viewModel.manualShare,
            icon: viewModel.isSharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(context.tr('intimacy_share_button')),
          ),

          // Son paylaşım / kalan hak
          if (viewModel.lastSharedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${context.tr('intimacy_last_shared')}: '
              '${context.relativeTime(DateTime.now().difference(viewModel.lastSharedAt!))}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (viewModel.canShare && viewModel.lastSharedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              context.tr(
                'intimacy_remaining_shares',
                params: {'count': '${viewModel.remainingShares}'},
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],

          // Hata
          if (error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: viewModel.clearError,
                  icon: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ],
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

    return AppTappable(
      onTap: () => _showDesireSheet(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 124),
        padding: const EdgeInsets.all(14),
        decoration: _miniCardDecoration(context, selected: hasSelection),
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
                color: context.tokens.secondary.withAlpha(22),
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
                        color: context.tokens.secondaryTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: context.tokens.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('intimacy_sexual_desire_title'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                          color: context.tokens.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const SizedBox(height: 10),
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
            color: context.tokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: context.tokens.textFaint.withAlpha(80),
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

    return AppTappable(
      onTap: () => _showAffectionSheet(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 124),
        padding: const EdgeInsets.all(14),
        decoration: _miniCardDecoration(context, selected: hasSelection),
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
                color: context.tokens.secondary.withAlpha(22),
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
                        color: context.tokens.secondaryTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.volunteer_activism_rounded,
                        size: 14,
                        color: context.tokens.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('intimacy_affection_title'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                          letterSpacing: 0.5,
                          color: context.tokens.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const SizedBox(height: 10),
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
                          ? context.tr(
                              'intimacy_selected_count',
                              params: {'n': '${needs.length}'},
                            )
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
                color: context.tokens.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
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
                        color: context.tokens.textFaint.withAlpha(80),
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
                      return AppTappable(
                        selected: isSelected,
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
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.tr('ok')),
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

/// Mini kartların zemini: beyaz kart; seçim varsa gül tonlu kenar.
BoxDecoration _miniCardDecoration(
  BuildContext context, {
  required bool selected,
}) {
  final t = context.tokens;
  return BoxDecoration(
    color: t.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: selected ? t.secondary.withAlpha(90) : AppCard.borderColor(t),
      width: selected ? 1.5 : 1,
    ),
    boxShadow: AppShadows.soft(context),
  );
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
      child: AppTappable(
        selected: isSelected,
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
