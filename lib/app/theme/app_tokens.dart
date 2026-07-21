import 'package:flutter/material.dart';

/// Design tokens — the vocabulary every screen is built from.
///
/// The point of naming these is that a value used in twelve places changes in
/// one. Ad-hoc numbers scattered through widgets are how an app drifts into
/// looking like six apps stitched together.
///
/// Deliberately NOT scaled with `flutter_screenutil`. Spacing and radii are
/// physical-comfort constants — a 16dp gutter is 16dp because that is how far
/// a thumb travels, not because the design mock was 390pt wide. Scaling them
/// makes a small phone cramped and a tablet cartoonish. Font sizes DO scale,
/// which is where screenutil earns its place.
abstract class Space {
  /// 4 — hairline separation, icon-to-label.
  static const xs = 4.0;

  /// 8 — within a component.
  static const sm = 8.0;

  /// 12 — between related rows.
  static const md = 12.0;

  /// 16 — the standard gutter. Most things are this.
  static const lg = 16.0;

  /// 20 — between distinct blocks.
  static const xl = 20.0;

  /// 28 — section separation.
  static const xxl = 28.0;

  /// 40 — hero breathing room.
  static const xxxl = 40.0;
}

abstract class Radii {
  /// 8 — chips, small controls.
  static const sm = 8.0;

  /// 12 — buttons, fields.
  static const md = 12.0;

  /// 16 — cards. The workhorse.
  static const lg = 16.0;

  /// 22 — hero surfaces, sheets.
  static const xl = 22.0;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

  /// Sheets and the hero header: rounded at the bottom only.
  static const BorderRadius bottomXl = BorderRadius.vertical(
    bottom: Radius.circular(xl),
  );
}

/// Shadows, defined once so elevation reads as one system.
///
/// Material's default `elevation:` is deliberately not used. Its shadows are
/// tuned for a grey backdrop and go muddy on the warm off-white this app uses;
/// these are softer, wider and tinted toward the primary hue, which is what
/// makes a card look like it is resting on the surface rather than cut out of
/// it.
abstract class Shadows {
  static const _tint = Color(0xFF0B3B2E);

  /// Resting card.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ];

  /// Raised — the next-prayer hero, active states.
  static List<BoxShadow> get raised => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.10),
          blurRadius: 22,
          offset: const Offset(0, 8),
        ),
      ];

  /// Coloured glow, for a primary CTA that should feel alive.
  static List<BoxShadow> glow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.32),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Dark theme: shadows read as noise on a near-black surface, so elevation
  /// there is carried by border and fill instead.
  static const List<BoxShadow> none = [];
}

/// Motion. Short, consistent, and never decorative.
///
/// Every duration here is under 300ms: this app is opened many times a day for
/// a few seconds each, and an animation the user waits through is a tax paid
/// on every one of those visits.
abstract class Motion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 280);

  /// Default easing — quick to start, gentle to settle.
  static const curve = Curves.easeOutCubic;

  /// For something entering the screen.
  static const enter = Curves.easeOutQuart;
}
