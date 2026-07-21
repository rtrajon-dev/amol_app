import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_tokens.dart';

/// The standard surface. Everything that groups content sits on one of these.
///
/// Wraps `Card` rather than replacing it so the theme still applies, but adds
/// the two things the Material card gets wrong here: a tinted shadow instead of
/// Material's grey one, and a tap target that keeps the ink inside the rounded
/// corners.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.raised = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  /// Lifts the card — for the one element on a screen that leads.
  final bool raised;

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final surface = color ??
        (isLight ? AppColors.surfaceLight : AppColors.surfaceDark);
    final border = borderColor ??
        (isLight ? AppColors.borderLight : AppColors.borderDark);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: border),
        // Shadows disappear against a near-black surface, so dark mode carries
        // elevation with the border and fill it already has.
        boxShadow: isLight
            ? (raised ? Shadows.raised : Shadows.card)
            : Shadows.none,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.lgAll,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A card that carries brand colour — the next prayer, the streak, premium.
///
/// Kept distinct from [AppCard] so gradient surfaces stay rare. If everything
/// is a gradient, nothing leads.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(Space.xl),
    this.onTap,
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient ??
            (isLight
                ? AppColors.heroGradient
                : AppColors.heroGradientDark),
        borderRadius: Radii.lgAll,
        boxShadow: isLight ? Shadows.raised : Shadows.none,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.lgAll,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
