import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// U-086 — shared chip. Replaces `_MiniChip` (explore_tab), the inline search
/// result pills, and filter chips. `tone` picks the colour role; `selected`
/// gives the filled state used by the filter screen.
///
/// `gold` is the scholarship/verification tone (spec: gold = scholarship);
/// `warning` is reserved for genuine urgency (deadlines).
enum ChipTone { neutral, primary, success, warning, gold }

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = ChipTone.primary,
    this.selected = false,
    this.onTap,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final ChipTone tone;
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;

  /// Theme-aware chip colours. Fills are translucent accent tints (so the
  /// glass they sit on reads through) with a faint matching hairline; the
  /// foreground brightens on dark surfaces for legibility.
  (Color bg, Color fg) _colorsFor(ColorScheme scheme) {
    if (selected) return (scheme.primary, Colors.white);
    final dark = scheme.brightness == Brightness.dark;
    return switch (tone) {
      ChipTone.neutral => (
          scheme.onSurfaceVariant.withValues(alpha: dark ? 0.14 : 0.10),
          scheme.onSurfaceVariant,
        ),
      ChipTone.primary => (
          scheme.primary.withValues(alpha: dark ? 0.18 : 0.10),
          scheme.primary,
        ),
      ChipTone.success => _accent(
          dark ? AppColors.successDark : AppColors.success, scheme, dark),
      ChipTone.warning => _accent(
          dark ? AppColors.warningDark : AppColors.warning, scheme, dark),
      ChipTone.gold => _accent(AppColors.gold, scheme, dark),
    };
  }

  /// Semantic accent (no scheme role) → translucent tint + a foreground kept
  /// legible on dark surfaces.
  static (Color bg, Color fg) _accent(
      Color accent, ColorScheme scheme, bool dark) {
    final fg = dark ? Color.lerp(accent, Colors.white, 0.25)! : accent;
    final bg = accent.withValues(alpha: dark ? 0.18 : 0.10);
    return (bg, fg);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsFor(context.scheme);
    final body = Padding(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 4 : 5),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: dense ? 12 : 13, color: fg),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                fontSize: dense ? 11 : 12,
                color: fg,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1)),
      ]),
    );
    // Material carries the fill so InkWell ripples paint ON the chip (an
    // opaque Container over the ink made tap feedback invisible).
    return Material(
      color: bg,
      shape: StadiumBorder(
          side: BorderSide(
              color: selected
                  ? Colors.transparent
                  : fg.withValues(alpha: 0.22))),
      child: onTap == null
          ? body
          : InkWell(
              customBorder: const StadiumBorder(), onTap: onTap, child: body),
    );
  }
}
