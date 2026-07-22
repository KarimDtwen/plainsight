import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plainsight/main.dart';
import 'package:plainsight/theme/app_spacing.dart';
import 'package:plainsight/theme/app_theme.dart';

void main() {
  testWidgets('app shell shows the login screen once no session is found',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const PlainsightApp());
    // The aurora drift loops forever — pump fixed frames, never pumpAndSettle.
    // A couple of pumps let the async SharedPreferences restore complete.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Plainsight'), findsOneWidget);
    expect(find.text('Sign in to your dashboard'), findsOneWidget);
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
