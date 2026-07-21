import 'package:flutter/material.dart';
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
    final mode = ref.watch(themeModeProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroIconButton(
          icon: _iconFor(context, mode),
          tooltip: 'থিম',
          onTap: () => _pickTheme(context, ref, mode),
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

  /// Reflects what the user is actually looking at, not the stored setting.
  /// On `system` that means showing the resolved brightness — an icon claiming
  /// "light" while the screen is dark would be worse than no icon.
  IconData _iconFor(BuildContext context, ThemeMode mode) {
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    return isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded;
  }

  /// Opens the full picker rather than toggling. A tap-to-cycle would make
  /// "follow the system" unreachable without three taps and no way to tell
  /// which of the three you had landed on.
  Future<void> _pickTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final chosen = await showOptionPicker<ThemeMode>(
      context: context,
      title: 'থিম',
      current: current,
      options: [
        for (final mode in ThemeMode.values)
          PickerOption(value: mode, label: ThemeModeNotifier.labelFor(mode)),
      ],
    );

    if (chosen != null) {
      await ref.read(themeModeProvider.notifier).set(chosen);
    }
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
            child: Icon(icon, size: 19, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
