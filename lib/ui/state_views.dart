import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared empty / error / loading views (ported from the UniMatch v3 kit):
/// the standard `Column(Icon + title + subtitle + action)` states.

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _Centered(
        icon: icon,
        // scheme.primary (not the deep navy literal) stays visible in dark.
        tint: context.scheme.primary,
        title: title,
        subtitle: subtitle,
        action: action,
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.icon = Icons.cloud_off,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _Centered(
        icon: icon,
        tint: context.scheme.error,
        title: title,
        subtitle: subtitle,
        action: onRetry == null
            ? null
            : FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
      );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: AppType.caption
                      .copyWith(color: context.scheme.onSurfaceVariant)),
            ],
          ],
        ),
      );
}

class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.tint,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final dark = context.scheme.brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon sits in a soft tinted disc — a bare 50%-alpha glyph was the
            // flattest surface in the app.
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: dark ? 0.15 : 0.08),
                border: Border.all(color: tint.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, size: 38, color: tint),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: AppType.titleL.copyWith(color: context.scheme.onSurface)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: AppType.body
                      .copyWith(color: context.scheme.onSurfaceVariant)),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
