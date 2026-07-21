import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Whether foreground "glass" surfaces use a real [BackdropFilter] blur.
///
/// **Web only.** On mobile, real-time `BackdropFilter` blur — especially many of
/// them in scrolling lists — is the biggest Flutter jank source, so glass there
/// uses a more opaque translucent fill (no blur) and stays smooth.
const bool kGlassBlur = kIsWeb;

/// How many discrete steps the aurora drift is quantised to per loop.
///
/// The drift is an ~18 s loop, so the full-screen gradient + radial blooms do
/// not need to re-raster on every vsync frame. Quantising the drift progress to
/// this many steps makes [_GradientBackgroundPainter.shouldRepaint] fire only
/// ~14×/s (256 / 18 s) instead of 60–120×/s — visually identical for so slow a
/// motion, but it cuts the background's GPU fill-rate cost several-fold on
/// high-refresh and weak mobile GPUs. (Goldens render the static `progress = 0`
/// frame, so this is invisible to them.)
const int kGradientDriftSteps = 256;

/// Owns the single, app-wide drift [AnimationController] for the animated
/// gradient background. Mounted once near the app root (see `main.dart`); every
/// [AnimatedGradientBackground] only *reads* the shared animation via
/// [GradientMotion.of] — they never create their own ticker.
///
/// Honors reduced-motion ([MediaQueryData.disableAnimations]): when set, the
/// controller is frozen so the background renders as a static gradient.
class GradientMotion extends StatefulWidget {
  const GradientMotion({super.key, required this.child});

  final Widget child;

  /// The shared 0→1 looping drift. Returns a stopped animation when no
  /// [GradientMotion] ancestor exists (tests, goldens) so backgrounds still
  /// paint a deterministic static frame.
  static Animation<double> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_GradientMotionScope>();
    return scope?.drift ?? const AlwaysStoppedAnimation<double>(0);
  }

  @override
  State<GradientMotion> createState() => _GradientMotionState();
}

class _GradientMotionState extends State<GradientMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 18));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick up the theme-driven drift duration.
    final dur = Theme.of(context).extension<AppTokens>()?.gradientDriftDur;
    if (dur != null && dur != _controller.duration) _controller.duration = dur;

    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce != _reducedMotion || !(reduce || _controller.isAnimating)) {
      _reducedMotion = reduce;
      _applyMotion();
    }
  }

  void _applyMotion() {
    if (_reducedMotion) {
      _controller.stop();
      _controller.value = 0.0; // static gradient + static blob placement
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GradientMotionScope(drift: _controller, child: widget.child);
  }
}

class _GradientMotionScope extends InheritedWidget {
  const _GradientMotionScope({required this.drift, required super.child});

  final Animation<double> drift;

  @override
  bool updateShouldNotify(_GradientMotionScope oldWidget) =>
      drift != oldWidget.drift;
}

/// A full-bleed, theme-aware animated gradient: a slowly-sliding base gradient
/// plus a few drifting, blurred colour blobs, painted in a single
/// [RepaintBoundary] so foreground content never invalidates the background.
///
/// Reads stops from `context.tokens` (so it cross-fades on a light↔dark flip)
/// and the shared drift from [GradientMotion.of].
class AnimatedGradientBackground extends StatelessWidget {
  const AnimatedGradientBackground({
    super.key,
    this.intensity = 1.0,
    this.child,
    this.baseColors,
    this.blobColors,
  });

  /// Blob opacity multiplier. `0.0` paints only the base gradient.
  final double intensity;

  /// Content rendered above the background.
  final Widget? child;

  /// Optional fixed palettes for branded screens (e.g. the dark auth flow).
  /// When null the theme-aware `context.tokens` stops are used.
  final List<Color>? baseColors;
  final List<Color>? blobColors;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final drift = GradientMotion.of(context);
    final base = baseColors ?? tokens.bgGradient;
    final blobs = blobColors ?? tokens.blobColors;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: drift,
            builder: (context, _) {
              // Quantise the drift so the expensive painter only re-rasters
              // ~kGradientDriftSteps times per loop (see the const above), not
              // on every vsync frame.
              final progress =
                  (drift.value * kGradientDriftSteps).floorToDouble() /
                      kGradientDriftSteps;
              return CustomPaint(
                painter: _GradientBackgroundPainter(
                  progress: progress,
                  baseColors: base,
                  blobColors: blobs,
                  intensity: intensity,
                ),
                isComplex: true,
                willChange: true,
              );
            },
          ),
        ),
        ?child,
      ],
    );
  }
}

class _GradientBackgroundPainter extends CustomPainter {
  _GradientBackgroundPainter({
    required this.progress,
    required this.baseColors,
    required this.blobColors,
    required this.intensity,
  });

