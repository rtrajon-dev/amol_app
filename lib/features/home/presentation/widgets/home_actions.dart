import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/theme_mode_provider.dart';
import '../../../../global_widgets/option_picker.dart';

/// Theme and language, reachable from the home header.
///
/// These sit here rather than buried in Profile because they are settings a
/// user changes on impulse — dark mode because the room got dark, not because
/// they went looking for a settings screen. Everything else stays in Profile:
/// promoting a setting to the home screen costs permanent real estate on the
/// most-seen surface in the app, so it has to earn the space.
class HomeActions extends ConsumerWidget {
  const HomeActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroIconButton(
          // Shows the state the app is IN, like a switch showing on or off,
          // rather than the state a tap would produce. Both conventions exist;
          // this one is the more common and does not require the user to
          // reason backwards about what they are looking at.
          icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          tooltip: isDark ? 'লাইট থিমে যান' : 'ডার্ক থিমে যান',
          onTap: () {
            // No confirmation and no sheet: a two-state toggle that opens a
            // menu costs two taps to do what one should.
            HapticFeedback.selectionClick();
            ref.read(themeModeProvider.notifier).toggle();
          },
        ),
        const SizedBox(width: Space.sm),
        _HeroIconButton(
          icon: Icons.translate_rounded,
          tooltip: 'ভাষা',
          onTap: () => _pickLanguage(context),
        ),
      ],
    );
  }

  /// Bangla only in this release (C-02).
  ///
  /// Shows the picker with the one supported language selected, rather than a
  /// snackbar saying "no". Answering "what language is this, and can I change
  /// it?" is a legitimate question, and a list that visibly holds one entry
  /// answers it in a way a toast does not.
  Future<void> _pickLanguage(BuildContext context) async {
    await showOptionPicker<String>(
      context: context,
      title: 'ভাষা',
      current: 'bn',
      options: const [
        PickerOption(
          value: 'bn',
          label: 'বাংলা',
          description: 'এই সংস্করণে শুধু বাংলা সমর্থিত',
        ),
      ],
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: Radii.smAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.smAll,
          child: SizedBox(
            // 40dp — under Material's 48 because these sit inside a dense
            // header, but still comfortably above the ~32dp where thumbs start
            // missing.
            width: 40,
            height: 40,
            child: AnimatedSwitcher(
              duration: Motion.fast,
              // Cross-fade rather than a slide: the icon swaps in place, so
              // the tap reads as the same control changing state instead of a
              // different control arriving.
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 19,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
