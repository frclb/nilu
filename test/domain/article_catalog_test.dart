import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/article.dart';

/// Testlerde çeviri yerine anahtarı okunur bir başlığa çeviren sahte sözlük.
String fakeTranslate(String key) {
  const map = {
    'library_article_hormones': 'Regl Döngüsünde Hormonların Dansı',
    'library_article_pms': 'PMS Semptomlarını Hafifletmek İçin 5 Besin',
    'library_article_partner': 'Partnerinizle Döngünüz Hakkında Konuşmak',
    'library_article_mood': 'Regl Döneminde Duygu Durum Değişiklikleri',
    'library_article_iron': 'Demir Eksikliği: Belirtiler ve Beslenme',
    'library_cat_hormones': 'HORMON SAĞLIĞI',
    'library_cat_nutrition': 'BESLENME',
    'library_cat_relationships': 'İLİŞKİLER',
    'library_cat_psychology': 'PSİKOLOJİ',
    'library_cat_health': 'SAĞLIK',
  };
  return map[key] ?? key;
}

List<Article> run({
  ArticleCategory category = ArticleCategory.popular,
  String query = '',
}) => ArticleCatalog.filter(
  category: category,
  query: query,
  translate: fakeTranslate,
);

void main() {
  group('katalog', () {
    test('tam olarak bir öne çıkan makale vardır', () {
      expect(ArticleCatalog.all.where((a) => a.isFeatured), hasLength(1));
    });

    test('her makalenin okuma süresi pozitiftir', () {
      for (final a in ArticleCatalog.all) {
        expect(a.readMinutes, greaterThan(0), reason: a.titleKey);
      }
    });
  });

  group('kategori filtresi', () {
    test('"popüler" tümünü gösterir', () {
      expect(run().length, ArticleCatalog.all.length);
    });

    test('beslenme yalnızca beslenme makalelerini gösterir', () {
      final results = run(category: ArticleCategory.nutrition);
      expect(results, isNotEmpty);
      for (final a in results) {
        expect(a.category, ArticleCategory.nutrition);
      }
    });

    test('makalesi olmayan kategori boş döner', () {
      expect(run(category: ArticleCategory.exercise), isEmpty);
    });
  });

  group('arama', () {
    test('başlıkta geçen kelimeyi bulur', () {
      final results = run(query: 'demir');
      expect(results, hasLength(1));
      expect(results.single.titleKey, 'library_article_iron');
    });

    test('etikette geçen kelimeyi bulur', () {
      final results = run(query: 'psikoloji');
      expect(results, hasLength(1));
      expect(results.single.titleKey, 'library_article_mood');
    });

    test('büyük/küçük harf farkı önemsizdir', () {
      expect(run(query: 'DEMİR'), hasLength(1));
      expect(run(query: 'demir'), hasLength(1));
    });

    test('Türkçe karakter farkı önemsizdir', () {
      // Kullanıcı Türkçe klavye kullanmıyorsa "psikoloji" yazamayabilir.
      expect(run(query: 'psikoloji').length, run(query: 'PSİKOLOJİ').length);
      expect(run(query: 'semptom'), hasLength(1));
    });

    test('baştaki/sondaki boşluk sonucu değiştirmez', () {
      expect(run(query: '  demir  '), hasLength(1));
    });

    test('eşleşme yoksa boş döner', () {
      expect(run(query: 'bulunmayanbirkelime'), isEmpty);
    });

    test('boş arama tümünü gösterir', () {
      expect(run(query: '').length, ArticleCatalog.all.length);
      expect(run(query: '   ').length, ArticleCatalog.all.length);
    });
  });

  group('arama ve kategori birlikte', () {
    test('ikisi de uygulanır', () {
      // "regl" hem hormon (period) hem ruh hali (psychology) makalesinde geçer.
      expect(run(query: 'regl').length, greaterThan(1));

      final onlyPeriod = run(query: 'regl', category: ArticleCategory.period);
      expect(onlyPeriod, hasLength(1));
      expect(onlyPeriod.single.titleKey, 'library_article_hormones');
    });

    test('kategori eşleşse de arama tutmuyorsa boş döner', () {
      expect(run(query: 'zzzz', category: ArticleCategory.nutrition), isEmpty);
    });
  });

  test('kategori etiket anahtarları tanımlıdır', () {
    for (final c in ArticleCategory.values) {
      expect(c.labelKey, startsWith('health_library_cat_'));
    }
  });
}
