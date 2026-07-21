import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'animated_gradient_background.dart';
import 'shimmer.dart';

/// Skeleton placeholders built on [ShimmerBox], shown while lists load instead
/// of a bare spinner or a content pop-in. Skeletons render on the same
/// [GlassSurface] the loaded cards use, so content doesn't "pop" from an
/// opaque slab into translucent glass.

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.compact = true});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (compact) {
      return Padding(
        padding: EdgeInsets.only(bottom: t.m),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(t.radiusLg),
          boxShadow: t.shadowCard,
          padding: EdgeInsets.all(t.m + 2),
          child: Row(children: [
            ShimmerBox(width: 60, height: 60, borderRadius: t.radiusMd),
            SizedBox(width: t.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 170, height: 13, borderRadius: 6),
                  SizedBox(height: t.s),
                  ShimmerBox(width: 110, height: 11, borderRadius: 6),
                ],
              ),
            ),
          ]),
        ),
      );
    }
    // Full card skeleton: image block + two text bars.
    return Padding(
      padding: EdgeInsets.only(bottom: t.m),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(t.radiusXl),
        boxShadow: t.shadowCard,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(t.radiusXl)),
            child:
                ShimmerBox(width: double.infinity, height: 150, borderRadius: 0),
          ),
          Padding(
            padding: EdgeInsets.all(t.m + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 200, height: 15, borderRadius: 6),
                SizedBox(height: t.s),
                ShimmerBox(width: 140, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

/// A list of skeleton cards. Drop-in for a loading view.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({
    super.key,
    this.count = 6,
    this.compact = true,
    this.padding,
  });

  final int count;
  final bool compact;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: count,
      itemBuilder: (_, _) => CardSkeleton(compact: compact),
    );
  }
}
