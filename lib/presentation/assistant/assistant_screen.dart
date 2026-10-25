import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/log_vocabulary.dart';
import '../../domain/services/assistant/assistant_answer.dart';
import '../../domain/services/assistant/assistant_parser.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../../design_system/app_layout.dart';

/// Kullanıcının kendi verisine soru sorduğu ekran.
///
/// Bir dil modeline bağlı **değil**. Regl verisi GDPR'da özel nitelikli veri
/// ve bu uygulamanın en güçlü tarafı verinin cihazdan çıkmaması; onboarding'de
/// ve gizlilik bildiriminde bunun sözü veriliyor. Ayrıca "bu normal mi?"
/// türü sorulara uyduran bir model, sağlık uygulamasında en kötü hata türü.
///
/// Cevaplar `PredictionService` ve `InsightsService`'ten geliyor — yani
/// ekranda zaten görünen sayılarla aynı. Uygulama bilmediği bir şey
/// sorulduğunda uydurmuyor, ne sorulabileceğini gösteriyor.
///
/// Görünüm de buna uyuyor: robot simgesi, "yazıyor…" noktaları ya da
/// yapay zekâ degradesi yok. Soru bir hap, cevap bir hesap kartı.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_Turn> _turns = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Soruyu kullanıcının dilindeki anahtar kelimelerle bir niyete eşler.
  AssistantQuery _parse(String text) {
    // Belirti adları kullanıcının dilinde eşleşmeli.
    final symptomLabels = {
      for (final code in LogVocabulary.allSymptoms)
        context.tr(LogVocabulary.symptomKey(code)): code,
    };

    final patterns = {
      for (final intent in AssistantIntent.values)
        if (intent != AssistantIntent.unknown)
          intent: context.tr('assistant_kw_${intent.name}'),
    };

    return AssistantParser.parse(
      text,
      patterns: patterns,
      symptomLabels: symptomLabels,
    );
  }

  void _ask(String question) {
    final text = question.trim();
    if (text.isEmpty) return;

    final viewModel = context.read<CalendarViewModel>();
    final query = _parse(text);

    final answer = AssistantAnswerBuilder.build(
      query,
      cycleInfo: viewModel.cycleInfo,
      periodLogs: viewModel.periodLogs,
      dailyLogs: viewModel.dailyLogs,
      now: DateTime.now(),
      breaks: viewModel.cycleBreaks,
    );

    setState(() {
      _turns.insert(
        0,
        _Turn(question: text, answer: answer, intent: query.intent),
      );
      _controller.clear();
    });
  }

  /// Cevabı kullanıcının dilinde metne çevirir.
  ///
  /// Parametrelerin bir kısmı anahtar taşıyor (evre adı, belirti kodu) ya da
  /// ISO tarih; hepsi burada çözülüyor ki cevap üreticisi dilden bağımsız
  /// kalsın.
  String _render(AssistantAnswer answer) {
    final params = <String, String>{};
    answer.params.forEach((key, value) {
      params[key] = switch (key) {
        'phase' => context.tr(value),
        'symptom' => context.tr(LogVocabulary.symptomKey(value)),
        'date' || 'start' || 'end' || 'ovulation' => _formatDate(value),
        _ => value,
      };
    });
    return context.tr(answer.key, params: params);
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return context.dayMonth(date);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        title: Text(
          context.tr('assistant_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 21,
            color: t.text,
          ),
        ),
      ),
      // Giriş çubuğu gövdenin değil `Scaffold`'un altında: içerik
      // sütununun içinde kalınca zemini geniş ekranda 600 pt'de
      // kesilip sayfanın üstünde sert kenarlı bir dikdörtgen
      // bırakıyordu.
      bottomNavigationBar: _InputBar(controller: _controller, onAsk: _ask),
      body: AppContentWidth(
        child: Column(
          children: [
            Expanded(
              child: _turns.isEmpty
                  ? _Intro(onPick: _ask, intentOf: (q) => _parse(q).intent)
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg + 4,
                        AppSpacing.lg,
                        AppSpacing.lg + 4,
                        AppSpacing.lg,
                      ),
                      itemCount: _turns.length,
                      itemBuilder: (context, index) {
                        final turn = _turns[index];
                        return _TurnView(
                          question: turn.question,
                          answer: _render(turn.answer),
                          needsData: turn.answer.needsData,
                          intent: turn.intent,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Turn {
  final String question;
  final AssistantAnswer answer;
  final AssistantIntent intent;

  const _Turn({
    required this.question,
    required this.answer,
    required this.intent,
  });
}

/// Sorunun konusunu anlatan simge. Niyetten seçiliyor, örnek metnin
/// sırasından değil: diller örnekleri farklı sırada yazabilir.
IconData _iconFor(AssistantIntent intent) => switch (intent) {
  AssistantIntent.nextPeriod => Icons.event_outlined,
  AssistantIntent.currentPhase => Icons.today_outlined,
  AssistantIntent.fertileWindow => Icons.spa_outlined,
  AssistantIntent.cycleLength => Icons.timelapse,
  AssistantIntent.periodLength => Icons.water_drop_outlined,
  AssistantIntent.regularity => Icons.show_chart,
  AssistantIntent.symptomFrequency => Icons.bubble_chart_outlined,
  AssistantIntent.lastSymptom => Icons.history,
  AssistantIntent.unknown => Icons.help_outline,
};

/// Alttaki soru alanı: hap biçimli giriş, yanında yuvarlak gönder düğmesi.
class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onAsk});

  final TextEditingController controller;
  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: BorderSide(color: AppCard.borderColor(t)),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: t.background,
        boxShadow: AppShadows.soft(context),
      ),
      child: AppContentWidth(
        // Zemin tam genişlikte, giriş alanı okunur sütunda kalıyor.
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: onAsk,
                decoration: InputDecoration(
                  hintText: context.tr('assistant_hint'),
                  filled: true,
                  fillColor: t.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  border: pill,
                  enabledBorder: pill,
                  focusedBorder: pill.copyWith(
                    borderSide: BorderSide(color: t.secondary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: context.tr('assistant_send'),
              onPressed: () => onAsk(controller.text),
              style: IconButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size(50, 50),
                shadowColor: scheme.primary.withAlpha(80),
                elevation: 3,
              ),
              icon: const Icon(Icons.arrow_upward),
            ),
          ],
        ),
      ),
    );
  }
}

