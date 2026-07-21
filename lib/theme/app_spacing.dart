import 'package:flutter/material.dart';

import 'app_colors.dart';

/// U-082 — spacing / radius / shadow / motion tokens, exposed app-wide through a
/// [ThemeExtension] so any widget can read `context.tokens`. Values match the
/// most common existing usages so adopting them causes no visual change.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  // Spacing scale.
  final double xs, s, m, l, xl, xxl;
  // Radius scale (replaces the mixed 8/10/12/14/16/18/20/22).
  final double radiusSm, radiusMd, radiusLg, radiusXl, radiusPill;
  // Elevation / shadows.
  final List<BoxShadow> shadowCard, shadowCardLg, shadowNav;
  // Motion.
  final Duration durFast, dur, durSlow;
  final Curve curveEmphasized;
  // Animated gradient background (gradient redesign): theme-aware base stops +
  // drifting blob tints, driven by one shared controller at the app root.
  final List<Color> bgGradient;
  final List<Color> blobColors;
  final Duration gradientDriftDur;
  // Chart series palette (fl_chart) — ordered, theme-stable, colorblind-safe.
  final List<Color> chartSeries;

  const AppTokens({
    this.xs = 4,
    this.s = 8,
    this.m = 12,
    this.l = 16,
    this.xl = 24,
    this.xxl = 32,
    this.radiusSm = 8,
    this.radiusMd = 12,
    this.radiusLg = 16,
    this.radiusXl = 20,
    this.radiusPill = 999,
    required this.shadowCard,
    required this.shadowCardLg,
    required this.shadowNav,
    this.durFast = const Duration(milliseconds: 150),
    this.dur = const Duration(milliseconds: 250),
    this.durSlow = const Duration(milliseconds: 350),
    this.curveEmphasized = Curves.easeOutCubic,
    this.bgGradient = AppColors.bgGradientLight,
    this.blobColors = AppColors.blobTrioLight,
    this.gradientDriftDur = const Duration(seconds: 18),
    this.chartSeries = AppColors.chartSeries,
  });

  /// Default token set (also used as a safe fallback in tests where the theme
  /// extension may be absent).
  factory AppTokens.fallback() => AppTokens(
        shadowCard: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
        shadowCardLg: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
        shadowNav: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4)),
        ],
      );

  @override
  AppTokens copyWith({
    List<BoxShadow>? shadowCard,
    List<BoxShadow>? shadowCardLg,
    List<BoxShadow>? shadowNav,
    List<Color>? bgGradient,
    List<Color>? blobColors,
    Duration? gradientDriftDur,
    List<Color>? chartSeries,
  }) =>
      AppTokens(
        shadowCard: shadowCard ?? this.shadowCard,
        shadowCardLg: shadowCardLg ?? this.shadowCardLg,
        shadowNav: shadowNav ?? this.shadowNav,
        bgGradient: bgGradient ?? this.bgGradient,
        blobColors: blobColors ?? this.blobColors,
        gradientDriftDur: gradientDriftDur ?? this.gradientDriftDur,
        chartSeries: chartSeries ?? this.chartSeries,
      );

  // Spacing/radius/shadow/motion are identical across themes; only the gradient
  // stops differ, so a light<->dark ThemeMode flip cross-fades the background.
  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return copyWith(
      bgGradient: _lerpColors(bgGradient, other.bgGradient, t),
      blobColors: _lerpColors(blobColors, other.blobColors, t),
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) {
    final n = a.length < b.length ? a.length : b.length;
    return List<Color>.generate(n, (i) => Color.lerp(a[i], b[i], t) ?? a[i]);
  }
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.fallback();
}
