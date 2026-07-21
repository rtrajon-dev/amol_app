import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/models/prayer_time_model.dart';

/// One prayer in the day's list.
///
/// Three states, and they have to be distinguishable at a glance while walking:
///
///  - **next** — filled with the prayer's own colour, so the eye lands on it
///    first without having to read anything
///  - **current** — the waqt in progress: tinted and outlined, present but not
///    shouting over the next one
///  - **past** — dimmed, still legible
///
/// FR-N-17 requires the active waqt not be signalled by colour alone, so the
/// current row also carries a text label and the next row an explicit one —
/// which is what makes this work for a colour-blind user too.
class PrayerCard extends StatelessWidget {
  const PrayerCard({
    super.key,
    required this.slot,
    required this.name,
    required this.time,
    required this.icon,
    this.isCurrent = false,
    this.isNext = false,
    this.isPast = false,
  });

  final PrayerSlot slot;
  final String name;
  final String time;
  final IconData icon;
  final bool isCurrent;
  final bool isNext;
  final bool isPast;

  Color get _slotColor => switch (slot) {
        PrayerSlot.fajr => AppColors.fajr,
        PrayerSlot.sunrise => AppColors.sunrise,
        PrayerSlot.dhuhr => AppColors.dhuhr,
        PrayerSlot.asr => AppColors.asr,
        PrayerSlot.maghrib => AppColors.maghrib,
        PrayerSlot.isha => AppColors.isha,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final color = _slotColor;

    final background = isNext
        ? color
        : (isCurrent
            ? color.withValues(alpha: isLight ? 0.08 : 0.16)
            : (isLight ? AppColors.surfaceLight : AppColors.surfaceDark));

    final foreground = isNext
        ? Colors.white
        : (isLight ? AppColors.textPrimary : AppColors.textPrimaryDark);

    final muted = isNext
        ? Colors.white.withValues(alpha: 0.82)
        : theme.colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: Motion.normal,
      curve: Motion.curve,
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.lg,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: Radii.lgAll,
        border: Border.all(
          color: isNext
              ? Colors.transparent
              : (isCurrent
                  ? color.withValues(alpha: 0.45)
                  : (isLight
                      ? AppColors.borderLight
                      : AppColors.borderDark)),
          width: isCurrent ? 1.4 : 1,
        ),
        boxShadow: isNext && isLight ? Shadows.glow(color) : Shadows.none,
      ),
      // A prayer already passed is dimmed rather than hidden: the user may
      // still want to confirm when Asr was, but it should not compete with
      // what is coming.
      child: Opacity(
        opacity: isPast && !isCurrent && !isNext ? 0.55 : 1,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isNext
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: isLight ? 0.12 : 0.22),
                borderRadius: Radii.smAll,
              ),
              child: Icon(icon, size: 20, color: isNext ? Colors.white : color),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppType.h3.copyWith(color: foreground)),
                  if (isCurrent || isNext) ...[
                    const SizedBox(height: 2),
                    Text(
                      isNext ? 'পরবর্তী নামাজ' : 'চলমান ওয়াক্ত',
                      style: AppType.labelSmall.copyWith(color: muted),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              time,
              style: AppType.h3.copyWith(
                color: foreground,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
