import '../../../design_system/app_tappable.dart';
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

  /// Kutunun en az genişliği.
  ///
  /// Sabit genişlik denendi ve dile takıldı: Almanca "Schmierblutung" 100
  /// pt'ye sığmayıp iki satıra bölünüyordu. Artık kutu **etiketine göre**
  /// boyutlanıyor, bu yalnızca kısa etiketlerin ("Yok") iğne gibi
  /// kalmaması için bir alt sınır.
  static const double _chipMinWidth = 88;

  /// Kod → simge. Liste yerine eşleme: iki paralel liste tutulduğunda
  /// sözlüğe bir kademe eklemek simgeleri sessizce kaydırıyordu.
  static const Map<String, IconData> _icons = {
    'none': Icons.block,
    LogVocabulary.spotting: Icons.circle,
    'light': Icons.opacity,
    'medium': Icons.water_drop,
    'heavy': Icons.waves,
  };

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
        'icon': _icons[_values[i]] ?? Icons.help_outline,
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
          // `Row` + `Expanded` değil `Wrap`.
          //
          // Eşit bölünen beş kutuda dar bir telefonda etiket başına ~35 pt
          // kalıyor ve "Lekelenme" üç satıra bölünüyordu. `Wrap` kutuyu
          // etiketine göre boyutlandırıp sığmayanı alt satıra indiriyor:
          // hiçbir seçenek kırpılmıyor ve hepsi görünür kalıyor — yatay
          // kaydırmada olduğu gibi gizlenmiyor.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(options.length, (index) {
              final isSelected = _selectedIndex == index;
              return ConstrainedBox(
                constraints: const BoxConstraints(minWidth: _chipMinWidth),
                child: AppTappable(
                  selected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    // 'none' = kayıt yok. İndeks yerine kodun kendisine
                    // bakılıyor: sözlüğe bir kademe eklendiğinde indeks
                    // tabanlı kontrol sessizce yanlış seçeneği boşaltır.
                    final code = _values[index];
                    widget.onChanged(code == 'none' ? null : code);
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
              );
            }),
          ),
        ],
      ),
    );
  }
}
