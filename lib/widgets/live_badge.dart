import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// PS-030 — "N online now", polled every 10s. Takes a plain fetch callback
/// rather than an ApiService/siteId so the same widget serves both the authed
/// dashboard (`ApiService().live(id)`) and the no-auth share page
/// (`ApiService().publicLive(slug)`).
///
/// Polling pauses while the browser tab is hidden — a stranger with a share
/// link left open in a background tab shouldn't keep hitting a Render
/// free-tier instance every 10s forever.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, required this.fetchOnline});

  final Future<int> Function() fetchOnline;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 10);

  Timer? _timer;
  int? _online;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    if (_timer != null) return;
    unawaited(_poll());
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final online = await widget.fetchOnline();
      if (mounted) setState(() => _online = online);
    } catch (_) {
      // A live badge failing silently beats surfacing an error banner for it.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _stopTimer();
      case AppLifecycleState.resumed:
        _startTimer();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.scheme;
    final online = _online;
    final dot = cs.brightness == Brightness.dark
        ? AppColors.successDark
        : AppColors.success;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _pulse.drive(Tween(begin: 0.35, end: 1.0)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          online == null ? 'Live' : '$online online now',
          style: AppType.caption
              .copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
