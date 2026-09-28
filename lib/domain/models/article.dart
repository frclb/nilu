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

/// Makale gövdesinde tek bir bölüm.
class ArticleSection {
  /// Ara başlık. Giriş paragrafında `null`.
  final String? headingKey;

  /// Bölüm metni. Satır sonları paragraf ayırır.
  final String bodyKey;

  const ArticleSection({this.headingKey, required this.bodyKey});
}

/// Makalenin dayandığı kaynak.
///
/// Sağlık iddialarının nereden geldiği okunabilir olmalı; kaynaksız metin
/// kullanıcıdan güven istiyor ama karşılığını vermiyor. Etiket ve adres
/// çevrilmez — kurum adları ve URL'ler her dilde aynı.
class ArticleSource {
  final String label;
  final String url;

  const ArticleSource({required this.label, required this.url});
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

  /// Makale gövdesi.
  ///
  /// Önceden yalnızca başlık vardı: kütüphane beş başlık listeliyor ama
  /// dokununca "yakında" diyordu — alt menüdeki kök sekmelerden biri
  /// tamamen boştu.
  final List<ArticleSection> sections;

  /// Metnin dayandığı kaynaklar. Makale sonunda listelenir.
  final List<ArticleSource> sources;

  /// Makalenin sonunda tarif ekranına bağlantı çıksın mı?
  ///
  /// Tarif ekranı yazılmıştı ama hiçbir yerden açılmıyordu: rota tanımlıydı,
  /// kapısı yoktu. Elde tek bir tarif olduğu için burada rota kimliği değil
  /// bir bayrak duruyor — kütüphaneye "Tarifler" diye bir bölüm koymak
  /// olmayan bir katalog ima ederdi. Tarif çoğaldığında bu alan kimliğe
  /// dönüşür.
  final bool hasRecipe;

