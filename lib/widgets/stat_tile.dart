import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../ui/animated_gradient_background.dart';

/// A single big-number stat card (pageviews, visitors, …) used in the
/// dashboard's summary row.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent = AppColors.electric,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    return GlassSurface(
      borderRadius: BorderRadius.circular(t.radiusLg),
      boxShadow: t.shadowCard,
      padding: EdgeInsets.symmetric(vertical: t.l, horizontal: t.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          SizedBox(height: t.s),
          Text(value, style: AppType.displayM.copyWith(color: cs.onSurface)),
          SizedBox(height: 2),
          Text(label,
              style: AppType.caption.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
