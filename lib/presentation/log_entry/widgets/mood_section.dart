import 'package:flutter/material.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';

class MoodSection extends StatefulWidget {
  final List<String> initialMoods;
  final ValueChanged<List<String>> onChanged;

  const MoodSection({
    super.key,
    this.initialMoods = const [],
    required this.onChanged,
  });

  @override
  State<MoodSection> createState() => _MoodSectionState();
}

class _MoodSectionState extends State<MoodSection> {
  int _selectedIndex = -1;

  // Saklanan değerler kanonik kodlardır; etiketler lokalizasyondan gelir.
  static const List<String> _moodCodes = ['happy', 'calm', 'sad', 'anxious'];

  static const List<IconData> _moodIcons = [
    Icons.sentiment_satisfied,
    Icons.self_improvement,
    Icons.sentiment_dissatisfied,
    Icons.thunderstorm,
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final moods = List.generate(
      _moodCodes.length,
      (i) => {
        'icon': _moodIcons[i],
        'label': context.tr(LogVocabulary.moodKey(_moodCodes[i])),
      },
    );

    // Restore initial
    if (_selectedIndex == -1 && widget.initialMoods.isNotEmpty) {
      for (int i = 0; i < _moodCodes.length; i++) {
        if (widget.initialMoods.contains(_moodCodes[i])) {
          _selectedIndex = i;
          break;
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
              Icon(Icons.mood, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                context.tr('log_mood'),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(moods.length, (index) {
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onChanged([_moodCodes[index]]);
                },
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (context.tokens.border),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppScrim.veil(26),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        moods[index]['icon'] as IconData,
                        size: 32,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : theme.textTheme.labelLarge?.color?.withAlpha(127),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      moods[index]['label'] as String,
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
              );
            }),
          ),
        ],
      ),
    );
  }
}
