import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/article.dart';

/// Makale gövdeleri anahtarlara dolaylı olarak (`section.bodyKey`) erişiyor;
/// bir yazım hatası derlemede değil ancak ekranda ham anahtar olarak görünür.
/// Bu test onu erken yakalar.
void main() {
  final locales = Directory('lib/localization')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  Iterable<String> keysOf(Article a) sync* {
    yield a.titleKey;
    yield a.tagKey;
    for (final s in a.sections) {
      if (s.headingKey != null) yield s.headingKey!;
      yield s.bodyKey;
    }
  }

  group('ArticleCatalog', () {
    test('her makalenin gövdesi ve kaynağı var', () {
      expect(ArticleCatalog.all, isNotEmpty);
      for (final article in ArticleCatalog.all) {
        expect(
          article.sections,
          isNotEmpty,
          reason: '${article.titleKey} gövdesiz',
        );
        expect(
          article.sources,
          isNotEmpty,
          reason:
              '${article.titleKey} kaynaksız — sağlık iddiası '
              'kaynaksız yayınlanmamalı',
        );
        expect(article.readMinutes, greaterThan(0));
      }
    });

    test('kullandığı tüm anahtarlar her dilde var', () {
      for (final file in locales) {
        final map =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final article in ArticleCatalog.all) {
          for (final key in keysOf(article)) {
            expect(
              map.containsKey(key),
              isTrue,
              reason: '${file.path} içinde $key eksik',
            );
          }
        }
      }
    });

    test('ekranın kendi anahtarları her dilde var', () {
      const screenKeys = [
        'article_sources',
        'article_disclaimer',
        'article_read_minutes',
      ];
      for (final file in locales) {
        final map =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final key in screenKeys) {
          expect(
            map.containsKey(key),
            isTrue,
            reason: '${file.path} içinde $key eksik',
          );
        }
      }
    });

    test('kaynak adresleri https ve boş değil', () {
      for (final article in ArticleCatalog.all) {
        for (final source in article.sources) {
          expect(source.label, isNotEmpty);
          expect(
            source.url,
            startsWith('https://'),
            reason: '${article.titleKey}: ${source.url}',
          );
        }
      }
    });
  });

  group('ekranların dayandığı varsayımlar', () {
    // Kütüphane ekranı öne çıkan makaleyi gösteriyor. Hiç yoksa bölüm
    // atlanıyor (artık çökmüyor) ama ekran da eksik kalır; birden çoksa
    // hangisinin çıkacağı sıraya bağlı olur.
    test('tam olarak bir makale öne çıkarılmış', () {
      final one = ArticleCatalog.all.where((a) => a.isFeatured).toList();
      expect(one.length, 1, reason: 'öne çıkan makale sayısı 1 olmalı');
      expect(ArticleCatalog.featured, isNotNull);
    });

    // Kanama değerlendirmesi demir eksikliği yazısına anahtarla bağlanıyor.
    // Anahtar değişirse bağlantı sessizce kaybolur; burada yakalanmalı.
    test('ekranların anahtarla bağlandığı makaleler duruyor', () {
      for (final key in ['library_article_iron']) {
        expect(
          ArticleCatalog.byKey(key),
          isNotNull,
          reason: '$key katalogdan kalkmış; ona bağlanan ekran boş kalır',
        );
      }
    });

    test('başlık anahtarları benzersiz', () {
      final keys = ArticleCatalog.all.map((a) => a.titleKey).toList();
      expect(keys.toSet().length, keys.length, reason: 'yinelenen anahtar var');
    });
  });
}