/// İlk açılışta ne sorulabileceğini gösterir.
///
/// Boş bir sohbet kutusu kullanıcıya ne yapabileceğini söylemiyor; kapalı
/// bir soru kümesi olduğu için örnekleri göstermek şart.
class _Intro extends StatelessWidget {
  final ValueChanged<String> onPick;
  final AssistantIntent Function(String question) intentOf;

  const _Intro({required this.onPick, required this.intentOf});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final examples = context.tr('assistant_examples').split('|');

    // Tanıtım iki cümle: ilki başlık, gerisi açıklama. Tek cümlelik bir
    // çeviride hepsi açıklama olarak kalıyor.
    final intro = context.tr('assistant_intro');
    final cut = intro.indexOf('. ');
    final headline = cut > 0 ? intro.substring(0, cut + 1) : null;
    final body = cut > 0 ? intro.substring(cut + 2) : intro;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: t.secondary.withAlpha(40),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.dataset_outlined, size: 30, color: t.secondary),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (headline != null) ...[
          Text(
            headline,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 26,
              height: 1.2,
              color: t.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Icon(Icons.lock_outline, size: 15, color: t.secondary),
                ),
              ),
              TextSpan(text: body),
            ],
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final example in examples)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: () => onPick(example),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppCard.borderColor(t)),
                    boxShadow: AppShadows.soft(context),
                  ),
                  child: Row(
                    children: [
                      AppIconTile(
                        icon: _iconFor(intentOf(example)),
                        size: 30,
                        circle: true,
                        background: t.surfaceAlt,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          example,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 15,
                            color: t.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.north_east, size: 18, color: t.secondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr('assistant_privacy_note'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: t.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TurnView extends StatelessWidget {
  final String question;
  final String answer;
  final bool needsData;
  final AssistantIntent intent;

  const _TurnView({
    required this.question,
    required this.answer,
    required this.needsData,
    required this.intent,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Kısa cevap dergi başlığı gibi serif; uzun açıklama gövde yazısında
    // kalıyor, serif uzun paragrafta yorucu.
    final short = answer.length <= 110;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.soft(context),
              ),
              child: Text(
                question,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconTile(
                  icon: _iconFor(intent),
                  size: 36,
                  circle: true,
                  color: t.secondary,
                  background: t.surfaceAlt,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer,
                        style: short
                            ? theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 19,
                                height: 1.35,
                                color: t.text,
                              )
                            : theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                height: 1.5,
                                color: t.text,
                              ),
                      ),
                      if (needsData) ...[
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: () =>
                              context.pushNamed(RouteNames.calendar),
                          style: TextButton.styleFrom(
                            foregroundColor: t.secondary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(
                            Icons.edit_calendar_outlined,
                            size: 18,
                          ),
                          label: Text(context.tr('assistant_go_log')),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
