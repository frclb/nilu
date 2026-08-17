import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class HealthLibraryArticleList extends StatelessWidget {
  const HealthLibraryArticleList({super.key});

  /// Başlıklar dile bağlı olduğu için liste `build` içinde, aktif dile göre
  /// kurulur — sınıf alanı olarak tutulamaz.
  List<Map<String, String>> _articles(BuildContext context) => [
    {
      'tag': context.tr('library_cat_nutrition'),
      'title': context.tr('library_article_pms'),
      'time': '4',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDg5vgbdAao9ao_4kx1A5rrTfnPPCuPc2WpEAwq2kGd0BnM-8znBiqvy2JPn9uOnPXk5PQwqglq7VpHlnveeQ5NPIOCTNBJ-GGImlCqHNL3NjueI_Dznb3KoryB5O46bul-pwKHs4j8CmO_X7_zMrpUvt-47S0RICZmlFwH7jxNrpMakT-GD0QsFp1MDHjmggTOzaTxKJj31l89TA2TCtQ_c3B82sSSzUCKwn2q5lbxCefYSf1LSJEfUEF08ecl9XV_WgIBB5FpOwY',
    },
    {
      'tag': context.tr('library_cat_relationships'),
      'title': context.tr('library_article_partner'),
      'time': '7',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDhn9fpLKSfBwJpmS0ZJLCRGCcjQ1jYb8ACMIOhfPHTK_lXvXP6Kt29-FvwKXl-Q9lmFYMKvo2EzRsUuzCrALRxS09bDgAjQ6X_iSSPPOGbS4ehYUO5oKCDRhSmP1yt8jAGy2hs0REvWX1DHZxXh1dOxlnd2pR97VKkG5hxAC1RvU3BJpUFSYaeRpuWiUTK7IjE6v0eF7JH9GfV1tvWmRVNIElS1XW6VSmGv0x4YjLz2O1-eAGlsGIESwk5HUipv6c2sW5_vOa8s3k',
    },
    {
      'tag': context.tr('library_cat_psychology'),
      'title': context.tr('library_article_mood'),
      'time': '5',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAoW707rVS7RDxsprckZ9rCktPcWj_2_xebEVnylauP9BYeu8k5ZC37jgguMZOVMWnTyqLtKGQ6YWDl4QRhpW4JThFLTPUbuilihET4yA_YBE8h6YK21B8sLG-XYVLmdLRRqKFnvFgID6MqweT7C4Uu4nbyQnCJ8nNYG7DQGpTaCHV2RtlY6FsaLfO1t9u4SdvfQ3IJb8GElFIEFW24nR-VZ1zMdSo-2D3YvZ-rzFxELc3ktdTwnjcwYQK-xiAAx3s-NOkqkQpcjO4',
    },
    {
      'tag': context.tr('library_cat_health'),
      'title': context.tr('library_article_iron'),
      'time': '5',
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuARjqhhUD_Xy75rqi_5FJCPKk45dHKkfPOvjxEO5APBx93T39eZ0aMj7VIkOmvEYZOdXowAx926UmexpuEwxuCesWzcd-hsYMGQgFOZmWj68OwBMOVaO0bCakdOuU9cD3GPgz4kPKS6SXpGqVEnHWVXVxdAE1W_9MN8vRMx8PfTrpImnAVAivTFSBaAB1B_9ykPyK9zj968HKdPYKfIU8u3Mo5JrOD5IWqpyqyvjziUEeI54KgcYDFeFtS8_HkFBSY1nCoytsOmSdQ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mockArticles = _articles(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.tr('health_library_recommended'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textMainSlate,
                ),
              ),
              Text(
                context.tr('health_library_see_all'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF8A4F5B)
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: mockArticles.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final article = mockArticles[index];
            return _buildArticleCard(context, article, theme, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildArticleCard(
    BuildContext context,
    Map<String, String> article,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        // Makale detay ekranı henüz yok. Buradan tarif ekranına gidiliyordu:
        // "PMS için 5 besin"e dokunan kullanıcı somonlu kinoa tarifiyle
        // karşılaşıyordu. Alakasız bir ekran açmaktansa dürüst mesaj.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('article_coming_soon'))),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceWarmDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(7),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: isDark
              ? Border.all(color: Colors.white.withAlpha(12))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                article['image']!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 96,
                  height: 96,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article['tag']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF8A4F5B)
                            : theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article['title']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textMainSlate,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context
                                  .tr('health_library_read_time_short')
                                  .replaceAll('{min}', article['time']!),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.bookmark_border,
                          size: 20,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
