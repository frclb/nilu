import 'package:flutter/material.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';

class FlowIntensitySection extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const FlowIntensitySection({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<FlowIntensitySection> createState() => _FlowIntensitySectionState();
}

class _FlowIntensitySectionState extends State<FlowIntensitySection> {
  int _selectedIndex = -1;

  // Saklanan değerler kanonik kodlardır (bkz. LogVocabulary); ekranda görünen
  // etiketler lokalizasyondan çözülür.
  static const List<String> _values = LogVocabulary.flowIntensities;

  static const List<IconData> _icons = [
    Icons.block,
    Icons.opacity,
    Icons.water_drop,
    Icons.waves,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _selectedIndex = _values.indexOf(widget.initialValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final options = List.generate(
      _values.length,
      (i) => {
        'icon': _icons[i],
        'label': context.tr(LogVocabulary.flowKey(_values[i])),
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('log_flow_intensity'),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(options.length, (index) {
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index < options.length - 1 ? 12 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      widget.onChanged(index == 0 ? null : _values[index]);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? AppScrim.frost(25)
                                  : theme.colorScheme.primary.withAlpha(12))
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (Theme.of(context).colorScheme.primary)
                              : (context.tokens.border),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            options[index]['icon'] as IconData,
                            color: isSelected
                                ? (Theme.of(context).colorScheme.primary)
                                : theme.textTheme.labelLarge?.color?.withAlpha(
                                    127,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            options[index]['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? (Theme.of(context).colorScheme.primary)
                                  : theme.textTheme.labelLarge?.color,
                            ),
                          ),
                        ],
                      ),
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
