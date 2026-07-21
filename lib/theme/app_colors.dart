import 'package:flutter/material.dart';

/// Canonical Plainsight palette — single source of truth for brand colors.
/// Ported from the UniMatch design system (v3); shares the same monochrome-blue
/// brand family and light/dark surface pairs.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0847AD); // matches the seed + splash
  static const Color primaryDeep = Color(0xFF001845); // navy header start
  static const Color primaryBright = Color(0xFF4F8EF7); // light-blue accent
  static const Color aiAccent = Color(0xFF5E8BFF); // AI accent (monochrome blue)

  // ── Liquid-glass v2 accents (monochrome blue) ────────────────────────────────
  static const Color electric = Color(0xFF2F7BFF); // primary CTA fill
  static const Color electricDeep = Color(0xFF0A4FE0); // CTA gradient end
  static const Color cyanMatch = Color(0xFF22A0FF); // match% / success signal
  static const Color amberUrgent = Color(0xFFF5A728); // deadlines / urgency only

  /// Was a divergent primary used only in search_screen — alias it away.
  @Deprecated('Use AppColors.primary')
  static const Color primaryLegacy = primary;

  // ── Surfaces (light) ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF0F4FF);
  static const Color surface = Colors.white;
  static const Color onSurfaceStrong = Color(0xFF1A1A2E); // ink for titles

  // ── Surfaces (dark) ──────────────────────────────────────────────────────────
  // backgroundDark matches the aurora base mid-stop so navigating between a
  // GradientScaffold screen and a plain Scaffold never shows a brightness jump.
  static const Color backgroundDark = Color(0xFF060A15);
  static const Color surfaceDark = Color(0xFF151D2E);
  static const Color onSurfaceStrongDark = Color(0xFFEAEEF7);

  // ── Semantics ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1B9E5A);
  static const Color warning = Color(0xFF8A6D00);
  static const Color danger = Color(0xFFD32F2F);
  // Dark-theme counterparts: the light values sit at ~2:1 contrast on dark
  // surfaces (the olive warning is near-illegible), so dark resolves brighter.
  static const Color successDark = Color(0xFF3DCB84);
  static const Color warningDark = Color(0xFFFFC24D);
  static const Color dangerDark = Color(0xFFFF6B6B);
  static const Color gold = Color(0xFFFFB300); // verification / scholarship
  static const Color silver = Color(0xFF9E9E9E);
  static const Color bronze = Color(0xFFCD7F32);

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const List<Color> brandGradient = [primaryDeep, primary]; // headers
  static const List<Color> aiGradient = [primaryBright, electric]; // AI surfaces (monochrome blue)

  // ── Chart series (fl_chart) ──────────────────────────────────────────────────
  // Ordered palette for data series: distinguishable in both themes and under
  // common color-vision deficiencies (blue/teal/amber/violet/rose/slate).
  static const List<Color> chartSeries = [
    Color(0xFF3B82F6), // blue — primary series (visitors)
    Color(0xFF14B8A6), // teal — secondary series (pageviews)
    Color(0xFFF59E0B), // amber
    Color(0xFF8B5CF6), // violet
    Color(0xFFF43F5E), // rose
    Color(0xFF64748B), // slate
  ];

  // ── Aurora mesh background (liquid-glass v2) ─────────────────────────────────
  // Near-black (dark) / soft sky (light) base; vivid blue blooms drift on top so
  // the glass has real colour to refract. Drives AppTokens.bgGradient/blobColors.
  static const List<Color> bgGradientLight = [
    Color(0xFFEAF1FF), // top sky
    Color(0xFFF2F6FF), // mid
    Color(0xFFDCE8FF), // bottom
  ];
  // Four stops so the full-screen dark ramp shades smoothly (a 3-stop ramp over
  // near-black values mach-bands on OLED).
  static const List<Color> bgGradientDark = [
    Color(0xFF05080F), // near-black
    Color(0xFF060A15), // deep navy-black
    Color(0xFF080D20), // navy-black
    Color(0xFF0A1430), // navy
  ];
  // Drifting aurora blooms (painted as soft radial tints over the base).
  static const List<Color> blobTrioLight = [
    Color(0xFF6FA4FF),
    Color(0xFF3AA0FF),
    Color(0xFF8FB6FF),
  ];
  // Ambient blooms stay non-semantic blues: cyan (#22A0FF) is reserved for
  // match/success signals, so it never washes the background.
  static const List<Color> blobTrioDark = [electric, Color(0xFF4A7DFF), electricDeep];
}

/// U-109 — concise access to the active [ColorScheme] for the M15 tokenization
/// pass: `context.scheme.surface`, `context.scheme.onSurfaceVariant`, etc.
extension AppColorSchemeContext on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
}
