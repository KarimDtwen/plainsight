import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plainsight/models/models.dart';
import 'package:plainsight/theme/app_theme.dart';
import 'package:plainsight/widgets/breakdown_list.dart';
import 'package:plainsight/widgets/live_badge.dart';
import 'package:plainsight/widgets/stat_tile.dart';
import 'package:plainsight/widgets/timeseries_chart.dart';

void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? AppTheme.light(),
        home: Scaffold(body: child),
      );

  group('StatTile', () {
    testWidgets('renders its label and value', (tester) async {
      // StatTile's own root is a Row with an Expanded value/label column, so
      // (like every real call site) it needs a bounded-width parent — the
      // dashboard/share screens each wrap it in Expanded inside their
      // summary Row.
      await tester.pumpWidget(wrap(
        const Row(children: [
          Expanded(
            child: StatTile(
                label: 'Pageviews',
                value: '42',
                icon: Icons.visibility_outlined),
          ),
        ]),
      ));
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Pageviews'), findsOneWidget);
    });
  });

  group('TimeseriesChart', () {
    final points = [
      StatsPoint(bucket: DateTime(2026, 1, 1), pageviews: 10, visitors: 4),
      StatsPoint(bucket: DateTime(2026, 1, 2), pageviews: 25, visitors: 9),
      StatsPoint(bucket: DateTime(2026, 1, 3), pageviews: 5, visitors: 2),
    ];

    testWidgets('renders the legend and a chart for fixed data',
        (tester) async {
      await tester.pumpWidget(wrap(TimeseriesChart(points: points)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Pageviews'), findsOneWidget);
      expect(find.text('Visitors'), findsOneWidget);
    });

    testWidgets('shows an empty message when there is no data',
        (tester) async {
      await tester.pumpWidget(wrap(const TimeseriesChart(points: [])));
      expect(find.text('No data in this range yet'), findsOneWidget);
    });

    testWidgets('renders identically in dark mode without throwing',
        (tester) async {
      await tester.pumpWidget(
          wrap(TimeseriesChart(points: points), theme: AppTheme.dark()));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Pageviews'), findsOneWidget);
    });
  });

  group('BreakdownList', () {
    testWidgets('renders each row with its value and pageview count',
        (tester) async {
      await tester.pumpWidget(wrap(const BreakdownList(rows: [
        BreakdownRow(value: '/pricing', pageviews: 12, visitors: 8),
        BreakdownRow(value: '', pageviews: 3, visitors: 3),
      ])));
      expect(find.text('/pricing'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      // An empty referrer/value renders as "(direct)" rather than blank.
      expect(find.text('(direct)'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows an empty message when there are no rows',
        (tester) async {
      await tester.pumpWidget(wrap(const BreakdownList(rows: [])));
      expect(find.text('No data in this range yet'), findsOneWidget);
    });

    testWidgets('an empty country (no geoip match) renders as "Unknown"',
        (tester) async {
      await tester.pumpWidget(wrap(const BreakdownList(
        dimension: BreakdownDimension.country,
        rows: [BreakdownRow(value: '', pageviews: 5, visitors: 5)],
      )));
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('(direct)'), findsNothing);
    });
  });

  group('LiveBadge', () {
    // LiveBadge's pulse AnimationController repeats forever, same as the
    // gradient background — pump fixed durations here, never pumpAndSettle.
    testWidgets('shows the online count once the fetch resolves',
        (tester) async {
      await tester.pumpWidget(wrap(LiveBadge(fetchOnline: () async => 3)));
      expect(find.text('Live'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('3 online now'), findsOneWidget);
      // Unmount so the 10s poll Timer.periodic is cancelled — a still-pending
      // Timer at teardown otherwise fails the test.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('stays on "Live" if the fetch throws', (tester) async {
      await tester.pumpWidget(wrap(
          LiveBadge(fetchOnline: () async => throw Exception('boom'))));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Live'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
