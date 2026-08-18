import 'package:flutter/material.dart';

/// Sağlık kütüphanesi kategorileri.
enum ArticleCategory {
  popular,
  period,
  nutrition,
  psychology,
  exercise;

  /// Kategori sekmesinin lokalizasyon anahtarı.
  String get labelKey => switch (this) {
    ArticleCategory.popular => 'health_library_cat_popular',
    ArticleCategory.period => 'health_library_cat_period',
    ArticleCategory.nutrition => 'health_library_cat_nutrition',
    ArticleCategory.psychology => 'health_library_cat_psychology',
    ArticleCategory.exercise => 'health_library_cat_exercise',
  };
}

/// Bir kütüphane makalesi.
///
/// Başlık ve etiket dile bağlı olduğu için metin değil **anahtar** tutulur;
/// arama yapılırken çevrilmiş başlık üzerinde eşleşme aranır.
class Article {
  final String titleKey;
  final String tagKey;
  final ArticleCategory category;
  final int readMinutes;

  /// Makale görselinin simgesi.
  ///
  /// Eskiden burada `imageUrl` vardı ve beş makalenin beşi de Google'ın
  /// geçici mockup adreslerini gösteriyordu; öne çıkan makalenin adresi
  /// çoktan HTTP 400 dönmeye başlamıştı. Görsel artık uygulama içinde
  /// çiziliyor (bkz. `ContentIllustration`).
  final IconData icon;

  /// Öne çıkan makale kartında gösterilir.
  final bool isFeatured;

  const Article({
    required this.titleKey,
    required this.tagKey,
    required this.category,
    required this.readMinutes,
    required this.icon,
    this.isFeatured = false,
  });
}

/// Uygulamadaki makale kataloğu.
///
/// Şimdilik sabit; ileride bir içerik servisinden beslenecek. Listenin tek
/// bir yerde durması arama ve kategori filtresinin aynı veriyi görmesini
/// sağlar — daha önce her widget kendi kopyasını taşıyordu.
class ArticleCatalog {
  const ArticleCatalog._();

  static const List<Article> all = [
    Article(
      titleKey: 'library_article_hormones',
      tagKey: 'library_cat_hormones',
      category: ArticleCategory.period,
      readMinutes: 8,
      icon: Icons.spa_outlined,
      isFeatured: true,
    ),
    Article(
      titleKey: 'library_article_pms',
      tagKey: 'library_cat_nutrition',
      category: ArticleCategory.nutrition,
      readMinutes: 4,
      icon: Icons.restaurant_menu,
    ),
    Article(
      titleKey: 'library_article_partner',
      tagKey: 'library_cat_relationships',
      category: ArticleCategory.psychology,
      readMinutes: 7,
      icon: Icons.favorite_outline,
    ),
    Article(
      titleKey: 'library_article_mood',
      tagKey: 'library_cat_psychology',
      category: ArticleCategory.psychology,
      readMinutes: 5,
      icon: Icons.psychology_outlined,
    ),
    Article(
      titleKey: 'library_article_iron',
      tagKey: 'library_cat_health',
      category: ArticleCategory.nutrition,
      readMinutes: 5,
      icon: Icons.local_dining_outlined,
    ),
  ];

  /// Kategoriye ve arama metnine göre süzer.
  ///
  /// [translate] başlık anahtarını çevirir; arama çevrilmiş metin üzerinde
  /// yapılır ki kullanıcı ekranda gördüğü kelimeyi arayabilsin.
  /// [ArticleCategory.popular] tümünü gösterir.
  static List<Article> filter({
    required ArticleCategory category,
    required String query,
    required String Function(String key) translate,
  }) {
    final normalizedQuery = _fold(query);

    return all.where((article) {
      final matchesCategory =
          category == ArticleCategory.popular || article.category == category;
      if (!matchesCategory) return false;

      if (normalizedQuery.isEmpty) return true;

      final haystack =
          '${_fold(translate(article.titleKey))} '
          '${_fold(translate(article.tagKey))}';
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  /// Büyük/küçük harf ve Türkçe karakter farkını önemsizleştirir.
  static String _fold(String value) {
    const map = {
      'ı': 'i',
      'İ': 'i',
      'ğ': 'g',
      'Ğ': 'g',
      'ü': 'u',
      'Ü': 'u',
      'ş': 's',
      'Ş': 's',
      'ö': 'o',
      'Ö': 'o',
      'ç': 'c',
      'Ç': 'c',
    };
    final buffer = StringBuffer();
    for (final char in value.trim().split('')) {
      buffer.write(map[char] ?? char);
    }
    return buffer.toString().toLowerCase();
  }
}
