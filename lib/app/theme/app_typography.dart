import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Type scale.
///
/// **This replaces `google_fonts`, which was a live bug.** `GoogleFonts.hind`
/// fetches its font over the network at first paint. On a device with no
/// connection that threw an unhandled exception on launch and fell back to
/// Roboto — in an app whose entire interface is Bangla, aimed at rural users on
/// intermittent data, that shipped with Kalpurush already bundled and unused.
///
/// Everything now resolves to a bundled family:
///   - **Kalpurush** — Bangla and Latin. Purpose-built for Bengali script, with
///     the conjuncts (যুক্তাক্ষর) and matra alignment that a Latin-first font
///     renders as broken clusters.
///   - **Amiri** — Arabic only. Naskh, and the correct register for Qur'anic
///     text; using a UI font for আয়াত would be a category error.
///
/// Sizes scale with `.sp` so the layout tracks device width, and every style
/// honours the OS text-size setting.
abstract class AppType {
  static const bangla = 'Kalpurush';
  static const arabic = 'Amiri';

  /// Bangla numerals for a countdown or a prayer time need tabular spacing, or
  /// the row jitters as digits change. Kalpurush has no tabular variant, so the
  /// callers that need it lock the width instead.
  static const _family = bangla;

  // ------------------------------------------------------------------ display
  //
  // Reserved for one number per screen: the countdown, the tasbeeh count.

  static TextStyle get displayLarge => TextStyle(
        fontFamily: _family,
        fontSize: 44.sp,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: _family,
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.3,
      );

  // ------------------------------------------------------------------ heading

  static TextStyle get h1 => TextStyle(
        fontFamily: _family,
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle get h2 => TextStyle(
        fontFamily: _family,
        fontSize: 19.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get h3 => TextStyle(
        fontFamily: _family,
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        height: 1.35,
      );

  // --------------------------------------------------------------------- body
  //
  // 1.5 line height. Bangla sets taller than Latin — matras sit above the line
  // and descenders below — so the 1.4 that suits English crowds it.

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _family,
        fontSize: 15.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get body => TextStyle(
        fontFamily: _family,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: _family,
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  // -------------------------------------------------------------------- label

  static TextStyle get label => TextStyle(
        fontFamily: _family,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: _family,
        fontSize: 11.5.sp,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );

  /// Section eyebrows and overlines.
  static TextStyle get overline => TextStyle(
        fontFamily: _family,
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.6,
      );

  // ------------------------------------------------------------------- arabic
  //
  // Larger than the surrounding UI by design. Arabic script carries its detail
  // in diacritics that vanish at Latin body sizes, and this is scripture — it
  // should feel weightier than a form label.

  static TextStyle get arabicLarge => TextStyle(
        fontFamily: arabic,
        fontSize: 30.sp,
        fontWeight: FontWeight.w400,
        height: 2.0,
      );

  static TextStyle get arabicMedium => TextStyle(
        fontFamily: arabic,
        fontSize: 22.sp,
        fontWeight: FontWeight.w400,
        height: 1.9,
      );

  /// Builds the Material text theme from the scale above, so any widget that
  /// reads `Theme.of(context).textTheme` lands on the same type system.
  static TextTheme themeFor(Brightness brightness) {
    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.textPrimaryDark;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondary
        : AppColors.textSecondaryDark;

    return TextTheme(
      displayLarge: displayLarge.copyWith(color: primary),
      displayMedium: displayMedium.copyWith(color: primary),
      headlineLarge: h1.copyWith(color: primary),
      headlineMedium: h2.copyWith(color: primary),
      headlineSmall: h3.copyWith(color: primary),
      titleLarge: h2.copyWith(color: primary),
      titleMedium: h3.copyWith(color: primary),
      titleSmall: label.copyWith(color: primary),
      bodyLarge: bodyLarge.copyWith(color: primary),
      bodyMedium: body.copyWith(color: primary),
      bodySmall: bodySmall.copyWith(color: secondary),
      labelLarge: label.copyWith(color: primary),
      labelMedium: labelSmall.copyWith(color: secondary),
      labelSmall: overline.copyWith(color: secondary),
    );
  }
}

/// Bangla numerals.
///
/// The app speaks Bangla, so `৪:১৫` rather than `4:15`. Centralised because a
/// screen that mixes the two looks like a translation someone abandoned
/// halfway.
abstract class BanglaNumerals {
  static const _digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  static String from(Object value) {
    final buffer = StringBuffer();
    for (final rune in value.toString().runes) {
      final char = String.fromCharCode(rune);
      final digit = int.tryParse(char);
      buffer.write(digit == null ? char : _digits[digit]);
    }
    return buffer.toString();
  }
}
