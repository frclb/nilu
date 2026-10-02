import 'package:flutter/material.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final codes = widget.codes;

    // Saklanan değerler kanonik kodlardır; etiketler lokalizasyondan gelir.
    final symptoms = codes
        .map((code) => context.tr(LogVocabulary.symptomKey(code)))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                context.tr('log_symptoms'),
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
            children: List.generate(symptoms.length, (index) {
              final code = codes[index];
              final isSelected = _selected.contains(code);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selected.remove(code);
                    } else {
                      _selected.add(code);
                    }
                  });
                  widget.onChanged(_selected.toList());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (context.tokens.border),
                      width: 1,
                    ),
                    boxShadow: isSelected
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
                    symptoms[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : theme.textTheme.labelLarge?.color,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
