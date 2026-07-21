import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// M-UI — the single top-of-screen header for the clean-fintech redesign.
///
/// Replaces the navy→blue gradient `Container` that was hand-rolled inline in
/// ~6 screens. Two looks, one widget:
///
///  * [AppHeader.slim] — flat, on the scaffold surface: a title (+ optional
///    subtitle), an optional [leading] (e.g. a back button) and trailing
///    [actions]. The new default — the brand gradient no longer fills a whole
///    header block, it survives only as the contained hero variant below.
///  * [AppHeader.gradientHero] — a brand-gradient block that keeps the brand
///    blue as a *contained accent*: white title/subtitle, optional [child]
///    (an embedded search field, quick chips…) and [actions]. By default it is
///    full-bleed with a rounded bottom (a screen header); pass `contained: true`
///    for the Home "hero search card" look (side margins + all-round radius +
///    soft shadow).
class AppHeader extends StatelessWidget {
  const AppHeader._({
    required this.title,
    required this.gradient,
    this.subtitle,
    this.greeting,
    this.leading,
    this.actions,
    this.child,
    this.contained = false,
    this.titleStyle,
  });

  /// Flat header on the scaffold surface (the new default).
  factory AppHeader.slim({
    required String title,
    String? subtitle,
    String? greeting,
    Widget? leading,
    List<Widget>? actions,
    Widget? child,
    TextStyle? titleStyle,
  }) =>
      AppHeader._(
        title: title,
        subtitle: subtitle,
        greeting: greeting,
        leading: leading,
        actions: actions,
        titleStyle: titleStyle,
        gradient: false,
        child: child,
      );

  /// Brand-gradient hero. `contained: true` → the Home hero-search card.
  factory AppHeader.gradientHero({
    required String title,
    String? subtitle,
    String? greeting,
    Widget? leading,
    List<Widget>? actions,
    Widget? child,
    bool contained = false,
    TextStyle? titleStyle,
  }) =>
      AppHeader._(
        title: title,
        subtitle: subtitle,
        greeting: greeting,
        leading: leading,
        actions: actions,
        contained: contained,
        titleStyle: titleStyle,
        gradient: true,
        child: child,
      );

  final String title;

  /// A muted line *above* the title (e.g. "Hello, Sam").
  final String? greeting;

  /// A muted line *below* the title.
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  /// Embedded content under the title row (search field, quick chips…).
  final Widget? child;
  final bool gradient;
  final bool contained;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final cs = context.scheme;
    final t = context.tokens;
    final onColor = gradient ? Colors.white : cs.onSurface;
    final mutedColor =
        gradient ? Colors.white.withValues(alpha: 0.7) : cs.onSurfaceVariant;

    final titleRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, SizedBox(width: t.s)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (greeting != null) ...[
                Text(greeting!,
                    style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2)),
                const SizedBox(height: 2),
              ],
              Text(title,
                  style: titleStyle ??
                      AppType.displayM.copyWith(
                          color: onColor, fontSize: 22, height: 1.1)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: TextStyle(color: mutedColor, fontSize: 13)),
              ],
            ],
          ),
        ),
        if (actions != null) ...[
          SizedBox(width: t.s),
          ...actions!,
        ],
      ],
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        if (child != null) ...[SizedBox(height: t.m + 2), child!],
      ],
    );

    // ── Flat / slim ───────────────────────────────────────────────────────────
    if (!gradient) {
      // A flat header sits on the scaffold, so the status-bar icons must follow
      // the theme (dark icons on a light surface, light on dark) — otherwise the
      // light-mode icons wash out against the pale header.
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: cs.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: SafeArea(
          bottom: false,
          child: Padding(
            // t.l + 2 (18px) instead of t.xl (24px): optically aligns the
            // header text with the 16px card gutter used by every list below.
            padding: EdgeInsets.fromLTRB(t.l + 2, t.l, t.l, t.s),
            child: content,
          ),
        ),
      );
    }

    final decoration = BoxDecoration(
      gradient: const LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      borderRadius: contained
          ? BorderRadius.circular(t.radiusXl + 2)
          : BorderRadius.vertical(bottom: Radius.circular(t.radiusXl + 8)),
      boxShadow: contained
          ? [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 22,
                  offset: const Offset(0, 10)),
            ]
          : null,
    );

    // ── Contained hero card (Home) ──────────────────────────────────────────────
    if (contained) {
      return Padding(
        padding: EdgeInsets.fromLTRB(t.l, t.s, t.l, t.s),
        child: Container(
          decoration: decoration,
          // Top-lit hairline so the navy hero keeps its edge over the
          // near-black dark aurora instead of sinking into it.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusXl + 2),
            border: Border.all(
                color: Colors.white.withValues(
                    alpha: cs.brightness == Brightness.dark ? 0.14 : 0.0),
                width: 1),
          ),
          padding: EdgeInsets.all(t.l + 2),
          child: content,
        ),
      );
    }

    // ── Full-bleed gradient header ──────────────────────────────────────────────
    // The brand gradient is always dark → light status-bar icons in both themes.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: decoration,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(t.xl, t.l, t.xl, t.l),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A circular icon button sized for [AppHeader.slim] `leading`/`actions`
/// (back/close buttons, etc.). Subtle on the scaffold surface; themes via the
/// active [ColorScheme]. Use [onGradient] for the white-on-brand variant.
class AppHeaderIconButton extends StatelessWidget {
  const AppHeaderIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.onGradient = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final cs = context.scheme;
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onGradient
              ? Colors.white.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: onGradient ? Colors.white : cs.onSurface, size: 19),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}
