import 'package:flutter/material.dart';

/// U-095 — one source of truth for push transitions. Replaces the duplicated
/// `_fadeRoute` / `_slideRoute` in explore_tab and the inline fade route in
/// account_tab's `_SavedCard`. Screens migrate to these in M14.

Route<T> fadeRoute<T>(Widget page,
        {Duration duration = const Duration(milliseconds: 250)}) =>
    PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// Slide up from the bottom (used for filter / modal-style screens).
Route<T> slideUpRoute<T>(Widget page,
        {Duration duration = const Duration(milliseconds: 350)}) =>
    PageRouteBuilder<T>(
      transitionDuration: duration,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: animation.drive(
            Tween(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))),
        child: child,
      ),
    );

/// Slide in from the right + fade (used for detail screens).
Route<T> slideRightRoute<T>(Widget page,
        {Duration duration = const Duration(milliseconds: 380)}) =>
    PageRouteBuilder<T>(
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: animation.drive(
            Tween(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
