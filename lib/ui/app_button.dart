import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// U-085 — shared buttons. Replace the repeated inline
/// `ElevatedButton.styleFrom(backgroundColor: 0xFF0847AD, radius 14)` and
/// `OutlinedButton` blocks across explore_tab / account_tab / profile_setup /
/// search with these token-driven widgets.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation(Colors.white)),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
              Text(label, style: AppType.button),
            ],
          );
    // Loading keeps the full electric look (fill + glow): a working button
    // that suddenly goes translucent-muddy over the aurora reads as broken.
    final glowing = onPressed != null || loading;
    final button = SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radiusLg),
          boxShadow: glowing
              ? [
                  BoxShadow(
                      color: AppColors.electric.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.electric,
            foregroundColor: Colors.white,
            disabledBackgroundColor: loading
                ? AppColors.electric
                : AppColors.electric.withValues(alpha: 0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusLg)),
          ),
          child: child,
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final button = SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electric,
          side: const BorderSide(color: AppColors.electric, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radiusLg)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
            Text(label, style: AppType.button),
          ],
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
