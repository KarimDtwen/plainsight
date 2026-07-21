import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plainsight/main.dart';
import 'package:plainsight/theme/app_spacing.dart';
import 'package:plainsight/theme/app_theme.dart';

void main() {
  testWidgets('app shell renders the wordmark on the gradient scaffold',
      (tester) async {
    await tester.pumpWidget(const PlainsightApp());
    // The aurora drift loops forever — pump fixed frames, never pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Plainsight'), findsOneWidget);
    expect(find.textContaining('Privacy-first'), findsOneWidget);
  });

  testWidgets('both themes expose AppTokens with the chart palette',
      (tester) async {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      late AppTokens tokens;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(builder: (context) {
          tokens = context.tokens;
          return const SizedBox.shrink();
        }),
      ));
      expect(tokens.chartSeries.length, greaterThanOrEqualTo(6),
          reason: 'chartSeries token must cover 6 breakdown series');
      expect(tokens.bgGradient, isNotEmpty);
    }
  });
}
