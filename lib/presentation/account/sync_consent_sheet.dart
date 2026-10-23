import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';

/// Bulut eşitleme için açık rıza.
///
/// Sağlık verisi KVKK'da özel nitelikli (m.6) ve sunucular Türkiye dışında
/// olabilir (m.9): ikisi için de açık rıza gerekiyor. Açık rıza **belirli
/// bir konuya ilişkin, bilgilendirilmeye dayanan ve özgür iradeyle**
/// verilmeli; bu yüzden:
///
/// * ne gideceği, nereye gideceği ve nasıl korunduğu (uçtan uca şifreli
///   **olmadığı** dahil) onaydan önce yazıyor,
/// * kutucuk kendiliğinden işaretli değil, işaretlenmeden düğme çalışmıyor,
/// * geri çekmenin yolu ve sonucu baştan söyleniyor.
///
/// Rıza verilmezse hiçbir şey değişmiyor: uygulama yerelde çalışmaya devam
/// ediyor. Rıza verildiyse `true`.
Future<bool> showSyncConsentSheet(BuildContext context) async {
  final sonuc = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ConsentSheet(),
  );
  return sonuc ?? false;
}

class _ConsentSheet extends StatefulWidget {
  const _ConsentSheet();

  @override
  State<_ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends State<_ConsentSheet> {
  bool _onay = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final govde = theme.textTheme.bodyMedium?.copyWith(
      color: t.text,
      height: 1.5,
    );

    Widget madde(IconData icon, String key) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, size: 36, background: t.surfaceAlt),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(context.tr(key), style: govde),
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AppIconTile(
                    icon: Icons.verified_user_outlined,
                    size: 40,
                    circle: true,
                    background: t.secondaryTint,
                    color: t.secondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        context.tr('sync_consent_title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Ne gidiyor, nereye gidiyor (uçtan uca şifreli **olmadığı**
              // dahil), nasıl geri çekilir — onaydan önce, bu sırayla.
              madde(Icons.inventory_2_outlined, 'sync_consent_what'),
              madde(Icons.public, 'sync_consent_where'),
              madde(Icons.undo, 'sync_consent_withdraw'),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => context.pushNamed(RouteNames.privacyPolicy),
                  style: TextButton.styleFrom(
                    foregroundColor: t.secondary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 44),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(context.tr('sync_consent_policy'))),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Kutucuk kendi zemininde: onayın ne olduğu gözden kaçmasın.
              // Kendiliğinden işaretli değil.
              Container(
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _onay ? t.secondary : AppCard.borderColor(t),
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  clipBehavior: Clip.antiAlias,
                  child: CheckboxListTile(
                    key: const Key('sync_consent_checkbox'),
                    value: _onay,
                    onChanged: (v) => setState(() => _onay = v ?? false),
                    contentPadding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      context.tr('sync_consent_checkbox'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // Degrade yalnızca kutucuk işaretliyken: kapalı düğme temanın
              // soluk görünümünde, "basılabilir" sanılmasın.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _onay ? AppGradients.primary(context) : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: _onay ? AppShadows.floating(context) : null,
                ),
                child: FilledButton(
                  key: const Key('sync_consent_accept'),
                  onPressed: _onay
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: AppTheme.dialogAction().copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(0, 54)),
                    shape: const WidgetStatePropertyAll(StadiumBorder()),
                    backgroundColor: _onay
                        ? const WidgetStatePropertyAll(Colors.transparent)
                        : null,
                    shadowColor: const WidgetStatePropertyAll(
                      Colors.transparent,
                    ),
                  ),
                  child: Text(context.tr('sync_consent_accept')),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: t.textMuted,
                  minimumSize: const Size(0, 48),
                ),
                child: Text(context.tr('cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
