import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../global_widgets/app_state_view.dart';
import '../../../../global_widgets/loading_indicator.dart';
import '../../domain/models/tasbeeh_model.dart';
import '../viewmodel/tasbeeh_viewmodel.dart';
import '../widgets/tasbeeh_selector.dart';

class TasbeehScreen extends ConsumerWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tasbeehProvider);
    final notifier = ref.read(tasbeehProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('তাসবিহ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.reset,
            tooltip: 'গণনা রিসেট',
          ),
          const SizedBox(width: Space.xs),
        ],
      ),
      body: asyncState.when(
        loading: () => const LoadingIndicator(),
        error: (_, _) => AppStateView.error(title: 'তাসবিহ লোড করা যাচ্ছে না'),
        data: (state) => _TasbeehBody(state: state, notifier: notifier),
      ),
    );
  }
}

class _TasbeehBody extends StatelessWidget {
  const _TasbeehBody({required this.state, required this.notifier});

  final TasbeehState state;
  final TasbeehNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        state.selected.target > 0 ? state.count / state.selected.target : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.md),
          child: TasbeehSelector(
            presets: TasbeehModel.presets,
            selected: state.selected,
            onSelect: notifier.select,
          ),
        ),

        // The dhikr itself, in Amiri. Given room to breathe — this is the
        // thing being recited, not a label on a counter.
        Expanded(
          flex: 3,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.selected.arabic,
                    style: AppType.arabicLarge
                        .copyWith(color: theme.colorScheme.onSurface),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.md),
                  Text(
                    state.selected.bangla,
                    style: AppType.body
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // The counter, ringed by its own progress — so the target is legible
        // without a separate bar competing for attention.
        Expanded(
          flex: 4,
          child: Center(
            child: _CounterButton(
              count: state.count,
              target: state.selected.target,
              progress: progress,
              onTap: notifier.increment,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            0,
            Space.xl,
            Space.xxl,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Stat(
                label: 'লক্ষ্য',
                value: BanglaNumerals.from(state.selected.target),
              ),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: Space.xl),
                color: theme.dividerColor,
              ),
              _Stat(
                label: 'আজকের মোট',
                value: BanglaNumerals.from(state.displayTotal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The tap target.
///
/// Deliberately enormous: this is tapped a hundred times in a sitting, often
/// without looking at the screen, so it has to be findable by thumb alone.
class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.count,
    required this.target,
    required this.progress,
    required this.onTap,
  });

  final int count;
  final int target;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final size = 210.0;

    return GestureDetector(
      onTap: () {
        // Light rather than medium: at this tap rate a heavy buzz becomes
        // unpleasant, and the wrist notices the difference over a hundred
        // repetitions.
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                duration: Motion.fast,
                builder: (_, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor:
                      isLight ? AppColors.neutral200 : AppColors.neutral800,
                  valueColor:
                      AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
            ),
            Container(
              width: size - 34,
              height: size - 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isLight
                    ? AppColors.heroGradient
                    : AppColors.heroGradientDark,
                boxShadow: isLight
                    ? Shadows.glow(theme.colorScheme.primary)
                    : Shadows.none,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    BanglaNumerals.from(count),
                    style: AppType.displayLarge.copyWith(color: Colors.white),
                  ),
                  Text(
                    'স্পর্শ করুন',
                    style: AppType.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: AppType.h2.copyWith(color: theme.colorScheme.onSurface),
        ),
        Text(
          label,
          style: AppType.labelSmall
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
