import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// U-088 — shared section header (title + optional subtitle + trailing action).
/// Promotes the inline `_SectionHeader` pattern out of explore_tab. Pass
/// [onSeeAll] for the standard "See all ›" rail affordance.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  /// Renders a trailing "See all ›" affordance — every top-tier rail pattern
  /// has one; a rail without it is a dead end.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final cs = context.scheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppType.titleL.copyWith(color: cs.onSurface)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!,
                      style: AppType.caption
                          .copyWith(color: cs.onSurfaceVariant)),
                ),
            ],
          ),
        ),
        ?action,
        if (action == null && onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('See all',
                    style: AppType.label.copyWith(color: cs.primary)),
                Icon(Icons.chevron_right_rounded, size: 16, color: cs.primary),
              ]),
            ),
          ),
      ],
    );
  }
}
