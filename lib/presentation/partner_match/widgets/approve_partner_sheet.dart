import 'package:flutter/material.dart';

import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../home/widgets/intimacy_options.dart';
import 'partner_ui.dart';

/// Onay sayfasında verilen karar.
class ApproveDecision {
  /// Onayla ve seçilenleri hemen paylaş.
  const ApproveDecision.share({
    required this.sexualDesire,
    required this.affectionNeeds,
  }) : share = true;

  /// Erişimi ver ama şimdilik hiçbir şey paylaşma.
  const ApproveDecision.approveOnly()
    : share = false,
      sexualDesire = null,
      affectionNeeds = const [];

  final bool share;
  final String? sexualDesire;
  final List<String> affectionNeeds;
}

/// Partner isteğini onaylarken: partnerin **tam olarak neyi göreceği**.
///
/// TestFlight bulgusu: sahip onaylarken neyi paylaştığını görmüyordu, onaydan
/// sonra da hiçbir şey gitmiyordu; partnerin ekranı sahip ayrıca
/// "Partnerinle Paylaş"a basana kadar boş kaldı. Sayfa şimdi seçimleri
/// gösteriyor, orada değiştirilebiliyor; "Onayla ve paylaş" onları hemen
/// gönderiyor.
///
/// Paylaşım cinsel hayata ilişkin, yani özel nitelikli veri: rıza daha önce
/// verilmediyse rıza metninin maddeleri de burada ([consentGiven]). Erişimi
/// paylaşmadan vermek de mümkün.
///
/// Vazgeçilirse `null`.
Future<ApproveDecision?> showApprovePartnerSheet(
  BuildContext context, {
  required String code,
  required String? sexualDesire,
  required List<String> affectionNeeds,
  required bool consentGiven,
}) => showModalBottomSheet<ApproveDecision>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => _ApprovePartnerSheet(
    code: code,
    sexualDesire: sexualDesire,
    affectionNeeds: affectionNeeds,
    consentGiven: consentGiven,
  ),
);

class _ApprovePartnerSheet extends StatefulWidget {
  const _ApprovePartnerSheet({
    required this.code,
    required this.sexualDesire,
    required this.affectionNeeds,
    required this.consentGiven,
  });

  final String code;
  final String? sexualDesire;
  final List<String> affectionNeeds;
  final bool consentGiven;

  @override
  State<_ApprovePartnerSheet> createState() => _ApprovePartnerSheetState();
}

class _ApprovePartnerSheetState extends State<_ApprovePartnerSheet> {
  late String? _desire = widget.sexualDesire;
  late final List<String> _needs = List.of(widget.affectionNeeds);

  bool get _nothingPicked => _desire == null && _needs.isEmpty;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    Widget baslik(String key) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        context.tr(key),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: t.text,
        ),
      ),
    );

    Widget secenek(IntimacyOption o, {required bool selected}) => FilterChip(
      key: Key('partner_approve_${o.value}'),
      avatar: selected ? null : Icon(o.icon, size: 16, color: primary),
      label: Text(context.tr(o.labelKey)),
      selected: selected,
      showCheckmark: true,
      onSelected: (_) => setState(() {
        if (desireOptions.contains(o)) {
          _desire = selected ? null : o.value;
        } else if (selected) {
          _needs.remove(o.value);
        } else {
          _needs.add(o.value);
        }
      }),
    );

    Widget madde(IconData icon, String key) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: t.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(key),
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: t.textMuted,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      key: const Key('partner_approve_sheet'),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('partner_approve_title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Doğru kişi mi: aynı kod partnerin ekranında da yazıyor.
                    Text.rich(
                      PartnerUi.emphasize(
                        context.tr(
                          'partner_request_code',
                          params: {'code': widget.code},
                        ),
                        widget.code,
                        theme.textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: primary,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('partner_approve_code_hint'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(height: 22),
                    AppSectionLabel(
                      context.tr('partner_approve_sees'),
                      color: t.secondary,
                    ),
                    const SizedBox(height: 12),
                    baslik('intimacy_sexual_desire_title'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in desireOptions)
                          secenek(o, selected: _desire == o.value),
                      ],
                    ),
                    const SizedBox(height: 16),
                    baslik('intimacy_affection_title'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in affectionNeedOptions)
                          secenek(o, selected: _needs.contains(o.value)),
                      ],
                    ),
                    if (_nothingPicked) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.tr('partner_approve_nothing'),
                        key: const Key('partner_approve_nothing'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: t.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: t.secondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.tr('partner_approve_not_shared'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.45,
                                    color: t.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Rıza bilgilendirilmiş olmalı: nerede saklanıyor,
                          // neden özel, nasıl geri alınıyor.
                          if (!widget.consentGiven) ...[
                            madde(Icons.cloud_outlined, 'consent_where'),
                            madde(Icons.shield_outlined, 'consent_special'),
                            madde(Icons.undo_rounded, 'consent_withdraw'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppGradientButton(
                    key: const Key('partner_approve_share'),
                    label: context.tr('partner_approve_share'),
                    icon: Icons.favorite_rounded,
                    radius: AppRadius.pill,
                    onPressed: () => Navigator.pop(
                      context,
                      ApproveDecision.share(
                        sexualDesire: _desire,
                        affectionNeeds: List.of(_needs),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    key: const Key('partner_approve_only'),
                    onPressed: () => Navigator.pop(
                      context,
                      const ApproveDecision.approveOnly(),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: t.textMuted,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(context.tr('partner_approve_only')),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: t.textMuted,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: Text(context.tr('cancel')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
