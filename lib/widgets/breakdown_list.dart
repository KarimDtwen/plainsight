import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Hand-rolled fraction-bar rows — the same shape for pages, referrers,
/// countries, devices, and browsers. Bar width is proportional to the
/// top row's pageviews so the busiest item always reads as a full bar.
class BreakdownList extends StatelessWidget {
  const BreakdownList({super.key, required this.rows});

  final List<BreakdownRow> rows;

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
    return Column(
      children: [
        for (final row in rows)
          _BreakdownRowTile(
            row: row,
            fraction: maxPv == 0 ? 0 : row.pageviews / maxPv,
          ),
      ],
    );
  }
}

class _BreakdownRowTile extends StatelessWidget {
  const _BreakdownRowTile({required this.row, required this.fraction});

  final BreakdownRow row;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    final label = row.value.isEmpty ? '(direct)' : row.value;
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
