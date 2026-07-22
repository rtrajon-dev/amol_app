import 'package:flutter/material.dart';

/// The palette.
///
/// Built around a deep emerald rather than the slate blue this started with.
/// Green carries obvious meaning in an Islamic context, and it also solves a
/// practical problem: the old primary sat close to the "info" blue every
/// Android system surface uses, so the app never looked like itself. The gold
/// accent is reserved almost entirely for premium and completion — scarcity is
/// what keeps an accent meaning something.
///
/// Ramps run 50 (lightest) to 900 (darkest), which is what makes states
/// derivable instead of invented: a hover is one step up, a pressed state one
/// step down, a disabled state a low-opacity neutral.
abstract class AppColors {
  // ------------------------------------------------------------- brand ramp

  static const primary50 = Color(0xFFE8F5EF);
  static const primary100 = Color(0xFFC6E6D8);
  static const primary200 = Color(0xFF9FD5BE);
  static const primary300 = Color(0xFF74C3A3);
  static const primary400 = Color(0xFF4FB58F);
  static const primary500 = Color(0xFF17A67B); // brand
  static const primary600 = Color(0xFF0E8F69);
  static const primary700 = Color(0xFF0A7454);
  static const primary800 = Color(0xFF075A41);
  static const primary900 = Color(0xFF043D2C);

  /// The one to reach for. Dark enough for white text at every size, which
  /// keeps buttons and headers accessible without special-casing.
  static const primary = primary700;
  static const primaryLight = primary400;
  static const primaryDark = primary900;

  // ------------------------------------------------------------ accent ramp
  //
  // Gold. Used for premium, streaks and completion — never for navigation, or
  // it stops signalling "special".

  static const accent100 = Color(0xFFFBF0CE);
  static const accent300 = Color(0xFFEBCF74);
  static const accent500 = Color(0xFFD9A82C); // brand gold
  static const accent700 = Color(0xFFA87C12);

  static const accent = accent500;
  static const accentLight = accent100;

  // ---------------------------------------------------------------- neutrals
  //
  // Warm-tinted rather than pure grey. A neutral carrying a trace of the brand
  // hue is what stops a light UI looking like unstyled HTML.

  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF7F9F8);
  static const neutral100 = Color(0xFFEEF2F0);
  static const neutral200 = Color(0xFFDFE5E2);
  static const neutral300 = Color(0xFFC6CFCB);
  static const neutral400 = Color(0xFF9AA5A0);
  static const neutral500 = Color(0xFF6E7A75);
  static const neutral600 = Color(0xFF4E5A55);
  static const neutral700 = Color(0xFF39433F);
  static const neutral800 = Color(0xFF232B28);
  static const neutral900 = Color(0xFF141A18);

  // ------------------------------------------------------------- light theme

  static const backgroundLight = neutral50;
  static const surfaceLight = neutral0;

  /// A card sitting ON a card — settings groups, nested tiles.
  static const surfaceLightRaised = neutral0;
  static const borderLight = neutral200;

  static const textPrimary = neutral900;
  static const textSecondary = neutral500;
  static const textTertiary = neutral400;
  static const textLight = neutral0;

  // -------------------------------------------------------------- dark theme
  //
  // Not pure black. #000 with an OLED panel produces visible smearing when a
  // list scrolls, and it makes elevation impossible to express.

  static const backgroundDark = Color(0xFF0E1513);
  static const surfaceDark = Color(0xFF16201D);
  static const surfaceDarkRaised = Color(0xFF1E2A26);
  static const borderDark = Color(0xFF2A3733);

  static const textPrimaryDark = Color(0xFFE8EDEB);
  static const textSecondaryDark = Color(0xFF9AA5A0);

  // ---------------------------------------------------------------- semantic

  static const success = Color(0xFF17A67B);
  static const successSurface = Color(0xFFE8F5EF);
  static const warning = Color(0xFFD98324);
  static const warningSurface = Color(0xFFFDF2E4);
  static const error = Color(0xFFD1453B);
  static const errorSurface = Color(0xFFFCEBEA);
  /// Informational blue. Deliberately not part of the brand ramp — it is for
  /// things that report state rather than express identity.
  static const info = Color(0xFF1F6FE0);

  /// Dark-theme pairing. The 600-weight blue above is unreadable on a near
  /// black surface, which is the usual way a "works in light mode" colour
  /// ships broken.
  static const infoLight = Color(0xFF6BA8F5);

  /// Tinted fill behind info-coloured content.
  static const infoSurface = Color(0xFFEAF2FE);

  // ------------------------------------------------------------ prayer times
  //
  // Each prayer takes the colour of its own sky. This is the one place the app
  // uses colour decoratively, and it earns it: the palette makes the five
  // prayers instantly distinguishable at a glance, which is the whole job of
  // the prayer list.

  /// Before dawn — deep indigo.
  static const fajr = Color(0xFF3B4E7E);

  /// Sunrise — warm amber.
  static const sunrise = Color(0xFFE8913A);

  /// Midday — high, bright gold.
  static const dhuhr = Color(0xFFD9A82C);

  /// Afternoon — softening orange.
  static const asr = Color(0xFFCE7B39);

  /// Sunset — dusk rose.
  static const maghrib = Color(0xFFB5544E);

  /// Night — deep slate.
  static const isha = Color(0xFF2E3D52);

  // ------------------------------------------------------------------ ramps

  /// The header gradient. Two adjacent ramp stops, not a rainbow: a gradient
  /// spanning distant hues reads as a decoration, one spanning neighbours
  /// reads as depth.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary800, primary600],
  );

  static const heroGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06120F), primary900],
  );

  /// Premium surfaces.
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent500, accent700],
  );
}
