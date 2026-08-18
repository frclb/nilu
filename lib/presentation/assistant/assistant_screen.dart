import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/log_vocabulary.dart';
import '../../domain/services/assistant/assistant_answer.dart';
import '../../domain/services/assistant/assistant_parser.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../calendar/view_models/calendar_view_model.dart';

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

  void _ask(String question) {
    final text = question.trim();
    if (text.isEmpty) return;

    final viewModel = context.read<CalendarViewModel>();

    // Belirti adları kullanıcının dilinde eşleşmeli.
    final symptomLabels = {
      for (final code in LogVocabulary.symptoms)
        context.tr(LogVocabulary.symptomKey(code)): code,
    };

    final patterns = {
      for (final intent in AssistantIntent.values)
        if (intent != AssistantIntent.unknown)
          intent: context.tr('assistant_kw_${intent.name}'),
    };

    final query = AssistantParser.parse(
      text,
      patterns: patterns,
      symptomLabels: symptomLabels,
    );

    final answer = AssistantAnswerBuilder.build(
      query,
      cycleInfo: viewModel.cycleInfo,
      periodLogs: viewModel.periodLogs,
      dailyLogs: viewModel.dailyLogs,
      now: DateTime.now(),
    );

    setState(() {
      _turns.insert(0, _Turn(question: text, answer: answer));
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
    return '${date.day} ${context.monthName(date.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('assistant_title'))),
      body: Column(
        children: [
          Expanded(
            child: _turns.isEmpty
                ? _Intro(onPick: _ask)
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _turns.length,
                    itemBuilder: (context, index) {
                      final turn = _turns[index];
                      return _TurnView(
                        question: turn.question,
                        answer: _render(turn.answer),
                        needsData: turn.answer.needsData,
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              MediaQuery.of(context).padding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: t.surface,
              border: Border(top: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _ask,
                    decoration: InputDecoration(
                      hintText: context.tr('assistant_hint'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: () => _ask(_controller.text),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Turn {
  final String question;
  final AssistantAnswer answer;

  const _Turn({required this.question, required this.answer});
}

/// İlk açılışta ne sorulabileceğini gösterir.
///
/// Boş bir sohbet kutusu kullanıcıya ne yapabileceğini söylemiyor; kapalı
/// bir soru kümesi olduğu için örnekleri göstermek şart.
class _Intro extends StatelessWidget {
  final ValueChanged<String> onPick;

  const _Intro({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final examples = context.tr('assistant_examples').split('|');

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: t.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('assistant_intro'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        for (final example in examples)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                onTap: () => onPick(example),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(example, style: theme.textTheme.bodyMedium),
                      ),
                      Icon(
                        Icons.north_east,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr('assistant_privacy_note'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: t.textFaint,
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

  const _TurnView({
    required this.question,
    required this.answer,
    required this.needsData,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Text(
                question,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answer,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                if (needsData) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () => context.pushNamed(RouteNames.calendar),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: Text(context.tr('assistant_go_log')),
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
