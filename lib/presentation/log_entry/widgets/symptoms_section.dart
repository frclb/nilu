import 'package:flutter/material.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';

class SymptomsSection extends StatefulWidget {
  final List<String> initialSymptoms;
  final ValueChanged<List<String>> onChanged;

  const SymptomsSection({
    super.key,
    this.initialSymptoms = const [],
    required this.onChanged,
  });

  @override
  State<SymptomsSection> createState() => _SymptomsSectionState();
}

class _SymptomsSectionState extends State<SymptomsSection> {
  late Set<int> _selectedIndices;

  static const List<String> _symptomCodes = LogVocabulary.symptoms;

  @override
  void initState() {
    super.initState();
    _selectedIndices = {};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Saklanan değerler kanonik kodlardır; etiketler lokalizasyondan gelir.
    final symptoms = _symptomCodes
        .map((code) => context.tr(LogVocabulary.symptomKey(code)))
        .toList();

    // Restore initial from widget
    if (_selectedIndices.isEmpty && widget.initialSymptoms.isNotEmpty) {
      for (int i = 0; i < _symptomCodes.length; i++) {
        if (widget.initialSymptoms.contains(_symptomCodes[i])) {
          _selectedIndices.add(i);
        }
      }
    }

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
              final isSelected = _selectedIndices.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIndices.remove(index);
                    } else {
                      _selectedIndices.add(index);
                    }
                  });
                  widget.onChanged(
                    _selectedIndices.map((i) => _symptomCodes[i]).toList(),
                  );
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
