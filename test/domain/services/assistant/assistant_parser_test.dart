import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/services/assistant/assistant_parser.dart';

void main() {
  // Gerçek kalıplarla aynı biçimde, Türkçe.
  const patterns = {
    AssistantIntent.nextPeriod:
        'sonraki+regl,regl+ne zaman,adet+ne zaman,'
        'kac gun+regl,regle+kac',
    AssistantIntent.currentPhase:
        'hangi+evre,hangi+faz,kacinci+gun,'
        'dongu+gunu,su an+nerede',
    AssistantIntent.fertileWindow: 'dogurgan,yumurtlama,ovulasyon,gebe kalma',
    AssistantIntent.cycleLength: 'dongum+kac,dongu+uzunlu,ortalama+dongu',
    AssistantIntent.periodLength:
        'reglim+kac gun,adetim+kac gun,'
        'regl+kac gun surer',
    AssistantIntent.regularity: 'duzenli+mi,duzensiz',
    AssistantIntent.lastSymptom: 'en son,son kez,ne zamandi',
  };

  const symptoms = {
    'Kramp': 'cramp',
    'Baş Ağrısı': 'headache',
    'Yorgunluk': 'fatigue',
    'Şişkinlik': 'bloating',
  };

  AssistantQuery ask(String q) =>
      AssistantParser.parse(q, patterns: patterns, symptomLabels: symptoms);

  group('normalize', () {
    test('Türkçe karakterleri ASCII\'ye indirir', () {
      expect(AssistantParser.normalize('Şişkinlik Ağrı'), 'siskinlik agri');
    });

    test('noktalama ve fazla boşluk temizlenir', () {
      expect(
        AssistantParser.normalize('  Regl,  ne   zaman? '),
        'regl ne zaman',
      );
    });

    test('boş girdi boş döner', () {
      expect(AssistantParser.normalize('   '), '');
    });
  });

  group('regl zamanı', () {
    test('doğrudan soru', () {
      expect(ask('reglim ne zaman').intent, AssistantIntent.nextPeriod);
    });

    test('ekli hâller de eşleşir', () {
      // Türkçe eklemeli: "regl" kalıbı "reglim", "regle" içinde de bulunur.
      expect(ask('regle kaç gün kaldı').intent, AssistantIntent.nextPeriod);
      expect(ask('sonraki reglim').intent, AssistantIntent.nextPeriod);
    });

    test('Türkçe karakter yazılmasa da eşleşir', () {
      expect(ask('regle kac gun kaldi').intent, AssistantIntent.nextPeriod);
    });
  });

  group('diğer niyetler', () {
    test('döngü günü', () {
      expect(ask('kaçıncı gündeyim').intent, AssistantIntent.currentPhase);
    });

    test('doğurganlık', () {
      expect(ask('ne zaman doğurganım').intent, AssistantIntent.fertileWindow);
      expect(ask('yumurtlama ne zaman').intent, AssistantIntent.fertileWindow);
    });

    test('döngü uzunluğu', () {
      expect(ask('döngüm kaç gün').intent, AssistantIntent.cycleLength);
    });

    test('regl süresi', () {
      expect(
        ask('reglim kaç gün sürüyor').intent,
        AssistantIntent.periodLength,
      );
    });

    test('düzenlilik', () {
      expect(ask('döngülerim düzenli mi').intent, AssistantIntent.regularity);
    });
  });

  group('belirti soruları', () {
    test('belirti sıklığı', () {
      final q = ask('kramplarım ne zaman oluyor');
      expect(q.intent, AssistantIntent.symptomFrequency);
      expect(q.symptomCode, 'cramp');
    });

    test('en son ne zaman', () {
      final q = ask('en son ne zaman baş ağrım oldu');
      expect(q.intent, AssistantIntent.lastSymptom);
      expect(q.symptomCode, 'headache');
    });

    test('belirti, zaman kalıbının önüne geçer', () {
      // "kramplarım ne zaman" hem belirti hem `nextPeriod` kalıbı taşıyor;
      // doğru cevap belirtiye ait olan.
      expect(ask('kramp ne zaman').intent, AssistantIntent.symptomFrequency);
    });

    test('uzun etiket kısa olanı gölgelemez', () {
      // "Baş Ağrısı" ararken yalnız "ağrı" ile eşleşip yanlış belirti
      // seçilmemeli.
      expect(ask('baş ağrısı sıklığı').symptomCode, 'headache');
    });
  });

  group('anlaşılmayan', () {
    test('alakasız soru unknown döner', () {
      expect(ask('hava nasıl olacak').intent, AssistantIntent.unknown);
    });

    test('boş girdi unknown döner', () {
      expect(ask('').intent, AssistantIntent.unknown);
      expect(ask('   ').intent, AssistantIntent.unknown);
    });

    test('uydurma cevap üretilmez', () {
      // Uygulamanın bilmediği bir şey soruldu; boş niyet dönmeli ki ekran
      // "şunları sorabilirsin" desin.
      expect(ask('gebe miyim').intent, AssistantIntent.unknown);
    });
  });
}
