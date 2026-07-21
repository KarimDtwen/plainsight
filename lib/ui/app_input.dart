import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shared search/input field (ported from the UniMatch v3 kit).
/// `onDark` styles it for the gradient headers; otherwise it's a white field.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search…',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onDark = false,
    this.autofocus = false,
    this.prefixIcon = Icons.search,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool onDark;
  final bool autofocus;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final cs = context.scheme;
    final dark = cs.brightness == Brightness.dark;
    final fg = onDark ? Colors.white : cs.onSurface;
    final hintFg = onDark
        ? Colors.white.withValues(alpha: 0.55)
        : cs.onSurfaceVariant;
    // Translucent in dark so the aurora reads through (an opaque slab broke
    // the glass language); solid white stays correct in light.
    final fill = onDark
        ? Colors.white.withValues(alpha: 0.15)
        : (dark ? Colors.white.withValues(alpha: 0.07) : cs.surface);

    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: fg, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintFg, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: hintFg, size: 20),
        suffixIcon: (onClear != null && controller.text.isNotEmpty)
            ? IconButton(
                icon: Icon(Icons.close, color: hintFg, size: 18),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: fill,
        // A real focus state — electric ring — so the active field is
        // distinguishable at arm's length.
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusLg),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusLg),
            borderSide:
                const BorderSide(color: AppColors.electric, width: 1.6)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radiusLg),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}
