import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'screens/login_screen.dart';
import 'screens/share_screen.dart';
import 'screens/sites_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/animated_gradient_background.dart';

void main() {
  // Clean `/share/<slug>` URLs (Firebase Hosting already rewrites every path
  // to index.html — see firebase.json) instead of the default `#/...` hash.
  usePathUrlStrategy();
  runApp(const PlainsightApp());
}

/// A share link is public — it must render without the auth gate, since a
/// stranger who never logs in opens it directly by URL.
String? _shareSlugFromUrl() {
  final segments =
      Uri.base.path.split('/').where((s) => s.isNotEmpty).toList();
  return segments.length == 2 && segments[0] == 'share' ? segments[1] : null;
}

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
  Widget build(BuildContext context) {
    final shareSlug = _shareSlugFromUrl();
    return AppStateProvider(
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
        home: shareSlug != null
            ? ShareScreen(slug: shareSlug)
            : const _AuthGate(),
      ),
    );
  }
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
