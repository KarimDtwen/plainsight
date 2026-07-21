import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// U-083 / U-109 — central theme builder.
///
/// Design-v3 pass: the scheme's neutrals are blue-greys (not raw Material
/// greys), secondary/tertiary are pinned to on-brand blues instead of the raw
/// `fromSeed` slate/mauve, [AppType] is mapped into [TextTheme], and component
/// themes route every stock Material widget (cards, dialogs, buttons, inputs,
/// sheets, snackbars) through the design system — electric #2F7BFF is the one
/// CTA blue app-wide.
///
///   surface              = white / #151D2E   (card backgrounds)
///   onSurface            = #1A1A2E / #EAEEF7 (primary ink)
///   onSurfaceVariant     = #62708E / #9BA3B4 (secondary text — blue-grey)
///   outline              = #AFB9D0 / #5A6473 (hints)
///   outlineVariant       = #DCE3F2 / #2C3650 (faint dividers)
///   surfaceContainerLow  = #F0F4FF / aurora   (scaffold background)
///   surfaceContainerHighest = #EDF1FA / #222C40 (chip fills)
///   primary              = #0847AD / #4F8EF7 (brand)
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness brightness) {
    final seed =
        ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: brightness);
    if (brightness == Brightness.dark) {
      return seed.copyWith(
        primary: AppColors.primaryBright,
        onPrimary: Colors.white,
        secondary: AppColors.primaryBright,
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFF1B3564),
        onSecondaryContainer: const Color(0xFFD6E4FF),
        tertiary: AppColors.cyanMatch,
        onTertiary: const Color(0xFF04223F),
        error: AppColors.dangerDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceStrongDark,
        onSurfaceVariant: const Color(0xFF9BA3B4),
        outline: const Color(0xFF5A6473),
        surfaceContainerLow: AppColors.backgroundDark,
        surfaceContainerHighest: const Color(0xFF222C40),
        outlineVariant: const Color(0xFF2C3650),
      );
    }
    return seed.copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryBright,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDCE8FF),
      onSecondaryContainer: const Color(0xFF0A2C66),
      tertiary: AppColors.cyanMatch,
      onTertiary: const Color(0xFF04223F),
      surface: AppColors.surface,
      onSurface: AppColors.onSurfaceStrong,
      // Blue-grey neutrals: same contrast tiers as the old Material greys, but
      // they share the brand hue so light mode feels designed, not default.
      onSurfaceVariant: const Color(0xFF62708E),
      outline: const Color(0xFFAFB9D0),
      surfaceContainerLow: AppColors.background,
      surfaceContainerHighest: const Color(0xFFEDF1FA),
      outlineVariant: const Color(0xFFDCE3F2),
    );
  }

  /// Brightness-specific tokens: identical spacing/shadows/motion, but a
  /// theme-aware gradient + blob palette for the animated background.
  static AppTokens _tokensFor(Brightness brightness) {
    final base = AppTokens.fallback();
    return brightness == Brightness.dark
        ? base.copyWith(
            bgGradient: AppColors.bgGradientDark,
            blobColors: AppColors.blobTrioDark,
          )
        : base.copyWith(
            bgGradient: AppColors.bgGradientLight,
            blobColors: AppColors.blobTrioLight,
          );
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = _scheme(brightness);
    final dark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'SpaceGrotesk', // global geometric type (liquid-glass v2)
    );

    // AppType → TextTheme so every widget that reads Theme.of(context).textTheme
    // (app bars, dialogs, list tiles, buttons, snackbars) speaks the design
    // system instead of stock M3 sizes.
    final textTheme = base.textTheme
        .copyWith(
          displaySmall: AppType.displayL,
          headlineSmall: AppType.displayM,
          titleLarge: AppType.titleL,
          titleMedium: AppType.titleM,
          titleSmall: AppType.titleS,
          bodyLarge: AppType.bodyL,
          bodyMedium: AppType.body,
          labelLarge: AppType.label,
          labelSmall: AppType.caption,
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    // One CTA recipe: electric fill, white ink, brand-voice label, pill-ish
    // radius. Loading/disabled keeps the electric hue (blended, not translucent)
    // so buttons never go muddy over the aurora.
    final ctaStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? Color.alphaBlend(
                  AppColors.electric.withValues(alpha: 0.45),
                  dark ? const Color(0xFF10182B) : Colors.white)
              : AppColors.electric),
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? Colors.white.withValues(alpha: 0.75)
              : Colors.white),
      textStyle: const WidgetStatePropertyAll(AppType.button),
      minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      elevation: const WidgetStatePropertyAll(0),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[_tokensFor(brightness)],
      textTheme: textTheme,
      // Dark plain scaffolds match the aurora base exactly, so pushing from a
      // GradientScaffold to a plain screen never flashes a brightness jump.
      scaffoldBackgroundColor:
          dark ? AppColors.backgroundDark : scheme.surfaceContainerLow,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: AppType.titleL.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        surfaceTintColor: Colors.transparent,
        backgroundColor: dark ? const Color(0xFF141D33) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppType.titleL.copyWith(color: scheme.onSurface),
        contentTextStyle: AppType.body.copyWith(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(style: ctaStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ctaStyle),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppType.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.55)),
          textStyle: AppType.button,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? Colors.white.withValues(alpha: 0.06)
            : scheme.surfaceContainerHighest,
        hintStyle: AppType.body.copyWith(color: scheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.electric, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(
          color: scheme.outlineVariant, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF1B2740) : const Color(0xFF1A1A2E),
        contentTextStyle: AppType.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? const Color(0xFF10182B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        labelStyle: AppType.titleS,
        unselectedLabelStyle: AppType.titleS.copyWith(fontWeight: FontWeight.w500),
      ),
      // Cupertino slide on every platform — desktop web otherwise falls back to
      // the stock zoom transition and breaks the app's motion language.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
