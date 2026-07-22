import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/sites_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/animated_gradient_background.dart';

void main() => runApp(const PlainsightApp());

class PlainsightApp extends StatefulWidget {
  const PlainsightApp({super.key});

  @override
  State<PlainsightApp> createState() => _PlainsightAppState();
}

class _PlainsightAppState extends State<PlainsightApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppStateProvider(
        state: _appState,
        child: MaterialApp(
          title: 'Plainsight',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          // One shared gradient drift controller above every route (same
          // pattern as UniMatch: GradientScaffold reads it via GradientMotion.of).
          builder: (context, child) => GradientMotion(child: child!),
          home: const _AuthGate(),
        ),
      );
}

/// Shows the login screen or the sites list depending on [AppState], and a
/// blank gradient while a persisted session is being restored on launch.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateProvider.of(context),
      builder: (context, _) {
        final app = AppStateProvider.of(context);
        if (app.initializing) {
          return const GradientScaffold(body: SizedBox.expand());
        }
        return app.isLoggedIn ? const SitesScreen() : const LoginScreen();
      },
    );
  }
}
