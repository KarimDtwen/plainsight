---
name: design-tokens
description: How to style Plainsight UI — always through the ported UniMatch v3 token system, never raw colors/sizes. Load before ANY Flutter UI work (screens, widgets, charts, theming).
---

# Plainsight design tokens

The design system lives in `lib/theme/` (ported from UniMatch v3) and `lib/ui/` (shared kit). Rules:

1. **Never hard-code** `Colors.*`, hex values, radii, spacing, durations, or shadows in widgets.
   - Colors: `context.scheme.<role>` (ColorScheme) for semantic roles; `AppColors.*` only inside the theme layer.
   - Spacing/radius/shadow/motion: `context.tokens` (`AppTokens` ThemeExtension) — `t.xs..t.xxl`, `t.radiusSm..t.radiusPill`, `t.shadowCard/CardLg/Nav`, `t.durFast/dur/durSlow`, `t.curveEmphasized`.
2. **Typography:** named roles from `AppType` (`displayL/M`, `headline`, `titleL/M/S`, `bodyL/body`, `label`, `caption`, `button`), always `.copyWith(color: context.scheme…)` — the roles carry no color.
3. **Charts (fl_chart):** series colors come ONLY from `context.tokens.chartSeries` (ordered: blue=visitors, teal=pageviews, then amber/violet/rose/slate). Never invent chart colors; the list is theme-stable and CVD-safe.
4. **Surfaces:** screens use `GradientScaffold`; floating cards/inputs use `GlassSurface` (both in `lib/ui/animated_gradient_background.dart`). One `GradientMotion` exists at the app root — never create another ticker for backgrounds.
5. **States:** loading = `skeletons.dart` (`CardSkeleton`, `ListSkeleton`, `ShimmerBox`); empty/error = `state_views.dart`. Buttons/inputs/chips/headers from `lib/ui/` before writing new ones.
6. **Dark mode is not optional:** every widget must read theme-aware roles so `ThemeMode` flips cleanly. Verify new UI in both themes (resize_window colorScheme or the account toggle once it exists).
7. Widget tests: `AppTokens.fallback()` keeps token reads safe without a theme; pump fixed durations — the aurora background never settles, so **never `pumpAndSettle`** on gradient screens.
