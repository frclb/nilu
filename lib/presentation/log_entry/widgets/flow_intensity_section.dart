import 'dart:math' as math;

import '../../../design_system/app_tappable.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';
import 'log_section_header.dart';

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

  /// Kutunun en az genişliği (etiketler sığmadığında).
  ///
  /// Sabit genişlik denendi ve dile takıldı: Almanca "Schmierblutung" 100
  /// pt'ye sığmayıp iki satıra bölünüyordu. Artık kutu **etiketine göre**
  /// boyutlanıyor, bu yalnızca kısa etiketlerin ("Yok") iğne gibi
  /// kalmaması için bir alt sınır.
  static const double _chipMinWidth = 88;

  static const double _gap = 6;

  /// Kutunun iç yatay boşluğu (iki yan).
  static const double _tilePadding = 3;

  /// Eşit kutuya sığmayan etiketin ne kadar küçültülebileceği. Biraz
  /// taşan etiket ("Lekelenme") hafifçe küçülüyor ve beş kutu tek satırda
  /// kalıyor; daha uzunu (ör. Almanca, büyük yazı) küçültülmüyor, kutular
  /// genişleyip alt satıra iniyor.
  static const double _maxShrink = 1.2;

  /// Kod → simge. Liste yerine eşleme: iki paralel liste tutulduğunda
  /// sözlüğe bir kademe eklemek simgeleri sessizce kaydırıyordu.
  static const Map<String, IconData> _icons = {
    'none': Icons.block,
    LogVocabulary.spotting: Icons.grain,
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

  TextStyle? _labelStyle(BuildContext context, {required bool selected}) =>
      Theme.of(context).textTheme.labelMedium?.copyWith(
        fontSize: 11.5,
        letterSpacing: 0,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : context.tokens.textMuted,
      );

  @override
  Widget build(BuildContext context) {
    final labels = [
      for (final code in _values) context.tr(LogVocabulary.flowKey(code)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogSectionHeader(
            icon: Icons.water_drop,
            title: context.tr('log_flow_intensity'),
          ),
          // Beş eşit kutu — sığıyorsa.
          //
          // Eşit bölünen beş kutuda dar bir telefonda etiket başına ~35 pt
          // kalıyor ve "Lekelenme" üç satıra bölünüyordu. En uzun etiket
          // ölçülüyor: eşit kutuya sığmıyorsa kutular etiketine göre
          // genişliyor ve `Wrap` sığmayanı alt satıra indiriyor. Hiçbir
          // seçenek kırpılmıyor ve hepsi görünür kalıyor — yatay
          // kaydırmada olduğu gibi gizlenmiyor.
          LayoutBuilder(
            builder: (context, constraints) {
              final scaler = MediaQuery.textScalerOf(context);
              final direction = Directionality.of(context);
              var widest = 0.0;
              for (final label in labels) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: label,
                    style: _labelStyle(context, selected: true),
                  ),
                  textDirection: direction,
                  textScaler: scaler,
                  maxLines: 1,
                )..layout();
                widest = math.max(widest, painter.width);
                painter.dispose();
              }
              final needed = widest + _tilePadding * 2 + 2;
              final width = constraints.maxWidth;
              // Bir satıra kaç kutu sığıyor; kutular satırı eşit dolduruyor.
              // Beşi sığıyorsa (gerekirse etiket biraz küçülerek) tek satır.
              final fiveFit =
                  needed <= _equalWidth(width, _values.length) * _maxShrink;
              final perRow = fiveFit
                  ? _values.length
                  : ((width + _gap) / (math.max(_chipMinWidth, needed) + _gap))
                        .floor()
                        .clamp(1, _values.length);
              // Küçük pay: kesirli toplam genişliği aşıp son kutuyu alt
              // satıra itmesin.
              final tileWidth = _equalWidth(width, perRow) - 0.05;

              return Wrap(
                spacing: _gap,
                runSpacing: _gap,
                children: [
                  for (var i = 0; i < _values.length; i++)
                    SizedBox(
                      width: tileWidth,
                      child: _tile(context, i, labels[i]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// [perRow] kutunun satırı eşit doldurduğu genişlik.
  static double _equalWidth(double width, int perRow) =>
      (width - _gap * (perRow - 1)) / perRow;

  Widget _tile(BuildContext context, int index, String label) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final scheme = theme.colorScheme;
    final isSelected = _selectedIndex == index;
    final code = _values[index];

    return AppTappable(
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // 'none' = kayıt yok. İndeks yerine kodun kendisine
        // bakılıyor: sözlüğe bir kademe eklendiğinde indeks
        // tabanlı kontrol sessizce yanlış seçeneği boşaltır.
        widget.onChanged(code == 'none' ? null : code);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.symmetric(
              horizontal: _tilePadding,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? null : t.surface,
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.secondary, scheme.primary],
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: isSelected
                  ? AppShadows.floating(context)
                  : AppShadows.soft(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? scheme.onPrimary.withAlpha(45)
                        : t.surfaceAlt,
                  ),
                  child: Icon(
                    _icons[code] ?? Icons.help_outline,
                    size: 18,
                    color: isSelected
                        ? scheme.onPrimary
                        : (code == 'none' ? t.textFaint : t.secondary),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: _labelStyle(context, selected: isSelected),
                  ),
                ),
              ],
            ),
          ),
          // Seçim işareti: rengin yanında biçim de söylesin.
          if (isSelected)
            Positioned(
              top: -5,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: t.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft(context),
                ),
                child: Icon(Icons.check, size: 12, color: t.secondary),
              ),
            ),
        ],
      ),
    );
  }
}
