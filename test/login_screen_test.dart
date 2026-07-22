import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:plainsight/screens/login_screen.dart';
import 'package:plainsight/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        home: child,
      );

  testWidgets('renders the password field and a disabled-look submit button',
      (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Plainsight'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('the visibility toggle flips the password field between '
      'obscured and visible', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    TextField field() => tester.widget<TextField>(find.byType(TextField));
    expect(field().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump(const Duration(milliseconds: 50));
    expect(field().obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('typing a password does not throw', (tester) async {
    await tester.pumpWidget(wrap(const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byType(TextField), 'hunter2');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Sign in'), findsOneWidget);
  });
}
