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

    // Başlıklar Lora (serif), gövde Inter.
    //
    // Öncesinde her şey Inter'dı ve ekranlar birbirinden ayrışmıyordu.
    // Başlıkta serif kullanmak sağlık uygulamasına klinik değil sakin bir
    // ton veriyor; gövdede grotesk kalması okunurluğu koruyor.
    //
    // Önce Fraunces denendi ama o bir "wonky" tasarım serifi: breve'i çok
    // küçük çiziyor ve 20px'te `ğ` ile `g` birbirinden ayrılmıyordu.
    // Türkçe birincil dil olduğu için diakritikleri sağlam çizen Lora
    // seçildi.
    // Yazı tipleri pakete gömülü (bkz. pubspec `fonts:`). Önce
    // `google_fonts` ile çalışma anında indiriliyorlardı; ilk açılışta ağ
    // yavaşsa ekran sistem yazı tipiyle açılıp sonra değişiyordu.
    final body = base.textTheme
        .apply(fontFamily: 'Inter')
        .apply(bodyColor: t.text, displayColor: t.text);

    final display = base.textTheme
        .apply(fontFamily: 'Fraunces')
        .apply(bodyColor: t.text, displayColor: t.text);

    final textTheme = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: display.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: body.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
          secondary: t.brandTint,
          onSecondary: t.text,
          tertiary: t.accent,
          surface: t.surface,
          onSurface: t.text,
          outline: t.border,
          error: t.danger,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      textTheme: textTheme,
      extensions: [t],

      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: t.text),
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 18),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      // Gölge yerine kenarlık: sıcak zeminde gölge kirli görünüyor,
      // ince kenarlık kartları daha net ayırıyor.
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: t.border),
        ),
      ),

      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),

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
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: t.textMuted),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceAlt,
        hintStyle: textTheme.bodyMedium?.copyWith(color: t.textFaint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: t.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceAlt,
        side: BorderSide(color: t.border),
        labelStyle: textTheme.bodyMedium,
        shape: const StadiumBorder(),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : t.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? scheme.primary : t.surfaceAlt,
        ),
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