  final double progress;
  final List<Color> baseColors;
  final List<Color> blobColors;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    // Base gradient — the begin/end alignments orbit slowly so the hue slides.
    final a = progress * 2 * math.pi;
    final shiftX = 0.18 * math.cos(a);
    final shiftY = 0.18 * math.sin(a);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + shiftX, -1 + shiftY),
          end: Alignment(1 - shiftX, 1 - shiftY),
          colors: baseColors,
        ).createShader(rect),
    );

    if (intensity <= 0 || blobColors.isEmpty) return;

    // Aurora blooms — corner-anchored like the approved mockup, gentle drift,
    // sized so the glass reads as even glass instead of a solid blue fill.
    // Soft radial blooms (no per-frame blur pass) so the continuously-drifting
    // background stays cheap on mobile GPUs. The falloff is a multi-stop
    // gaussian approximation: a linear 2-stop alpha ramp over a near-black base
    // mach-bands into visible rings on OLED; these eased stops cost the same on
    // the GPU and read as diffuse light.
    const anchors = [Offset(0.20, 0.10), Offset(0.86, 0.80), Offset(0.55, 0.52)];
    const radii = [0.58, 0.60, 0.46];
    const alphas = [0.55, 0.45, 0.36];
    const falloffStops = [0.0, 0.35, 0.60, 0.82, 1.0];
    for (var i = 0; i < blobColors.length; i++) {
      final anchor = anchors[i % anchors.length];
      final ph = a + i * 2.1;
      final cx = size.width * anchor.dx + 24 * math.cos(ph);
      final cy = size.height * anchor.dy + 24 * math.sin(ph * 1.2);
      final center = Offset(cx, cy);
      final r = size.width * radii[i % radii.length];
      final c = blobColors[i];
      final a0 = alphas[i % alphas.length] * intensity;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              c.withValues(alpha: a0),
              c.withValues(alpha: a0 * 0.62),
              c.withValues(alpha: a0 * 0.30),
              c.withValues(alpha: a0 * 0.10),
              c.withValues(alpha: 0.0),
            ],
            stops: falloffStops,
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_GradientBackgroundPainter old) =>
      old.progress != progress ||
      old.intensity != intensity ||
      !identical(old.baseColors, baseColors) ||
      !identical(old.blobColors, blobColors);
}

/// Drop-in [Scaffold] replacement whose body sits over the animated gradient.
/// The inner Scaffold is transparent so the gradient shows through; an opaque
/// [appBar] (when provided) renders above it unchanged.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.intensity = 1.0,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final double intensity;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    // Gradient sits behind the ENTIRE transparent scaffold, so it also shows
    // through a translucent app bar or floating bottom nav.
    return AnimatedGradientBackground(
      intensity: intensity,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        body: body,
      ),
    );
  }
}

/// A frosted-glass surface: translucent fill + top-lit hairline rim, with a
/// real blur on web and a translucent-navy fallback on mobile (see
/// [kGlassBlur]). Used for chips, input bars, chat bubbles and cards that
/// float over the gradient.
///
/// Design-v3 recipe:
///  * fill — web keeps the sheer white film over real blur; mobile dark uses a
///    translucent NAVY (white at 42% composited to mid-grey slabs — the old
///    look washed the dark showcase out).
///  * top highlight — fades out horizontally like a real specular streak
///    instead of terminating in square ends.
///  * rim — top-lit gradient hairline (bright top → dim bottom), painted once.
///  * shadow — two layers (soft key + tight contact); overridable per call
///    site so dense lists can pass a calmer `tokens.shadowCard`.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.alpha,
    this.blurSigma = 20,
    this.border = true,
    this.color,
    this.boxShadow,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Fill alpha; defaults to a value tuned for whether blur is available.
  final double? alpha;
  final double blurSigma;
  final bool border;

  /// Override the base fill colour (defaults to white on web / navy on mobile
  /// dark).
  final Color? color;

  /// Override the drop shadow (e.g. `context.tokens.shadowCard` for cards in
  /// dense lists, where stacked heavy shadows turn to mud).
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final dark = scheme.brightness == Brightness.dark;
    final radius =
        borderRadius ?? BorderRadius.circular(context.tokens.radiusLg);
    // With blur (web) the tint is minimal; without blur (mobile) use a more
    // opaque fill so cards stay legible — and skip the costly BackdropFilter.
    // Mobile dark fills with translucent navy, NOT white: white at 42% over the
    // near-black aurora composites to a milky mid-grey and kills the showcase.
    final fillAlpha =
        kGlassBlur ? (alpha ?? (dark ? 0.05 : 0.55)) : (dark ? 0.72 : 0.80);
    final fallbackFill = dark ? const Color(0xFF18233C) : Colors.white;
    final tint = (color ?? (kGlassBlur ? Colors.white : fallbackFill))
        .withValues(alpha: fillAlpha);

    final Widget body = Stack(
      children: [
        Positioned.fill(
          child: kGlassBlur
              ? BackdropFilter(
                  filter:
                      ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: ColoredBox(color: tint),
                )
              : ColoredBox(color: tint),
        ),
        // Specular top highlight — fades out at both ends like lit glass.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: dark ? 0.28 : 0.55),
                    Colors.white.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),
        ),
        if (padding != null) Padding(padding: padding!, child: child) else child,
      ],
    );

    final Widget clipped = ClipRRect(borderRadius: radius, child: body);
    if (!border) return clipped;

    final shadows = boxShadow ??
        (dark
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 24,
                    offset: const Offset(0, 12)),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ]
            : [
                BoxShadow(
                    color: const Color(0xFF2F5DBF).withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12)),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ]);

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: Stack(
        children: [
          clipped,
          // Top-lit hairline rim — painted once (static; no per-frame cost).
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _GlassRimPainter(radius, dark)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1px top-lit rim stroke: bright along the top edge, falling off toward the
/// bottom — the difference between "outlined rectangle" and "lit glass".
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter(this.radius, this.dark);

  final BorderRadius radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect).deflate(0.5);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? [
                Colors.white.withValues(alpha: 0.26),
                Colors.white.withValues(alpha: 0.06),
              ]
            : [
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.04),
              ],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) =>
      old.radius != radius || old.dark != dark;
}
