import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../app/theme/app_colors.dart';
import '../app/theme/app_tokens.dart';

/// Centred spinner. For a whole-screen wait where nothing is known yet.
///
/// Prefer [SkeletonList] when the SHAPE of what is coming is already known: a
/// skeleton tells the user what they are waiting for, and makes the wait feel
/// shorter than a spinner does.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: Space.lg),
            Text(label!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Placeholder rows matching the layout that is loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 76,
    this.padding = const EdgeInsets.all(Space.lg),
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Shimmer.fromColors(
      baseColor: isLight ? AppColors.neutral100 : AppColors.surfaceDarkRaised,
      highlightColor:
          isLight ? AppColors.neutral0 : AppColors.neutral800,
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: Space.md),
        itemBuilder: (_, _) => Container(
          height: itemHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: Radii.lgAll,
          ),
        ),
      ),
    );
  }
}
