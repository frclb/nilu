import '../../../design_system/app_tappable.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';
import 'log_section_header.dart';

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

  /// Kod → emoji. Gün sayfasındaki ruh hâli kutularıyla aynı dil.
  static const Map<String, String> _emojis = {
    'happy': '😊',
    'calm': '😌',
    'sad': '😔',
    'anxious': '😟',
  };

  @override
  void initState() {
    super.initState();
    // Bir kez: önceden her çizimde yükleniyordu (bkz. `SymptomsSection`).
    _selectedIndex = _moodCodes.indexWhere(widget.initialMoods.contains);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogSectionHeader(icon: Icons.mood, title: context.tr('log_mood')),
          // Kutular eşit boyda: küçülen etiket kutuyu kısaltmasın.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _moodCodes.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _tile(context, i)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, int index) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final code = _moodCodes[index];
    final isSelected = _selectedIndex == index;

    return AppTappable(
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        widget.onChanged([code]);
      },
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? t.accentTint : t.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? t.accent.withAlpha(90) : Colors.transparent,
              ),
              boxShadow: AppShadows.soft(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji süs; VoiceOver yalnızca etiketi okusun.
                ExcludeSemantics(
                  child: Text(
                    _emojis[code] ?? '',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 6),
                // Uzun etiket ("Angespannt") kelimenin ortasından
                // bölünmesin; hafifçe küçülsün.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr(LogVocabulary.moodKey(code)),
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? t.text : t.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: -5,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
