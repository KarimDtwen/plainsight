import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Hand-rolled fraction-bar rows — the same shape for pages, referrers,
/// countries, devices, and browsers. Bar width is proportional to the
/// top row's pageviews so the busiest item always reads as a full bar.
class BreakdownList extends StatelessWidget {
  const BreakdownList({
    super.key,
    required this.rows,
    this.dimension = BreakdownDimension.referrer,
  });

  final List<BreakdownRow> rows;

  /// Which dimension these rows came from — only affects the label shown
  /// for an empty `value` ("(direct)" for a referrer, "Unknown" for a
  /// country the geoip database couldn't resolve; every other dimension
  /// is never actually empty).
  final BreakdownDimension dimension;

  @override
  Widget build(BuildContext context) {
    final cs = context.scheme;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No data in this range yet',
              style: AppType.caption.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }
    final maxPv = rows.map((r) => r.pageviews).reduce((a, b) => a > b ? a : b);
    final emptyLabel =
        dimension == BreakdownDimension.country ? 'Unknown' : '(direct)';
    return Column(
      children: [
        for (final row in rows)
          _BreakdownRowTile(
            row: row,
            fraction: maxPv == 0 ? 0 : row.pageviews / maxPv,
            emptyLabel: emptyLabel,
            icon: _iconFor(dimension, row.value),
          ),
      ],
    );
  }

  /// A small leading glyph per row — mostly to give each row visual weight
  /// (the fraction bar alone leaves a lot of empty space for low-share
  /// rows), but device/browser icons are also genuinely informative.
  static IconData _iconFor(BreakdownDimension dimension, String value) {
    switch (dimension) {
      case BreakdownDimension.page:
        return Icons.description_outlined;
      case BreakdownDimension.referrer:
        return Icons.link_rounded;
      case BreakdownDimension.country:
        return Icons.public_rounded;
      case BreakdownDimension.browser:
        return Icons.language_rounded;
      case BreakdownDimension.device:
        switch (value) {
          case 'mobile':
            return Icons.smartphone_rounded;
          case 'tablet':
            return Icons.tablet_mac_rounded;
          case 'desktop':
            return Icons.computer_rounded;
          default:
            return Icons.devices_other_rounded;
        }
    }
  }
}

class _BreakdownRowTile extends StatelessWidget {
  const _BreakdownRowTile({
    required this.row,
    required this.fraction,
    required this.emptyLabel,
    required this.icon,
  });

  final BreakdownRow row;
  final double fraction;
  final String emptyLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    final label = row.value.isEmpty ? emptyLabel : row.value;
    return Padding(
      padding: EdgeInsets.only(bottom: t.s),
      child: Stack(
        children: [
          // The fraction bar sits behind the text as a soft tinted fill.
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.03, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.electric.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(t.radiusSm),
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: cs.onSurfaceVariant),
                SizedBox(width: t.xs),
                Expanded(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(color: cs.onSurface)),
                ),
                Text('${row.pageviews}',
                    style: AppType.label.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
