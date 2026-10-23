import '../../../design_system/app_tappable.dart';
import 'package:flutter/material.dart';

import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';
import 'log_section_header.dart';

/// Kayıt ekranının ağrı bölümü.
///
/// Ağrı daha önce yalnızca takvimin gün detayında soruluyordu — yani
/// uygulamanın birincil kayıt yolu (alt köşedeki "+") klinik olarak en
/// önemli belirtiyi hiç sormuyordu. Üç dokunuş derinde duran bir alan
/// pratikte doldurulmuyor.
///
/// Yer ve bağlam yalnızca bir şiddet seçilince açılıyor: ağrısı olmayan
/// kullanıcıya dört soru daha sormak, ekranı ağırlaştırmaktan başka bir
/// işe yaramaz.
class PainSection extends StatefulWidget {
  const PainSection({
    super.key,
    this.initialLevel,
    this.initialLimited = false,
    this.initialLocations = const [],
    this.initialContexts = const [],
    required this.onChanged,
  });

  final String? initialLevel;
  final bool initialLimited;
  final List<String> initialLocations;
  final List<String> initialContexts;

  final ValueChanged<PainEntry> onChanged;

  @override
  State<PainSection> createState() => _PainSectionState();
}

/// Bölümün ürettiği değer.
class PainEntry {
  const PainEntry({
    this.level,
    this.limitedActivity = false,
    this.locations = const [],
    this.contexts = const [],
  });

  final String? level;
  final bool limitedActivity;
  final List<String> locations;
  final List<String> contexts;
}

class _PainSectionState extends State<PainSection> {
  String? _level;
  bool _limited = false;
  late List<String> _locations;
  late List<String> _contexts;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _limited = widget.initialLimited;
    _locations = List.of(widget.initialLocations);
    _contexts = List.of(widget.initialContexts);
  }

  void _emit() => widget.onChanged(
    PainEntry(
      level: _level,
      limitedActivity: _limited,
      locations: _locations,
      contexts: _contexts,
    ),
  );

  void _selectLevel(String code) {
    setState(() {
      // Aynı kademeye tekrar dokunmak seçimi kaldırır.
      if (_level == code) {
        _level = null;
        // Ağrı yoksa yer ve bağlam da anlamını yitiriyor.
        _limited = false;
        _locations = [];
        _contexts = [];
      } else {
        _level = code;
      }
    });
    _emit();
  }

  void _toggle(List<String> list, String code) {
    setState(() {
      list.contains(code) ? list.remove(code) : list.add(code);
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LogSectionHeader(
            icon: Icons.monitor_heart_outlined,
            title: context.tr('day_detail_pain'),
          ),
          // Şiddet: tül bir rayın içinde üç bölüm; seçili olan şeftali.
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                for (final code in LogVocabulary.painLevels)
                  Expanded(
                    child: _Segment(
                      label: context.tr(LogVocabulary.painLevelKey(code)),
                      selected: _level == code,
                      onTap: () => _selectLevel(code),
                    ),
                  ),
              ],
            ),
          ),

          if (_level != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.soft(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    value: _limited,
                    onChanged: (v) {
                      setState(() => _limited = v ?? false);
                      _emit();
                    },
                    title: Text(
                      context.tr('day_detail_pain_limited'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),
                  _Label(context.tr('log_pain_location')),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final code in LogVocabulary.painLocations)
                        _Pill(
                          label: context.tr(
                            LogVocabulary.painLocationKey(code),
                          ),
                          selected: _locations.contains(code),
                          onTap: () => _toggle(_locations, code),
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  _Label(context.tr('log_pain_when')),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('log_pain_when_hint'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final code in LogVocabulary.painContexts)
                        _Pill(
                          label: context.tr(LogVocabulary.painContextKey(code)),
                          selected: _contexts.contains(code),
                          onTap: () => _toggle(_contexts, code),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: context.tokens.textMuted,
    ),
  );
}

/// Şiddet rayının bir bölümü.
class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppTappable(
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? t.accentTint : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? AppShadows.soft(context) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: t.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? t.text : t.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ağrı yeri ve bağlamı çipi: seçiliyken gül tülü ve onay işareti.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final fg = selected ? t.secondary : t.textMuted;

    return AppTappable(
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        // En az 44 pt: dokunma hedefi iOS'un önerdiği ölçüde kalsın.
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? t.secondaryTint : t.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 15, color: fg),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
