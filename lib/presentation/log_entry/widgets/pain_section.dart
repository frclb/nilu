import 'package:flutter/material.dart';

import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                context.tr('day_detail_pain'),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in LogVocabulary.painLevels)
                _Pill(
                  label: context.tr(LogVocabulary.painLevelKey(code)),
                  selected: _level == code,
                  onTap: () => _selectLevel(code),
                ),
            ],
          ),

          if (_level != null) ...[
            const SizedBox(height: 8),
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
                style: theme.textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 8),
            _Label(context.tr('log_pain_location')),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final code in LogVocabulary.painLocations)
                  _Pill(
                    label: context.tr(LogVocabulary.painLocationKey(code)),
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
                color: context.tokens.textMuted,
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
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}

/// Kayıt ekranının çip biçimi; semptom ve ruh hâli bölümleriyle aynı.
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : context.tokens.border,
          ),
          boxShadow: selected
              ? null
              : [
                  BoxShadow(
                    color: AppScrim.veil(26),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.labelLarge?.color,
          ),
        ),
      ),
    );
  }
}
