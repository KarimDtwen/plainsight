import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plainsight/screens/sites_screen.dart';
import 'package:plainsight/state/app_state.dart';
import 'package:plainsight/theme/app_theme.dart';

void main() {
  testWidgets(
      'shows the empty state for a fresh, logged-out session '
      '(no network attempted)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: AppStateProvider(state: state, child: const SitesScreen()),
    ));
    // Only the SharedPreferences restore runs (mocked, no session found) —
    // loadSites() is never triggered because the user isn't logged in, so
    // this never touches the network.
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No sites yet'), findsOneWidget);
    expect(find.text('Add your first site'), findsOneWidget);
  });
}
