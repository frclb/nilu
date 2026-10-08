import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/home_widget_entry.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../calendar/view_models/calendar_view_model.dart';
import 'home_widget_plan.dart';

/// Ana ekran widget'ının tanıtımı.
///
/// Önceden örnek verilerle çizilmiş üç widget gösteriyordu: "14. gün",
/// "8 gün kaldı", bir "günün önerisi" ve "Ayşe" adlı bir partnerin evresi.
/// Uygulamada ne öneri widget'ı ne partner widget'ı vardı; gösterilen
/// sayılar da kullanıcının değildi. Artık gerçek widget'ın bugün
/// göstereceği içerik, aynı plandan (bkz. [HomeWidgetPlan]) çiziliyor.
class WidgetsPreviewScreen extends StatelessWidget {
  const WidgetsPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final takvim = context.watch<CalendarViewModel>();
    final gebelik = context.watch<PregnancyViewModel>();
    final bugun = HomeWidgetPlan.entryFor(
      context,
      DateTime.now(),
      cycle: takvim.cycleInfo,
      pregnancies: gebelik.pregnancies,
      afterPregnancy: takvim.cycleBreaks.isNotEmpty,
    );

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('widgets_title'),
          style: TextStyle(
            color: t.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              _Baslik(context.tr('widgets_small_title')),
              Center(
                child: _Cerceve(
                  key: const Key('widget_preview_small'),
                  width: 160,
                  height: 160,
                  child: _KucukIcerik(entry: bugun),
                ),
              ),
              const SizedBox(height: 32),
              _Baslik(context.tr('widgets_medium_title')),
              _Cerceve(
                key: const Key('widget_preview_medium'),
                height: 160,
                child: _OrtaIcerik(entry: bugun),
              ),
              const SizedBox(height: 32),
              _Not(
                icon: Icons.add_to_home_screen_outlined,
                text: context.tr('widgets_how_to_add'),
              ),
              const SizedBox(height: 12),
              _Not(
                icon: Icons.lock_outline,
                text: context.tr('widgets_privacy_note'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `CycleWidget.swift`teki renklerin uygulama karşılığı.
Color _renk(BuildContext context, String key) {
  final t = context.tokens;
  return switch (key) {
    'menstruation' => t.flow,
    'follicular' => t.phaseFollicular,
    'ovulation' => t.ovulation,
    'luteal' => t.phaseLuteal,
    'suppressed' => t.phaseSuppressed,
    'pregnancy' || 'postpartum' => t.accent,
    _ => Theme.of(context).colorScheme.primary,
  };
}

class _Baslik extends StatelessWidget {
  const _Baslik(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        context.upper(text),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Cerceve extends StatelessWidget {
  const _Cerceve({
    super.key,
    this.width,
    required this.height,
    required this.child,
  });

  final double? width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _Etiket extends StatelessWidget {
  const _Etiket(this.entry);

  final HomeWidgetEntry entry;

  @override
  Widget build(BuildContext context) => Text(
    entry.label,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
      color: _renk(context, entry.colorKey),
    ),
  );
}

class _Bos extends StatelessWidget {
  const _Bos(this.entry);

  final HomeWidgetEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_calendar_outlined, color: t.textMuted, size: 28),
          const SizedBox(height: 6),
          Text(
            entry.detail,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}

class _KucukIcerik extends StatelessWidget {
  const _KucukIcerik({required this.entry});

  final HomeWidgetEntry entry;

  @override
  Widget build(BuildContext context) {
    if (!entry.hasData) return _Bos(entry);
    final t = context.tokens;
    final ikincil = TextStyle(fontSize: 11, color: t.textMuted);
    return Semantics(
      label: entry.spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Etiket(entry),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              entry.value,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: t.text,
              ),
            ),
          ),
          const Spacer(),
          if (entry.caption.isNotEmpty)
            Text(
              entry.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ikincil,
            ),
          if (entry.detail.isNotEmpty)
            Text(
              entry.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ikincil,
            ),
        ],
      ),
    );
  }
}

class _OrtaIcerik extends StatelessWidget {
  const _OrtaIcerik({required this.entry});

  final HomeWidgetEntry entry;

  @override
  Widget build(BuildContext context) {
    if (!entry.hasData) return _Bos(entry);
    final t = context.tokens;
    final renk = _renk(context, entry.colorKey);
    return Semantics(
      label: entry.spoken,
      excludeSemantics: true,
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: entry.progress ?? 0,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: renk,
                    backgroundColor: renk.withAlpha(51),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: t.text,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Etiket(entry),
                if (entry.caption.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                ],
                if (entry.detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: t.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Not extends StatelessWidget {
  const _Not({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: t.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, height: 1.4, color: t.textMuted),
          ),
        ),
      ],
    );
  }
}
