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
  final String imageUrl;

  /// Öne çıkan makale kartında gösterilir.
  final bool isFeatured;

  const Article({
    required this.titleKey,
    required this.tagKey,
    required this.category,
    required this.readMinutes,
    required this.imageUrl,
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
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBhVchXwSzfa9gpXHrqLxKdOvDx5aRHBpjHFVLJmmzKfXsFtxvHRxCfXBEzUKTtGRUXKktMHzZcvbSPLGkkl3CIYYPQwsAFwPBLTOZQmFvWLDVaLDPYQxT_9DKMHxRUgqZfLQlnvNIxDDpNSTdyxLXvIJqAtMFLGjXQGnJHnQZzqFHsvxlYsUBLBUgS',
      isFeatured: true,
    ),
    Article(
      titleKey: 'library_article_pms',
      tagKey: 'library_cat_nutrition',
      category: ArticleCategory.nutrition,
      readMinutes: 4,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDg5vgbdAao9ao_4kx1A5rrTfnPPCuPc2WpEAwq2kGd0BnM-8znBiqvy2JPn9uOnPXk5PQwqglq7VpHlnveeQ5NPIOCTNBJ-GGImlCqHNL3NjueI_Dznb3KoryB5O46bul-pwKHs4j8CmO_X7_zMrpUvt-47S0RICZmlFwH7jxNrpMakT-GD0QsFp1MDHjmggTOzaTxKJj31l89TA2TCtQ_c3B82sSSzUCKwn2q5lbxCefYSf1LSJEfUEF08ecl9XV_WgIBB5FpOwY',
    ),
    Article(
      titleKey: 'library_article_partner',
      tagKey: 'library_cat_relationships',
      category: ArticleCategory.psychology,
      readMinutes: 7,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDhn9fpLKSfBwJpmS0ZJLCRGCcjQ1jYb8ACMIOhfPHTK_lXvXP6Kt29-FvwKXl-Q9lmFYMKvo2EzRsUuzCrALRxS09bDgAjQ6X_iSSPPOGbS4ehYUO5oKCDRhSmP1yt8jAGy2hs0REvWX1DHZxXh1dOxlnd2pR97VKkG5hxAC1RvU3BJpUFSYaeRpuWiUTK7IjE6v0eF7JH9GfV1tvWmRVNIElS1XW6VSmGv0x4YjLz2O1-eAGlsGIESwk5HUipv6c2sW5_vOa8s3k',
    ),
    Article(
      titleKey: 'library_article_mood',
      tagKey: 'library_cat_psychology',
      category: ArticleCategory.psychology,
      readMinutes: 5,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAoW707rVS7RDxsprckZ9rCktPcWj_2_xebEVnylauP9BYeu8k5ZC37jgguMZOVMWnTyqLtKGQ6YWDl4QRhpW4JThFLTPUbuilihET4yA_YBE8h6YK21B8sLG-XYVLmdLRRqKFnvFgID6MqweT7C4Uu4nbyQnCJ8nNYG7DQGpTaCHV2RtlY6FsaLfO1t9u4SdvfQ3IJb8GElFIEFW24nR-VZ1zMdSo-2D3YvZ-rzFxELc3ktdTwnjcwYQK-xiAAx3s-NOkqkQpcjO4',
    ),
    Article(
      titleKey: 'library_article_iron',
      tagKey: 'library_cat_health',
      category: ArticleCategory.nutrition,
      readMinutes: 5,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuARjqhhUD_Xy75rqi_5FJCPKk45dHKkfPOvjxEO5APBx93T39eZ0aMj7VIkOmvEYZOdXowAx926UmexpuEwxuCesWzcd-hsYMGQgFOZmWj68OwBMOVaO0bCakdOuU9cD3GPgz4kPKS6SXpGqVEnHWVXVxdAE1W_9MN8vRMx8PfTrpImnAVAivTFSBaAB1B_9ykPyK9zj968HKdPYKfIU8u3Mo5JrOD5IWqpyqyvjziUEeI54KgcYDFeFtS8_HkFBSY1nCoytsOmSdQ',
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
