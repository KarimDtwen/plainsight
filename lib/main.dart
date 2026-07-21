import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';
import 'ui/animated_gradient_background.dart';

void main() => runApp(const PlainsightApp());

class PlainsightApp extends StatelessWidget {
  const PlainsightApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Plainsight',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        // One shared gradient drift controller above every route (same pattern
        // as UniMatch: GradientScaffold screens read it via GradientMotion.of).
        builder: (context, child) => GradientMotion(child: child!),
        home: const _PlaceholderHome(),
      );
}

/// M0 placeholder — proves the ported design system renders end-to-end.
/// Replaced by the login + dashboard flow in M2 (PS-020..025).
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GradientScaffold(
      body: Center(
        child: GlassSurface(
          borderRadius: BorderRadius.circular(t.radiusXl),
          boxShadow: t.shadowCardLg,
          padding: EdgeInsets.symmetric(horizontal: t.xxl, vertical: t.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Plainsight',
                  style: AppType.displayM
                      .copyWith(color: context.scheme.onSurface)),
              SizedBox(height: t.s),
              Text('Privacy-first web analytics — no cookies, one tiny script.',
                  textAlign: TextAlign.center,
                  style: AppType.body
                      .copyWith(color: context.scheme.onSurfaceVariant)),
              SizedBox(height: t.l),
              Text('M0 scaffold · dashboard lands in M2',
                  style: AppType.caption
                      .copyWith(color: context.scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
