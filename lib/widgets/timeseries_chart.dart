import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The dashboard's pageviews/visitors line chart. Colors always come from
/// `context.tokens.chartSeries` — never invented inline (see design-tokens
/// skill) — so the palette stays theme-stable and colorblind-safe.
class TimeseriesChart extends StatelessWidget {
  const TimeseriesChart({super.key, required this.points});

  final List<StatsPoint> points;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;

    if (points.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text('No data in this range yet',
              style: AppType.caption.copyWith(color: cs.onSurfaceVariant)),
        ),
      );
    }

    final pvColor = t.chartSeries[0];
    final visColor = t.chartSeries[1];

    final pvSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].pageviews.toDouble()),
    ];
    final visSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].visitors.toDouble()),
    ];
    final maxPv = points.map((p) => p.pageviews).fold(0, (a, b) => a > b ? a : b);
    final maxY = maxPv == 0 ? 10.0 : maxPv * 1.2;
    final labelEvery = (points.length / 5).ceil().clamp(1, points.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: pvColor, label: 'Pageviews'),
            SizedBox(width: t.m),
            _LegendDot(color: visColor, label: 'Visitors'),
          ],
        ),
        SizedBox(height: t.s),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                    strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: labelEvery.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final d = points[idx].bucket;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${d.month}/${d.day}',
                            style: AppType.caption.copyWith(
                                color: cs.onSurfaceVariant, fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => cs.inverseSurface,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: pvSpots,
                  isCurved: true,
                  color: pvColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: pvColor.withValues(alpha: 0.12)),
                ),
                LineChartBarData(
                  spots: visSpots,
                  isCurved: true,
                  color: visColor,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: AppType.caption
                  .copyWith(color: context.scheme.onSurfaceVariant)),
        ],
      );
}
