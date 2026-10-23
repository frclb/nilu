import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_flavor.dart';
import 'app_palette.dart';
import 'app_snack.dart';
import 'app_tokens.dart';
import 'app_layout.dart';

/// Uygulama teması.
///
/// Renkler [AppTokens] üzerinden role göre okunur; burada yalnızca Flutter'ın
/// kendi bileşenlerine o rolleri bağlıyoruz. Yeni renk değeri **buraya**
/// yazılmaz, `AppPalette`'e eklenir.
class AppTheme {
  /// Diyalog eylem düğmesi biçimi.
  ///
  /// Tema, sayfa düzeyindeki çağrılara tam genişlik veriyor
  /// (`minimumSize: Size.fromHeight(52)` — genişlik sonsuz). Diyalog içinde bu
  /// düğmeyi kendi satırına itiyor ve "İptal" ile onay eylemi alt alta
  /// diziliyordu.
  static ButtonStyle dialogAction() => FilledButton.styleFrom(
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 20),
  );

  /// Uzun metin ekranlarının gövde yazısı.
  ///
  /// Gizlilik politikası, kullanım şartları ve sağlık kütüphanesi
  /// makaleleri aynı ölçüyü paylaşıyor; üçü de ayrı ayrı yazdığı için
  /// ayrışmaya açıktı.
  ///
  /// Satır aralığı 1.7 idi: 15 pt harfe 25 pt satır kutusu düşüyordu.
  /// iOS'un kendi gövde metni 17 pt harfe ~22 pt kutu veriyor — yani
  /// bizim metin, harfleri daha küçük olmasına rağmen daha seyrekti ve
  /// blok bu yüzden "iri" görünüyordu. 1.5 ile kutu 23 pt'ye iniyor.
  static TextStyle? readingBody(BuildContext context, {Color? color}) =>
      Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: color, fontSize: 15, height: 1.5);

  /// Uzun metin ekranlarının bölüm başlığı.
  ///
  /// `displayLarge` yani serif: makale başlıklarıyla aynı aile. Hukuki
  /// ekranlar bunu `TextStyle` ile sıfırdan yazdığı için gövde yazı
  /// tipinde kalıyordu.
  static TextStyle? readingHeading(BuildContext context, {Color? color}) =>
      Theme.of(context).textTheme.displayLarge?.copyWith(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  const AppTheme._();

  static ThemeData light(AppFlavor flavor) => _build(flavor, Brightness.light);
  static ThemeData dark(AppFlavor flavor) => _build(flavor, Brightness.dark);

  static ThemeData _build(AppFlavor flavor, Brightness brightness) {
    final t = AppTokens.of(flavor, brightness);
    final brand = brightness == Brightness.light
        ? flavor.brand
        : flavor.brandDark;
    final isLight = brightness == Brightness.light;
    final base = isLight ? ThemeData.light() : ThemeData.dark();

    // Başlıklar Newsreader (serif), gövde Plus Jakarta Sans.
    //
    // "Luminous Editorial Wellness" yenilemesi: başlıkta dergi tadında,
    // yumuşak bir serif; gövdede geometrik ama sıcak bir grotesk. Önceki
    // Fraunces 20px'te `ğ`'nin breve'ini çok küçük çiziyordu; Newsreader'ın
    // optik boyutu (28) diakritikleri net bırakıyor.
    // Yazı tipleri pakete gömülü (bkz. pubspec `fonts:`): ilk açılışta ağ
    // yavaşsa ekran sistem yazı tipiyle açılıp sonra değişmesin diye.
    final body = base.textTheme
        .apply(fontFamily: 'PlusJakartaSans')
        .apply(bodyColor: t.text, displayColor: t.text);

    final display = base.textTheme
        .apply(fontFamily: 'Newsreader')
        .apply(bodyColor: t.text, displayColor: t.text);

    final textTheme = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.8,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
      ),
      displaySmall: display.displaySmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      titleLarge: body.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: body.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: body.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: body.labelLarge?.copyWith(color: t.textMuted),
      bodyMedium: body.bodyMedium?.copyWith(height: 1.5),
    );

    final scheme =
        ColorScheme.fromSeed(
          seedColor: flavor.brand,
          brightness: brightness,
        ).copyWith(
          primary: brand,
          onPrimary: isLight ? Colors.white : AppPalette.night900,
          secondary: t.secondary,
          onSecondary: isLight ? Colors.white : AppPalette.night900,
          secondaryContainer: t.secondaryTint,
          tertiary: t.accent,
          surface: t.surface,
          onSurface: t.text,
          onSurfaceVariant: t.textMuted,
          outline: t.border,
          outlineVariant: t.border,
          error: t.danger,
        );

    // Kenarlıklar erik tonlu ve çok ince: gri çizgi sıcak zeminde kirli
    // duruyordu.
    final hairline = isLight ? brand.withAlpha(20) : t.border;
    final fieldBorder = isLight ? brand.withAlpha(31) : t.border;

    final buttonText = textTheme.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.1,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      textTheme: textTheme,
      extensions: [t],
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: t.text),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 17),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: hairline),
        ),
      ),

      dividerTheme: DividerThemeData(color: hairline, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        iconColor: brand,
        titleTextStyle: textTheme.titleMedium?.copyWith(color: t.text),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: t.textMuted),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        // Flutter diyaloğa azami genişlik vermiyor: 40 pt kenar boşluğu
        // dışında ekranı dolduruyor. Telefonda sorun değil ama iPad'de iki
        // satırlık bir soru 950 pt'ye yayılıyor ve düğmeler metinden yüzlerce
        // piksel uzağa düşüyordu.
        //
        // `minWidth` de yazılmak zorunda: `constraints` verildiğinde Flutter'ın
        // kendi 280 pt'lik asgarisi devre dışı kalıyor ve kısa bir diyalog
        // içeriğine göre 88 pt'ye büzülüyor.
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: AppLayout.contentMaxWidth,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontSize: 22,
          color: t.text,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: t.textMuted),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: t.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white.withAlpha(204) : t.surfaceAlt,
        hintStyle: textTheme.bodyMedium?.copyWith(color: t.textFaint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg + 2,
          vertical: AppSpacing.md + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: t.secondary, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ),
      ),

      // İkincil düğme: hafif erik zeminli "hayalet" hap.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: isLight ? brand.withAlpha(13) : t.surfaceAlt,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: fieldBorder),
          shape: const StadiumBorder(),
          textStyle: buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: const StadiumBorder(),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: t.surfaceAlt,
          selectedBackgroundColor: t.surface,
          selectedForegroundColor: scheme.primary,
          foregroundColor: t.textMuted,
          side: BorderSide(color: hairline),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isLight ? Colors.white.withAlpha(179) : t.surfaceAlt,
        selectedColor: t.brandTint,
        checkmarkColor: scheme.primary,
        side: BorderSide(color: hairline),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : t.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.secondary : t.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : fieldBorder,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.secondary : null,
        ),
        side: BorderSide(color: fieldBorder, width: 1.5),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? scheme.primary : t.textFaint,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: t.secondary,
        inactiveTrackColor: t.secondaryTint,
        thumbColor: scheme.primary,
        overlayColor: t.secondary.withAlpha(30),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppSnack.background(brightness),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppSnack.foreground,
        ),
        actionTextColor: AppSnack.actionForeground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: t.surfaceAlt,
      ),
    );
  }
}
