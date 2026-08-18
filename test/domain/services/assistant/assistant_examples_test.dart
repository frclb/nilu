import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/domain/services/assistant/assistant_parser.dart';

/// Ekranda gösterilen örnek soruların hepsi çalışmalı.
///
/// Bunlar dokunulabilir çipler: biri yanlış niyete düşerse kullanıcı ilk
/// denemesinde alakasız bir cevap alır. Kalıplar ve örnekler ayrı
/// lokalizasyon anahtarlarında olduğu için biri değişince diğeri sessizce
/// bozulabiliyor — bu test onu yakalar.
void main() {
  Map<String, dynamic> load(String lang) =>
      jsonDecode(File('lib/localization/$lang.json').readAsStringSync())
          as Map<String, dynamic>;

  Map<AssistantIntent, String> patternsOf(Map<String, dynamic> d) => {
    for (final intent in AssistantIntent.values)
      if (intent != AssistantIntent.unknown)
        intent: d['assistant_kw_${intent.name}'] as String? ?? '',
  };

  Map<String, String> symptomsOf(Map<String, dynamic> d) => {
    for (final code in LogVocabulary.symptoms)
      (d[LogVocabulary.symptomKey(code)] as String? ?? code): code,
  };

  for (final lang in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
    test('$lang: her örnek soru bir niyete düşer', () {
      final dict = load(lang);
      final examples = (dict['assistant_examples'] as String).split('|');

      expect(examples, isNotEmpty);

      for (final example in examples) {
        final query = AssistantParser.parse(
          example,
          patterns: patternsOf(dict),
          symptomLabels: symptomsOf(dict),
        );
        expect(
          query.intent,
          isNot(AssistantIntent.unknown),
          reason: '$lang → "$example" anlaşılmadı',
        );
      }
    });
  }

  test('tr: örnekler doğru niyete düşer', () {
    final dict = load('tr');
    final patterns = patternsOf(dict);
    final symptoms = symptomsOf(dict);

    AssistantQuery ask(String q) =>
        AssistantParser.parse(q, patterns: patterns, symptomLabels: symptoms);

    // Regresyon: "Reglime kaç gün kaldı?" regl **süresi** cevabı veriyordu;
    // `periodLength` kalıbı "reglim"+"kac gun" ile fazla genişti.
    expect(ask('Reglime kaç gün kaldı?').intent, AssistantIntent.nextPeriod);
    expect(ask('Kaçıncı gündeyim?').intent, AssistantIntent.currentPhase);
    expect(ask('Döngüm kaç gün sürüyor?').intent, AssistantIntent.cycleLength);
    expect(ask('Döngülerim düzenli mi?').intent, AssistantIntent.regularity);
    expect(
      ask('Kramplarım ne zaman oluyor?').intent,
      AssistantIntent.symptomFrequency,
    );
    expect(ask('Ne zaman doğurganım?').intent, AssistantIntent.fertileWindow);

    // Regl süresi hâlâ kendi sorusuyla çalışmalı.
    expect(ask('Reglim kaç gün sürüyor?').intent, AssistantIntent.periodLength);
  });
}
