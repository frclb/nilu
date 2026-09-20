import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/article.dart';
import 'package:period_tracker/domain/services/cycle_alert.dart';

/// Sağlık kütüphanesinin denetimi.
///
/// Makaleler tıbbi iddia taşıyor. Bu dosya içeriğin doğruluğunu
/// değerlendiremez — o bir uzmanın işi ve mağaza listesinde bekleyen bir
/// madde. Denetlenebilen şey yapı: kaynak var mı, uygulamanın kendi
/// eşikleriyle çelişiyor mu, uygulama hakkında tutmadığı sözler veriyor mu.
void main() {
  const languages = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

  Map<String, dynamic> dictionary(String lang) =>
      jsonDecode(File('lib/localization/$lang.json').readAsStringSync())
          as Map<String, dynamic>;

  group('her makale kaynak gösteriyor', () {
    for (final article in ArticleCatalog.all) {
      test(article.titleKey, () {
        // Kaynaksız sağlık metni kullanıcıdan güven istiyor ama
        // karşılığını vermiyor.
        expect(article.sources, isNotEmpty);

        for (final source in article.sources) {
          expect(source.label.trim(), isNotEmpty);
          expect(
            Uri.tryParse(source.url)?.isAbsolute,
            isTrue,
            reason: '${source.label}: adres geçersiz',
          );
          expect(
            source.url,
            startsWith('https://'),
            reason: '${source.label}: şifresiz bağlantı',
          );
        }
      });
    }
  });

  group('metinler her dilde eksiksiz', () {
    test('başlık, etiket ve bölümler çevrilmiş', () {
      for (final lang in languages) {
        final keys = dictionary(lang).keys;
        for (final article in ArticleCatalog.all) {
          expect(keys, contains(article.titleKey), reason: lang);
          expect(keys, contains(article.tagKey), reason: lang);
          for (final section in article.sections) {
            if (section.headingKey != null) {
              expect(keys, contains(section.headingKey), reason: lang);
            }
            expect(keys, contains(section.bodyKey), reason: lang);
          }
        }
      }
    });
  });

  group('uygulamayla çelişmiyor', () {
    test('döngü uzunluğu eşiği uyarı servisiyle aynı', () {
      // Makale bir yandan "21–35 gün normaldir" diyor, öte yandan aynı
      // makalenin sonunda "24 günden kısaysa hekime danış" yazıyordu.
      // 22 günlük döngüsü olan kullanıcı iki paragrafta iki farklı şey
      // okuyor, üstelik uygulama da 24'te uyarı veriyordu.
      final min = CycleAlertService.minTypicalDays;
      final max = CycleAlertService.maxTypicalDays;

      for (final lang in languages) {
        final d = dictionary(lang);
        final intro = d['article_hormones_b1'] as String;
        expect(
          intro,
          contains('$min'),
          reason: '$lang: makale uygulamanın alt eşiğini anmıyor',
        );
        expect(
          intro,
          contains('$max'),
          reason: '$lang: makale uygulamanın üst eşiğini anmıyor',
        );
      }
    });

    test('partnerin döngü evresini gördüğü iddiası yok', () {
      // Partnere döngü verisi hiç gitmiyor. Bu iddia eşleşme ekranından
      // ve gizlilik politikasından temizlenmişti; makalede hayatta
      // kalmıştı.
      const claims = {
        'tr': 'hangi evrede olduğunu görebilir',
        'en': 'they can see which phase you are in',
        'de': 'sieht, in welcher phase du bist',
        'es': 'puede ver en qué fase estás',
        'fr': 'voit dans quelle phase tu es',
        'pt': 'vê em que fase estás',
      };

      for (final lang in languages) {
        final body = (dictionary(lang)['article_partner_b1'] as String)
            .toLowerCase();
        expect(
          body,
          isNot(contains(claims[lang])),
          reason: '$lang: partnere gitmeyen bir veri vaat ediliyor',
        );
      }
    });
  });

  group('sorumluluk reddi her makalede', () {
    test('makale ekranı koşulsuz gösteriyor', () {
      final screen = File(
        'lib/presentation/health_library/article_screen.dart',
      ).readAsStringSync();

      expect(screen.contains("tr('article_disclaimer')"), isTrue);
      // Koşula bağlanırsa bazı makalelerde kaybolur.
      expect(
        RegExp(r'if\s*\([^)]*\)\s*_Disclaimer').hasMatch(screen),
        isFalse,
        reason: 'sorumluluk reddi koşullu gösteriliyor',
      );
    });

    test('metin tıbbi tavsiye olmadığını söylüyor', () {
      for (final lang in languages) {
        expect(
          (dictionary(lang)['article_disclaimer'] as String).trim(),
          isNotEmpty,
          reason: '$lang: sorumluluk reddi boş',
        );
      }
    });
  });
}
