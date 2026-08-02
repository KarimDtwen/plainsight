import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../ui/animated_gradient_background.dart';

/// A single big-number stat card (pageviews, visitors, …) used in the
/// dashboard's summary row. The icon-in-a-tinted-circle leader (same recipe
/// as the sites list's site icon) gives the card a filled, intentional look
/// instead of a big empty box around a small number.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.electric,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    return GlassSurface(
      borderRadius: BorderRadius.circular(t.radiusLg),
      boxShadow: t.shadowCard,
      padding: EdgeInsets.symmetric(vertical: t.m, horizontal: t.m),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(t.radiusMd),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          SizedBox(width: t.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: AppType.displayM.copyWith(color: cs.onSurface)),
                Text(label,
                    style: AppType.caption.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