  const Article({
    required this.titleKey,
    required this.tagKey,
    required this.category,
    required this.readMinutes,
    required this.icon,
    required this.sections,
    required this.sources,
    this.hasRecipe = false,
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

  /// Öne çıkan makale; yoksa null.
  ///
  /// Kütüphane ekranı bunu `firstWhere` ile arıyordu ve hiçbir makale
  /// öne çıkarılmamışsa `StateError` fırlatıyordu — içerik düzenlemesi
  /// ekranı kırmızı hataya çeviriyordu. Varlığı `article_catalog_test`
  /// ile de sabitlendi; bu yalnızca ikinci savunma hattı.
  static Article? get featured {
    for (final article in all) {
      if (article.isFeatured) return article;
    }
    return null;
  }

  /// Başlık anahtarıyla makale; yoksa null.
  ///
  /// Ekranlar belirli makalelere anahtarla bağlanıyor (ör. kanama
  /// değerlendirmesinden demir eksikliği yazısına). Anahtar değişirse
  /// bağlantı sessizce kaybolmalı, uygulama çökmemeli.
  static Article? byKey(String titleKey) {
    for (final article in all) {
      if (article.titleKey == titleKey) return article;
    }
    return null;
  }

  static const List<Article> all = [
    Article(
      titleKey: 'library_article_hormones',
      tagKey: 'library_cat_hormones',
      category: ArticleCategory.period,
      readMinutes: 4,
      icon: Icons.spa_outlined,
      isFeatured: true,
      sections: [
        ArticleSection(bodyKey: 'article_hormones_intro'),
        ArticleSection(
          headingKey: 'article_hormones_h1',
          bodyKey: 'article_hormones_b1',
        ),
        ArticleSection(
          headingKey: 'article_hormones_h2',
          bodyKey: 'article_hormones_b2',
        ),
        ArticleSection(
          headingKey: 'article_hormones_h3',
          bodyKey: 'article_hormones_b3',
        ),
        ArticleSection(
          headingKey: 'article_hormones_h4',
          bodyKey: 'article_hormones_b4',
        ),
      ],
      sources: [
        ArticleSource(
          label: 'NHS — Periods',
          url: 'https://www.nhs.uk/conditions/periods/',
        ),
        ArticleSource(
          label: 'Office on Women\'s Health — Your menstrual cycle',
          url:
              'https://www.womenshealth.gov/menstrual-cycle/your-menstrual-cycle',
        ),
      ],
    ),
    Article(
      titleKey: 'library_article_pms',
      tagKey: 'library_cat_nutrition',
      category: ArticleCategory.nutrition,
      readMinutes: 4,
      icon: Icons.restaurant_menu,
      sections: [
        ArticleSection(bodyKey: 'article_pms_intro'),
        ArticleSection(headingKey: 'article_pms_h1', bodyKey: 'article_pms_b1'),
        ArticleSection(headingKey: 'article_pms_h2', bodyKey: 'article_pms_b2'),
        ArticleSection(headingKey: 'article_pms_h3', bodyKey: 'article_pms_b3'),
      ],
      sources: [
        ArticleSource(
          label: 'Office on Women\'s Health — Premenstrual syndrome',
          url:
              'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
        ),
        ArticleSource(
          label: 'NHS — PMS',
          url: 'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
        ),
      ],
      // Tarif magnezyum ve omega-3 üzerine; bu makalenin konusu da o.
      hasRecipe: true,
    ),
    Article(
      titleKey: 'library_article_partner',
      tagKey: 'library_cat_relationships',
      category: ArticleCategory.psychology,
      readMinutes: 3,
      icon: Icons.favorite_outline,
      sections: [
        ArticleSection(bodyKey: 'article_partner_intro'),
        ArticleSection(
          headingKey: 'article_partner_h1',
          bodyKey: 'article_partner_b1',
        ),
        ArticleSection(
          headingKey: 'article_partner_h2',
          bodyKey: 'article_partner_b2',
        ),
        ArticleSection(
          headingKey: 'article_partner_h3',
          bodyKey: 'article_partner_b3',
        ),
      ],
      sources: [
        ArticleSource(
          label: 'Office on Women\'s Health — Premenstrual syndrome',
          url:
              'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
        ),
      ],
    ),
    Article(
      titleKey: 'library_article_mood',
      tagKey: 'library_cat_psychology',
      category: ArticleCategory.psychology,
      readMinutes: 4,
      icon: Icons.psychology_outlined,
      sections: [
        ArticleSection(bodyKey: 'article_mood_intro'),
        ArticleSection(
          headingKey: 'article_mood_h1',
          bodyKey: 'article_mood_b1',
        ),
        ArticleSection(
          headingKey: 'article_mood_h2',
          bodyKey: 'article_mood_b2',
        ),
        ArticleSection(
          headingKey: 'article_mood_h3',
          bodyKey: 'article_mood_b3',
        ),
      ],
      sources: [
        ArticleSource(
          label: 'NHS — PMS',
          url: 'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
        ),
        ArticleSource(
          label: 'Office on Women\'s Health — Premenstrual syndrome',
          url:
              'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
        ),
      ],
    ),
    Article(
      titleKey: 'library_article_iron',
      tagKey: 'library_cat_health',
      category: ArticleCategory.nutrition,
      readMinutes: 4,
      icon: Icons.local_dining_outlined,
      sections: [
        ArticleSection(bodyKey: 'article_iron_intro'),
        ArticleSection(
          headingKey: 'article_iron_h1',
          bodyKey: 'article_iron_b1',
        ),
        ArticleSection(
          headingKey: 'article_iron_h2',
          bodyKey: 'article_iron_b2',
        ),
        ArticleSection(
          headingKey: 'article_iron_h3',
          bodyKey: 'article_iron_b3',
        ),
      ],
      sources: [
        ArticleSource(
          label: 'NHS — Iron deficiency anaemia',
          url: 'https://www.nhs.uk/conditions/iron-deficiency-anaemia/',
        ),
      ],
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
