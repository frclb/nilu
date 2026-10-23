import '../../../design_system/app_tappable.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';
import 'log_section_header.dart';

class SymptomsSection extends StatefulWidget {
  final List<String> initialSymptoms;
  final ValueChanged<List<String>> onChanged;

  /// Seçilebilecek belirti kodları (evreye göre, bkz.
  /// `LogVocabulary.symptomsFor`).
  final List<String> codes;

  const SymptomsSection({
    super.key,
    this.initialSymptoms = const [],
    this.codes = LogVocabulary.symptoms,
    required this.onChanged,
  });

  @override
  State<SymptomsSection> createState() => _SymptomsSectionState();
}

class _SymptomsSectionState extends State<SymptomsSection> {
  /// Seçili kodlar. Listede görünmeyenler de burada kalıyor: gebelikte
  /// girilen "bulantı" döngüye dönünce listede yok ama kayıttan silinmemeli.
  ///
  /// Seçim **bir kez**, burada kuruluyor. Önceden her çizimde "seçim boşsa
  /// başlangıç değerini yükle" deniyordu: ön dolu bir belirtinin seçimi
  /// kaldırılınca bir sonraki çizimde geri geliyordu.
  late final Set<String> _selected = {...widget.initialSymptoms};

  /// Döngü belirtilerinin simgeleri — yalnızca süs; anlamı etiket taşıyor.
  ///
  /// Liste simgesi olmayan bir kod içeriyorsa (gebelik belirtileri) hiçbir
  /// çipte simge çizilmiyor: yarısı simgeli bir liste dağınık duruyor.
  static const Map<String, IconData> _icons = {
    'cramp': Icons.bolt,
    'headache': Icons.psychology_outlined,
    'bloating': Icons.lens_blur,
    'fatigue': Icons.bedtime_outlined,
    'tender': Icons.favorite_border,
    'acne': Icons.bubble_chart_outlined,
    'appetite': Icons.restaurant,
    'backache': Icons.airline_seat_recline_extra,
  };

  @override
  Widget build(BuildContext context) {
    final codes = widget.codes;
    final withIcons = codes.every(_icons.containsKey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogSectionHeader(
            icon: Icons.healing,
            title: context.tr('log_symptoms'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in codes)
                _SymptomChip(
                  // Saklanan değerler kanonik kodlardır; etiketler
                  // lokalizasyondan gelir.
                  label: context.tr(LogVocabulary.symptomKey(code)),
                  icon: withIcons ? _icons[code] : null,
                  selected: _selected.contains(code),
                  onTap: () {
                    setState(() {
                      if (_selected.contains(code)) {
                        _selected.remove(code);
                      } else {
                        _selected.add(code);
                      }
                    });
                    widget.onChanged(_selected.toList());
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Belirti çipi: seçiliyken erik dolgu ve onay işareti.
class _SymptomChip extends StatelessWidget {
  const _SymptomChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final fg = selected ? theme.colorScheme.onPrimary : t.text;

    return AppTappable(
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        // En az 44 pt: dokunma hedefi iOS'un önerdiği ölçüde kalsın.
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : t.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: selected ? null : AppShadows.soft(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? theme.colorScheme.onPrimary.withAlpha(210)
                    : t.textFaint,
              ),
              const SizedBox(width: 6),
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
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check, size: 15, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}
