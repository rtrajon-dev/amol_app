import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Light and dark themes, built once from tokens.
///
/// Component themes are set here rather than per-widget so a screen that just
/// drops in a `Card` or an `ElevatedButton` is already correct. The rule is:
/// if a widget needs `.copyWith` to look right, the theme is wrong.
abstract class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final surface = isLight ? AppColors.surfaceLight : AppColors.surfaceDark;
    final background =
        isLight ? AppColors.backgroundLight : AppColors.backgroundDark;
    final border = isLight ? AppColors.borderLight : AppColors.borderDark;
    final textPrimary =
        isLight ? AppColors.textPrimary : AppColors.textPrimaryDark;
    final textSecondary =
        isLight ? AppColors.textSecondary : AppColors.textSecondaryDark;

    // Light uses the deep 700 so white text clears contrast everywhere. Dark
    // uses the lighter 400: a dark-on-dark primary is unreadable, and this is
    // the pair most themes get wrong.
    final brandColor = isLight ? AppColors.primary700 : AppColors.primary400;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: brandColor,
      onPrimary: isLight ? AppColors.neutral0 : AppColors.primary900,
      primaryContainer:
          isLight ? AppColors.primary50 : AppColors.primary900,
      onPrimaryContainer:
          isLight ? AppColors.primary900 : AppColors.primary100,
      secondary: AppColors.accent500,
      onSecondary: AppColors.neutral900,
      secondaryContainer:
          isLight ? AppColors.accent100 : AppColors.accent700,
      onSecondaryContainer:
          isLight ? AppColors.accent700 : AppColors.accent100,
      error: AppColors.error,
      onError: AppColors.neutral0,
      errorContainer: isLight ? AppColors.errorSurface : AppColors.error,
      onErrorContainer: isLight ? AppColors.error : AppColors.neutral0,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      outlineVariant: border,
    );

    final textTheme = AppType.themeFor(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,

      // Kalpurush everywhere, including widgets that build their own styles.
      fontFamily: AppType.bangla,

      // The default ripple is heavy on a low-end panel and reads as lag. A
      // short, light highlight communicates the same thing for less.
      splashFactory: InkSparkle.splashFactory,
      highlightColor: brandColor.withValues(alpha: 0.04),

      appBarTheme: AppBarTheme(
        // Flat and surface-coloured, not a slab of brand colour. A coloured bar
        // on every screen competes with the content and makes the hero headers
        // that DO use brand colour stop feeling special.
        backgroundColor: surface,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: AppType.h2.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        // Shadow is drawn by the widgets that need it (Shadows.card), so cards
        // stay flat here and elevation is expressed once, deliberately.
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: border, width: isLight ? 1 : 1),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: brandColor,
        unselectedItemColor:
            isLight ? AppColors.neutral400 : AppColors.neutral500,
        selectedLabelStyle: AppType.labelSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppType.labelSmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: isLight ? AppColors.neutral0 : AppColors.primary900,
          disabledBackgroundColor:
              isLight ? AppColors.neutral200 : AppColors.neutral800,
          disabledForegroundColor:
              isLight ? AppColors.neutral400 : AppColors.neutral600,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: AppType.h3,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandColor,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: AppType.h3,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandColor,
          textStyle: AppType.label,
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.neutral50 : AppColors.surfaceDarkRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: brandColor, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: AppColors.error, width: 1.6),
        ),
        labelStyle: AppType.body.copyWith(color: textSecondary),
        hintStyle: AppType.body.copyWith(
          color: isLight ? AppColors.textTertiary : AppColors.neutral500,
        ),
        errorStyle: AppType.bodySmall.copyWith(color: AppColors.error),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.xs,
        ),
        titleTextStyle: AppType.bodyLarge.copyWith(color: textPrimary),
        subtitleTextStyle: AppType.bodySmall.copyWith(color: textSecondary),
        iconColor: textSecondary,
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isLight ? AppColors.neutral800 : AppColors.surfaceDarkRaised,
        contentTextStyle: AppType.body.copyWith(color: AppColors.neutral0),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        insetPadding: const EdgeInsets.all(Space.lg),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: Radii.xlAll),
        titleTextStyle: AppType.h2.copyWith(color: textPrimary),
        contentTextStyle: AppType.body.copyWith(color: textSecondary),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brandColor
              : Colors.transparent,
        ),
        side: BorderSide(color: border, width: 1.6),
        shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.neutral0
              : (isLight ? AppColors.neutral0 : AppColors.neutral400),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? brandColor
              : (isLight ? AppColors.neutral200 : AppColors.neutral700),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brandColor,
        linearTrackColor:
            isLight ? AppColors.neutral200 : AppColors.neutral800,
        circularTrackColor: Colors.transparent,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.neutral100 : AppColors.surfaceDarkRaised,
        selectedColor: isLight ? AppColors.primary50 : AppColors.primary900,
        labelStyle: AppType.labelSmall.copyWith(color: textPrimary),
        side: BorderSide(color: border),
        shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
      ),

      // One transition for the whole app. Android's default zoom is heavy on a
      // low-end GPU; a fade-through reads as faster and costs less.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
