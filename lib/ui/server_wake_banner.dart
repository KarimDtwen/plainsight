import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A slim, honest notice shown while the Render backend is cold-starting.
/// The dashboard keeps working underneath; this only discloses that fresh
/// data may take 30-60 seconds (Render free tier sleeps after ~15 min idle).
class ServerWakeBanner extends StatelessWidget {
  const ServerWakeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final warn = context.scheme.brightness == Brightness.dark
        ? AppColors.warningDark
        : AppColors.warning;
    return ValueListenableBuilder<bool>(
      valueListenable: ApiService.serverWaking,
      builder: (context, waking, _) => AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: !waking
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                color: warn.withValues(alpha: 0.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(warn),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Waking up the server… this can take 30-60s on a '
                        'free-tier cold start.',
                        style: AppType.caption
                            .copyWith(color: warn, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
